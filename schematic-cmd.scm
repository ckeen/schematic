(use posix files srfi-1 easy-args)

(include "schematic.scm")

(define-arguments
  ((*help* h))
  ((*title* t) "")
  ((*output* o) 'html)
  ((*language* l) 'scheme)
  ((*formatter* f) "")
  ((*highlighter* s) "")
  ((*comment-string* c) ";; ")
  ((*directory*) "html")
  ((*stylesheet*)
   (find (lambda (s) (string-suffix? ".css" s))
         (cdr (assq 'files (extension-information 'schematic))))))

(define usage
  (format "usage: ~a [options] [file ...]

  options:
    -h, --help            show this message
    -o, --output          output format (html, ansi)
    -f, --formatter       external comment string formatting command
    -s, --highlighter     external syntax highlighting command
    -c, --comment-string  comment string format
    -l, --language        language name (html, built-in colorizer only)
        --stylesheet      alternative stylesheet (html only)
        --directory       output directory (html only)

" (program-name)))

(define (die . msg)
  (parameterize ((current-output-port (current-error-port)))
    (for-each display msg)
    (newline)
    (display usage)
    (exit 1)))

(unless (null? (unmatched-arguments))
  (die "Invalid argument: " (caar (unmatched-arguments))))

(when (*help*)
  (display usage)
  (exit))

;; Pipe to a command, if given.
(define (maybe-external cmd)
  (if (string-null? cmd)
    (lambda (s) s)
    (lambda (s)
      (receive (i o p) (process cmd)
        (display s o)
        (close-output-port o)
        (let ((output (read-all i)))
          (close-input-port i)
          output)))))

;; Load the colorize egg if it's installed and no
;; other highlighter was given at the command line.
(define (use-colorize-egg)
  (and (string-null? (*highlighter*))
       (extension-information 'colorize)
       (use colorize)
       (lambda (s) (html-colorize (*language*) s))))

(define process-file
  (let ((format (maybe-external (*formatter*)))
        (hilite (maybe-external (*highlighter*))))
    (case (*output*)
      ;; ANSI goes to stdout.
      ((ANSI ansi)
       (use fmt)
       (let ((width 0.65)
             (sep " | "))
         (lambda (reader file)
           (fmt #t (columnar width (cat nl file nl) sep))
           (let lp ()
             (call-with-values reader
               (lambda (docs code)
                 (unless (eof-object? docs)
                   (fmt #t (columnar width
                             (cat nl (wrap-lines (format docs))) sep
                             (cat nl (hilite code))))
                   (lp)))))
           (fmt #t (columnar width nl sep)))))
      ;; HTML is written to files.
      ;; I don't really like this difference in behavior,
      ;; but we have to put the stylesheet somewhere...
      ;; Maybe inline?
      ((HTML html)
       (use sxml-transforms)
       (let ((dir (*directory*))
             (hilite (or (use-colorize-egg) hilite)))
         (create-directory dir 'w/parents)
         (file-copy
           (*stylesheet*)
           (make-pathname dir "schematic.css")
           'clobber)
         (lambda (reader title)
           ;; `file` may be a title given at the command line.
           (let lp ((i 1)
                    (rows '()))
             (call-with-values reader
               (lambda (docs code)
                 (if (eof-object? docs)
                   ;; Write full html to file.
                   (with-output-to-file
                     (make-pathname dir title ".html")
                     (lambda ()
                       (SRV:send-reply
                         (pre-post-order
                           `("<!doctype html>"
                             (html
                              (head
                                (title ,title)
                                (link
                                  (@ (rel "stylesheet")
                                     (href "schematic.css"))))
                              (body
                                (div (@ (id "background")))
                                (div (@ (id "container"))
                                     (table
                                       (@ (cellspacing 0)
                                          (cellpadding 0))
                                       (tr (th (@ (class "docs"))
                                               (h1 ,title))
                                           (th (@ (class "code"))))
                                       ,@(reverse rows))))))
                           universal-protected-rules))))
                   ;; Format & accumulate sections as table rows.
                   (let ((href (string-append "section-" (number->string i))))
                     (lp (+ i 1)
                         (cons `(tr (@ (id ,href))
                                    (td (@ (class "docs"))
                                        (div (@ (class "pilwrap"))
                                             (a (@ (class "pilcrow")
                                                   (href "#" ,href))
                                                (& "para")))
                                        ,(format docs))
                                    (td (@ (class "code"))
                                        (pre (@ (class "highlight"))
                                             ,(hilite code))))
                               rows))))))))))
      (else
       (die "Unknown output format: " (*output*))))))

;; Loop through all files.
(let lp ((files (command-line-arguments)))
  (unless (null? files)
    (let ((file (car files)))
      (with-input-from-port
        (if (equal? file "-")
          (current-input-port)
          (open-input-file file))
        (lambda ()
          ;; Use the file's name as the title, or the
          ;; `--title` argument if reading from stdin.
          (process-file
            (section-reader (*comment-string*))
            (cond ((equal? file "-")
                   (if (string-null? (*title*))
                     "stdin"
                     (*title*)))
                  (else
                   (pathname-strip-directory file))))
          (close-input-port
            (current-input-port)))))
    (lp (cdr files))))
