# schematic

A simple literate-programming documentation tool a la [docco][].

[docco]: http://jashkenas.github.com/docco/

## Requirements

  * [chicken](http://call-cc.org)
  * [fmt](http://wiki.call-cc.org/egg/fmt) (for ansi output)
  * [sxml-transforms](http://wiki.call-cc.org/egg/sxml-transforms) (for html output)
  * [colorize](http://wiki.call-cc.org/egg/colorize) (for syntax highlighting)

## Install

    $ git clone git://bitbucket.com/evhan/schematic.git
    $ cd schematic
    $ chicken-install

## Usage

The `schematic` command takes some number of input files as arguments and
outputs formatted, side-by-side documentation & source code for each.

    schematic [option ...] [file ...]

    options:
      -h, --help            show this message
      -o, --output          output format (html, ansi)
      -f, --formatter       external comment string formatting command
      -s, --highlighter     external syntax highlighting command
      -c, --comment-string  comment string format
      -l, --language        language name (html, built-in syntax highlighter only)
          --stylesheet      alternative stylesheet (html only)
          --directory       output directory (html only)

Two output modes are available, `ansi` and `html`. In `ansi` mode, concatenated
output for all files is written to stdout. In `html` mode, separate HTML files
are written to an output directory, along with associated styling. This is the
default behavior.

When specifying input files, a dash represents `stdin`.

`--formatter` and `--highlighter` specify external commands that will be
used to process documentation and code, respectively. [`markdown`][markdown]
and [`highlight`][highlight] might be good choices.

`--comment-string` specifies the prefix to use for identifying comment lines.
For example, for Bash or Ruby, `--comment-string "# "` would give the intended
results.

[markdown]: http://daringfireball.net/projects/markdown/
[highlight]: http://www.andre-simon.de/doku/highlight/en/highlight.html

## License

BSD. See LICENSE for details.
