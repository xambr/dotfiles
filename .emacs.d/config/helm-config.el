;;; helm-config.el --- Helm Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Helm completion framework configuration
;;; Code:

;; Configure helm if it's available
(when (package-installed-p 'helm)
  ;; Load helm and ensure all functions are available
  (require 'helm)
  (require 'helm-mode)
  
  ;; Enable helm-mode for better completion
  (helm-mode 1)
  
  ;; Set up keybindings
  (global-set-key (kbd "M-x") 'helm-M-x)
  (global-set-key (kbd "C-x r b") 'helm-filtered-bookmarks)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "C-x b") 'helm-mini)
  
  ;; Use local helm-ag from libs directory if ag/silver searcher is available
  (when (executable-find "ag")
    ;; Load helm-ag from libs directory first
    (when (file-exists-p "~/.emacs.d/libs/helm-ag.el")
      (add-to-list 'load-path "~/.emacs.d/libs")
      (autoload 'helm-ag "helm-ag" "Helm ag search" t)
      (autoload 'helm-ag-this-file "helm-ag" "Helm ag this file" t)
      (autoload 'helm-ag-project-root "helm-ag" "Helm ag project root" t)
      (global-set-key (kbd "C-c a g") 'helm-ag)
      (global-set-key (kbd "C-c a f") 'helm-ag-this-file)
      (message "Using local helm-ag from libs directory")))
  
  ;; Defer helm configuration until after it's loaded
  (eval-after-load 'helm
    '(progn
       (setq helm-M-x-fuzzy-match t)
       (setq helm-buffer-details-flag t)
       (setq helm-buffer-max-length 63)
       (setq helm-buffer-skip-remote-checking t)
       (setq helm-buffers-fuzzy-matching t)
       (setq helm-buffers-left-margin-width 1)
       (setq helm-ff-use-notify nil)
       (setq helm-find-files-ignore-thing-at-point t)
       ;; Always start helm-find-files from current buffer's directory
       (setq helm-ff-default-directory-function
             (lambda () (if (buffer-file-name)
                           (file-name-directory (buffer-file-name))
                         default-directory)))
       (setq helm-move-to-line-cycle-in-source nil)
       (setq helm-buffer--pretty-names
             '((dired-mode . "Dired") 
               (lisp-interaction-mode . "Lisp Inter")
               (BUILD.bazel . "Bazel"))))))

;; Helm projectile
(use-package helm-projectile
  :after (projectile)
  :config
  (helm-projectile-on))


;; Fallback if helm is not available - use standard Emacs completion (no ido)
(unless (package-installed-p 'helm)
  (message "Helm not installed - using standard Emacs completion")
  (global-set-key (kbd "M-x") 'execute-extended-command)
  (global-set-key (kbd "C-x C-f") 'find-file)
  (global-set-key (kbd "C-x b") 'switch-to-buffer)
  (global-set-key (kbd "C-x r b") 'bookmark-jump))

(provide 'helm-config)
;;; helm-config.el ends here 
