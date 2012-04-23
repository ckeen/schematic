;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; A literate-programming documentation tool a la
;; [docco](http://jashkenas.github.com/docco/).
;;
;; 2012-03-31 Evan Hanson
;;

;; Create a reader that yields two strings,
;; documentation and code, for each commented
;; section read in turn from the given port.
;;
;; If no port is given, the current input
;; port is used.
(define section-reader
  (case-lambda
    ((cs)
     (section-reader cs (current-input-port)))
    ((cs port)
     ;; When a new section is encountered, the continuation
     ;; is captured so the reader can pick up where it left
     ;; off the next time it is invoked.
     (let ((resume #f)
           (cslen (string-length cs)))
       (lambda ()
         (let lp ((docs (open-output-string))
                  (code (open-output-string)))
           (let next-line ()
             (if resume
               (resume)
               (let ((line (read-line port)))
                 (cond
                   ;; When no input remains, the reader returns
                   ;; the end-of-file object for both values.
                   ((eof-object? line)
                    (set! resume
                      (lambda ()
                        (values #!eof #!eof)))
                    (values
                      (get-output-string docs)
                      (get-output-string code)))
                   (else
                    (let ((lnlen (string-length line)))
                      (let scan ((ci 0) (li 0))
                        (cond
                          ;; If the current line is a comment and we
                          ;; haven't read any code yet, write it to the
                          ;; comment string.
                          ((= ci cslen)
                           (cond ((zero? (string-length (get-output-string code)))
                                  (display (substring line li lnlen) docs)
                                  (newline docs)
                                  (next-line))
                                 (else
                                  ;; Otherwise, if we have read code, we're at the
                                  ;; start of a new section. Save the continuation
                                  ;; and yield the current comment/code pair.
                                  (set! resume
                                    (lambda ()
                                      (set! resume #f)
                                      (let ((docs (open-output-string)))
                                        (display (substring line li lnlen) docs)
                                        (newline docs)
                                        (lp docs (open-output-string)))))
                                  (values
                                    (get-output-string docs)
                                    (get-output-string code)))))
                          ;; If the current line is a comment but doesn't
                          ;; match the full comment string format, skip it.
                          ;; Treat everything else as code.
                          ((= li lnlen)
                           (cond ((zero? ci)
                                  (display line code)
                                  (newline code)
                                  (next-line))
                                 (else
                                  (newline docs)
                                  (next-line))))
                          ;; Scan the current line for a comment,
                          ;; skipping leading whitespace.
                          ((< li lnlen)
                           (let ((c (string-ref line li)))
                             (cond ((char=? (string-ref cs ci) c)
                                    (scan (+ ci 1) (+ li 1)))
                                   ((char-whitespace? c)
                                    (scan ci (+ li 1)))
                                   ((zero? ci)
                                    (display line code)
                                    (newline code)
                                    (next-line))
                                   (else
                                    (next-line)))))))))))))))))))
