;;; dl-zmx.el --- project terminals in zmx sessions -*- lexical-binding: t; -*-

;; A ghostel buffer `term-PROJECT.ID' attached to the zmx session of that name;
;; `my/zmx-switch' picks any running session and reattaches.
;;
;;   ghostel term-P.ID   (cwd: project root)
;;     `-- zmx attach P.ID nu
;;
;; Naming, labels and durability belong to the `zmx' wrapper this repo installs
;; by overlay: it writes `project' and `id' from the name, births the session in
;; its own systemd scope, and asks every caller for nothing but the name. So
;; this file composes `PROJECT.ID' and attaches. It derives no labels, parses no
;; `zmx list' records, and launches no scope of its own.
;;
;; Two names the wrapper refuses land its message in the buffer: a project that
;; contains a dot (`p.i' splits once, at the first dot) and a leading dot, which
;; leaves no project at all.

(require 'seq)
(require 'subr-x)
(require 'project)
(autoload 'ghostel-exec "ghostel")   ; ghostel only autoloads its commands

(defgroup dl-zmx nil
  "Persistent project terminals via zmx."
  :group 'terminals)

(defcustom dl-zmx-command "zmx"
  "Command used to invoke zmx.
Use the wrapper this repo installs: it is what supplies labels and a scope."
  :type 'string)

(defcustom dl-zmx-shell "nu"
  "Shell zmx runs in a new session."
  :type 'string)

;;; Names

(defun dl-zmx-session-name (project identifier)
  "Return the zmx session name for PROJECT and IDENTIFIER."
  (format "%s.%s" project identifier))

(defun dl-zmx-buffer-name (session)
  "Return the ghostel buffer name for zmx SESSION."
  (concat "term-" session))

(defun dl-zmx-attach-argv (session)
  "Return argv attaching to SESSION, creating it if absent."
  (list dl-zmx-command "attach" session dl-zmx-shell))

;;; Sessions: names only

(defun dl-zmx-sessions ()
  "Return the names of running zmx sessions, or nil if zmx cannot be asked.
`zmx ls --short' is a list of names, not `zmx list'\\='s field grammar:
grouping comes from the labels the wrapper wrote, so nothing here parses a
session record."
  (ignore-errors (process-lines dl-zmx-command "ls" "--short")))

(defun dl-zmx-project-identifiers (project names)
  "Return identifiers of PROJECT's sessions among session NAMES."
  (let ((prefix (dl-zmx-session-name project "")))
    (mapcar (lambda (name) (string-remove-prefix prefix name))
            (seq-filter (lambda (name) (string-prefix-p prefix name)) names))))

;;; Commands

(defun dl-zmx--open (session argv)
  "Pop to SESSION's ghostel buffer; run ARGV in it unless already running."
  (let ((buffer (get-buffer-create (dl-zmx-buffer-name session))))
    (pop-to-buffer buffer)        ; display first: size the PTY to the window
    (unless (process-live-p (get-buffer-process buffer))
      (ghostel-exec buffer (car argv) (cdr argv)))))

(defun my/zmx-project (identifier)
  "Open zmx session PROJECT-IDENTIFIER in a terminal at the project root.
Completes the identifiers of the project's running sessions."
  (interactive
   (list (completing-read "zmx session: "
                          (dl-zmx-project-identifiers
                           (project-name (project-current t))
                           (dl-zmx-sessions)))))
  (when (string-empty-p identifier)
    (user-error "Empty zmx session identifier"))
  (let* ((project (project-current t))
         (session (dl-zmx-session-name (project-name project) identifier))
         (default-directory (project-root project)))
    (dl-zmx--open session (dl-zmx-attach-argv session))))

(defun my/zmx-switch (session)
  "Show running zmx SESSION: its buffer, or a new one reattached to it."
  (interactive (list (completing-read "zmx: " (dl-zmx-sessions))))
  (when (string-empty-p session)
    (user-error "No zmx session given"))
  (dl-zmx--open session (dl-zmx-attach-argv session)))

;; `C-c p p' menu: switch project, then `z'.
(add-to-list 'project-switch-commands '(my/zmx-project "zmx" "z") t)

(provide 'dl-zmx)
;;; dl-zmx.el ends here
