;;; dl-zmx-test.el --- ert tests for zmx sessions -*- lexical-binding: t; -*-

;; Run: M-x ert RET dl-zmx RET, or in batch:
;;   emacs -Q --batch -L emacs -l ert -l dl-zmx-test.el -f ert-run-tests-batch-and-exit
;;
;; What is worth testing here is what the plugin still owns: the name it
;; composes, the buffer it reuses, and the name list it completes over. Labels,
;; scopes and state are the wrapper's, and are asserted against its argv in
;; tests/ instead.

(require 'ert)
(require 'dl-zmx)

(ert-deftest dl-zmx/session-name-joins-project-and-identifier ()
  "The one convention left in this file: the wrapper splits at the dot."
  (should (equal (dl-zmx-session-name "hris" "claude") "hris.claude")))

(ert-deftest dl-zmx/buffer-name-is-term-prefixed ()
  (should (equal (dl-zmx-buffer-name "hris.claude") "term-hris.claude")))

(ert-deftest dl-zmx/attach-argv-asks-for-nothing-but-the-name ()
  "Labels, scope and state belong to the wrapper, so the argv is bare attach."
  (let ((dl-zmx-command "zmx")
        (dl-zmx-shell "nu"))
    (should (equal (dl-zmx-attach-argv "hris.claude")
                   '("zmx" "attach" "hris.claude" "nu")))))

(defmacro dl-zmx-test--with-zmx (body &rest script)
  "Run BODY with `dl-zmx-command' bound to a stub running SCRIPT."
  (declare (indent 1))
  `(let ((dl-zmx-command (make-temp-file "zmx-stub")))
     (unwind-protect
         (progn
           (with-temp-file dl-zmx-command
             (insert "#!/bin/sh\n" ,@script))
           (set-file-modes dl-zmx-command #o700)
           ,body)
       (delete-file dl-zmx-command))))

(ert-deftest dl-zmx/sessions-are-the-names-from-ls-short ()
  (dl-zmx-test--with-zmx
   (should (equal (dl-zmx-sessions) '("hris.claude" "other.pi")))
   "[ \"$1 $2\" = 'ls --short' ] || exit 9\nprintf 'hris.claude\\nother.pi\\n'"))

(ert-deftest dl-zmx/sessions-are-nil-when-zmx-cannot-be-asked ()
  "With no store and no sessions, zmx explains itself on stderr and fails."
  (dl-zmx-test--with-zmx
   (should (null (dl-zmx-sessions)))
   "echo 'no sessions found' >&2\nexit 1\n"))

(ert-deftest dl-zmx/project-identifiers-from-session-names ()
  "Only this project's sessions, by identifier."
  (should (equal (dl-zmx-project-identifiers
                  "hris" '("hris.claude" "other.pi" "hris.build" "ls"))
                 '("claude" "build"))))

(ert-deftest dl-zmx/ghostel-exec-callable-before-ghostel-loads ()
  "ghostel is lazy-loaded and doesn't autoload `ghostel-exec' itself."
  (should (fboundp 'ghostel-exec)))

(ert-deftest dl-zmx/offered-on-project-switch ()
  "`project-switch-project' menu offers zmx on `z'."
  (should (equal (assq 'my/zmx-project project-switch-commands)
                 '(my/zmx-project "zmx" "z"))))

(provide 'dl-zmx-test)
;;; dl-zmx-test.el ends here
