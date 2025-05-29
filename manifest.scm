;;; A GNU Guix (https://guix.gnu.org/) manifest for setting up a
;;; development environment, for example with:
;;;
;;; $ guix shell --pure
;;;
(specifications->manifest
 (list "bash-minimal"
       "coreutils"
       "diffutils"
       "findutils"
       "git-minimal"
       "gawk"
       "go"
       "grep"
       "make"
       "perl"
       "python-minimal"
       "sed"))
