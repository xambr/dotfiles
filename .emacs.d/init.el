;;; .emacs --- Emacs Configuration File -*- lexical-binding: t -*-
;;; Commentary:
;; Modern Emacs configuration using use-package and modular structure
;; All specific configurations are organized in ~/.emacs.d/config/
;;; Code:

;; Ensure use-package is available
(require 'use-package)

;; Add config directory to load path
(add-to-list 'load-path (expand-file-name "config" user-emacs-directory))

;; Load configuration modules in order
(require 'core)         ; Core settings and performance
(require 'ui)           ; Themes, powerline, visual settings
(require 'keybindings)  ; Custom keybindings and functions

;; Load optional modules if available
(require 'helm-config)                  ; Helm completion framework
(ignore-errors (require 'development))  ; Programming languages and tools
(ignore-errors (require 'ai))           ; AI assistants (GPT)
(ignore-errors (require 'org-config))   ; Org mode configuration
(ignore-errors (require 'terminal))     ; Terminal emulator

(defvar eglot-server-programs nil)

;; Clean up old backups on startup
(cleanup-old-backups)

;; Reset GC threshold after startup for better runtime performance
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1000 1000)))) ; 2MB

;; Package list for reference (automatically managed by use-package)
(setq package-selected-packages
      '(ag apropospriate-theme bazel company compat copyit dap-mode
           dape dockerfile-mode exec-path-from-shell flex-compile
           flycheck-yamllint git-lens go-mode gptel helm
           helm-ispell helm-ls-git helm-org
           helm-system-packages json-mode julia-vterm
           lazy-ruff lsp-mode lsp-java lsp-pyre lsp-pyright magit magit-popup
           magithub markdown-preview-mode nlinum-hl org-assistant
           org-bullets powerline projectile protobuf-mode ruff-format
           solarized-theme terraform-mode transient uniquify-files
           use-package-hydra vterm yaml yaml-mode yasnippet))

(provide '.emacs)
;;; .emacs ends here

;; Custom variables and faces (automatically added by Emacs)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(lsp-response-timeout 30)
 '(package-selected-packages
   '(claude-code-ide company dap-mode dockerfile-mode flycheck-yamllint
                     go-mode gptel helm-projectile ibuffer-projectile
                     json-mode kubed magit org-bullets org-jira
                     powerline protobuf-mode solarized-theme
                     terraform-mode yaml-mode))
 '(package-vc-selected-packages
   '((claude-code-ide :url
                      "https://github.com/manzaltu/claude-code-ide.el")))
 '(safe-local-variable-values
   '((eval add-to-list 'eglot-server-programs
           '((js-mode js-ts-mode tsx-ts-mode typescript-mode
                      typescript-ts-mode)
             "yarn" "typescript-language-server" "--stdio"
             :initializationOptions
             (:preferences (:importModuleSpecifier "non-relative")
                           :maxTsServerMemory 16384))))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(aw-background-face ((t (:foreground "gray50"))))
 '(aw-leading-char-face ((t (:foreground "red" :background "white" :weight bold :height 3.0))))
 '(gptel-context-highlight-face ((t nil)))
 '(powerline-active1 ((t (:foreground "black" :background "lightgray" :inherit mode-line))))
 '(powerline-active2 ((t (:background "lightgray" :inherit mode-line))))
 '(powerline-inactive1 ((t (:background "lavender" :inherit mode-line-inactive))))
 '(powerline-inactive2 ((t (:background "lavender" :inherit mode-line-inactive)))))
