;;; core.el --- Core Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Core Emacs configuration and basic settings
;;; Code:

;; Performance optimizations
(setq read-process-output-max (* 1024 1024)) ; 1MB
(setq create-lockfiles nil)
(setq make-backup-files nil)
(setq auto-save-default nil)

;; Better defaults
(setq-default
 indent-tabs-mode nil
 tab-width 2
 standard-indent 2
 c-basic-offset 2
 js-indent-level 2
 default-tab-width 2)

;; UI improvements
(setq column-number-mode t)
(setq line-number-mode t)
(setq show-trailing-whitespace t)
(setq mode-line-compact t)
(setq confirm-kill-emacs 'y-or-n-p)

;; Better backup handling
(setq backup-directory-alist `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; Clean up old backups on startup
(defun cleanup-old-backups ()
  "Delete backup files older than a week."
  (message "Deleting old backup files...")
  (let ((week (* 60 60 24 7))
        (current (float-time (current-time))))
    (dolist (file (directory-files temporary-file-directory t))
      (when (and (backup-file-name-p file)
                 (> (- current (float-time (nth 4 (file-attributes file))))
                    week))
        (message "%s" file)
        (delete-file file)))))

;; Add subdirectories to load path
(let ((default-directory "~/.emacs.d/"))
  (normal-top-level-add-subdirs-to-load-path))

;; Suppress warnings
(setq warning-suppress-log-types '((emacs)))

;; Desktop session configuration
(use-package desktop
  :ensure nil
  :config
  (setq desktop-clear-preserve-buffers
        '("\\*Messages\\*" "\\*server\\*" "\\*tramp/.+\\*" "\\*Warnings\\*"))
  (setq desktop-globals-to-clear nil)
  (setq desktop-globals-to-save
        '(desktop-missing-file-warning tags-file-name tags-table-list
                                       search-ring regexp-search-ring
                                       register-alist file-name-history
                                       kill-ring))
  (desktop-save-mode 1))

;; Winner mode for window configuration undo/redo
(use-package winner
  :ensure nil
  :config
  (winner-mode 1))

;; Uniquify buffer names
(use-package uniquify
  :ensure nil
  :config
  (setq uniquify-buffer-name-style 'post-forward))

(provide 'core)
;;; core.el ends here 