;;; development.el --- Development Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Development tools, LSP, linting, and programming language support
;;; Code:

;; Direct Python LSP setup - bypass lsp-pyright package issues
(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection '("/opt/homebrew/bin/pyright-langserver" "--stdio"))
                    :major-modes '(python-mode python-ts-mode)
                    :server-id 'pyright
                    :priority 1)))

;; LSP Mode - SAFE AUTOMATIC STARTUP
(use-package lsp-mode
  :commands (lsp lsp-deferred manually-start-lsp safe-lsp-start)
  :init
  ;; Server paths
  (setq lsp-gopls-server-path (expand-file-name "~/go/bin/gopls"))

  ;; Performance
  (setq lsp-log-io nil)
  (setq lsp-idle-delay 0.5)
  (setq lsp-response-timeout 30)
  (setq lsp-enable-file-watchers nil)       ; Too slow on large repos
  (setq lsp-progress-via-spinner nil)       ; No spinner in terminal
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil)

  ;; Features
  (setq lsp-lens-enable t)
  (setq lsp-enable-xref t)
  (setq lsp-enable-symbol-highlighting t)
  (setq lsp-enable-snippet t)
  (setq lsp-signature-auto-activate t)
  (setq lsp-eldoc-enable-hover t)
  (setq lsp-completion-enable t)
  (setq lsp-enable-folding t)
  (setq lsp-enable-imenu t)
  (setq lsp-diagnostics-provider :flycheck)
  (setq lsp-auto-configure t)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-before-save-edits nil)
  (setq lsp-auto-execute-action nil)
  (setq lsp-auto-install-servers nil)
  (setq lsp-suggest-project-file nil)
  
  :config
  ;; Go-specific settings
  (setq lsp-gopls-use-placeholders nil)
  (setq lsp-gopls-completion-use-placeholders nil))



;; Simple LSP hooks
(add-hook 'go-mode-hook #'lsp-deferred)
(add-hook 'python-mode-hook #'lsp-deferred)
(add-hook 'python-ts-mode-hook #'lsp-deferred)
(add-hook 'c-mode-hook #'lsp-deferred)
(add-hook 'c++-mode-hook #'lsp-deferred)
(add-hook 'objc-mode-hook #'lsp-deferred)

;; Basic Go mode without save hooks
(use-package go-mode
  :mode "\\.go\\'"
  :config
  (setq gofmt-command "/opt/homebrew/bin/gofmt")
  (setq gofmt-before-save nil))

;; Python mode configuration - ensure proper file association
(use-package python
  :ensure nil  ; Built into Emacs
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode)
  :interpreter ("python3" . python-mode)
  :config
  ;; Use Python 3.11 as configured in your system
  (setq python-shell-interpreter "python3")
  ;; Disable automatic save hooks that might cause vfork issues
  (setq python-indent-guess-indent-offset-verbose nil))

;; Force Python mode for .py files if it's not working
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; LSP Go support (built into lsp-mode)
(with-eval-after-load 'lsp-mode
  (require 'lsp-go nil t))

;; Python LSP client is now registered directly above

;; C/C++ LSP support with clangd (built into lsp-mode)
(with-eval-after-load 'lsp-mode
  ;; Clangd is automatically detected by lsp-mode
  ;; Set clangd arguments for better performance and features
  (setq lsp-clients-clangd-args
        '("--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=iwyu"
          "--header-insertion-decorators")))

;; LSP UI - DISABLED to avoid vfork errors
;; (use-package lsp-ui
;;   :after lsp-mode
;;   :hook (lsp-mode . lsp-ui-mode)
;;   :config
;;   (setq lsp-ui-sideline-enable t)
;;   (setq lsp-ui-doc-enable t)
;;   (setq lsp-ui-peek-enable t))

;; Additional Go configuration can go here if needed

;; Bazel support with LSP
;; Load bazel-mode from libs directory
(add-to-list 'load-path "~/.emacs.d/libs/emacs-bazel-mode")
(require 'bazel nil t)

;; Configure Bazel file associations
(use-package bazel
  :ensure nil
  :mode (("\\.bazel\\'" . bazel-build-mode)
         ("\\.bzl\\'" . bazel-starlark-mode)
         ("BUILD\\'" . bazel-build-mode)
         ("BUILD\\.bazel\\'" . bazel-build-mode)
         ("WORKSPACE\\'" . bazel-workspace-mode)
         ("WORKSPACE\\.bazel\\'" . bazel-workspace-mode))
  :config
  ;; Set buildifier path for formatting
  (when (executable-find "buildifier")
    (setq bazel-buildifier-command "/opt/homebrew/bin/buildifier"))
  
  ;; Enable formatting on save for Bazel files
  (add-hook 'bazel-build-mode-hook
            (lambda ()
              (when (executable-find "buildifier")
                (add-hook 'before-save-hook 'bazel-buildifier nil t))))
  
  (add-hook 'bazel-starlark-mode-hook
            (lambda ()
              (when (executable-find "buildifier")
                (add-hook 'before-save-hook 'bazel-buildifier nil t))))
  
  (add-hook 'bazel-workspace-mode-hook
            (lambda ()
              (when (executable-find "buildifier")
                (add-hook 'before-save-hook 'bazel-buildifier nil t)))))

;; Configure Bazel LSP support with error suppression
(with-eval-after-load 'lsp-mode
  
  ;; Register Bazel LSP server with error handling
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection 
                                     (lambda ()
                                       ;; Find the Bazel workspace root (directory with WORKSPACE file)
                                       (let* ((current-file (buffer-file-name))
                                              (workspace-root (locate-dominating-file current-file "WORKSPACE")))
                                         ;; Use let-binding to temporarily change directory for LSP connection only
                                         (let ((default-directory (or workspace-root default-directory)))
                                           (list "/opt/homebrew/bin/bazel-lsp")))))
                    :activation-fn (lsp-activate-on "bazel" "starlark")
                    :server-id 'bazel-lsp
                    :priority 1
                    ;; Suppress error notifications
                    :notification-handlers (ht ("window/showMessage" 'ignore)
                                               ("window/logMessage" 'ignore))
                    :request-handlers (ht)))
  
  ;; Add Bazel modes to LSP
  (add-to-list 'lsp-language-id-configuration '(bazel-build-mode . "bazel"))
  (add-to-list 'lsp-language-id-configuration '(bazel-starlark-mode . "starlark"))
  (add-to-list 'lsp-language-id-configuration '(bazel-workspace-mode . "bazel")))

;; Enable LSP for Bazel modes with conditional activation
;; Only enable LSP for smaller Bazel files to avoid external repository issues
(defun maybe-enable-bazel-lsp ()
  "Enable Bazel LSP only for files that are likely to work well with it."
  (when (and (buffer-file-name)
             (< (buffer-size) 50000)  ; Only enable for files smaller than 50KB
             (not (string-match-p "@.*//.*:" (or (buffer-file-name) ""))))  ; Skip external repo files
    (lsp-deferred)))

(add-hook 'bazel-build-mode-hook #'maybe-enable-bazel-lsp)
(add-hook 'bazel-starlark-mode-hook #'lsp-deferred)  ; .bzl files usually work better
(add-hook 'bazel-workspace-mode-hook #'maybe-enable-bazel-lsp)

;; Manual Bazel definition lookup for external repositories
(defun bazel-find-external-definition ()
  "Find definition for external Bazel repository symbols."
  (interactive)
  (let* ((symbol (thing-at-point 'symbol t))
         (line (thing-at-point 'line t)))
    (cond
     ;; Handle load statements
     ((or (string-match "load(\"\\(@[^\"]+\\)\"" line)
          (string-match "\\(@[^/]+//[^\"]+\\)" line))
      (let* ((repo-path (match-string 1 line))
             (output-base (string-trim (shell-command-to-string "cd ~/dd/dd-source && bazel info output_base")))
             (repo-name (if (string-match "@\\([^/]+\\)" repo-path) (match-string 1 repo-path) ""))
             ;; Parse the file path correctly: @repo//package:file -> package/file
             (file-path (if (string-match "@[^/]+//\\([^:]+\\):\\(.+\\)" repo-path) 
                           (concat (match-string 1 repo-path) "/" (match-string 2 repo-path))
                         (if (string-match "@[^/]+//\\(.+\\)" repo-path) (match-string 1 repo-path) "")))
             (external-path (concat output-base "/external/" repo-name "/" file-path)))
        (if (file-exists-p external-path)
            (find-file external-path)
          (message "External file not found: %s" external-path))))
     ;; Handle target references
     ((string-match "@\\([^/]+\\)//\\([^:]+\\):\\([^\"]+\\)" (or symbol line ""))
      (message "Target: %s in repository %s, package %s" 
               (match-string 3 (or symbol line "")) 
               (match-string 1 (or symbol line "")) 
               (match-string 2 (or symbol line ""))))
     (t (message "No external repository reference found at point")))))

;; Manual lookup function available via M-x bazel-find-external-definition

;; Flycheck - fix the initialization
(use-package flycheck
  :hook (prog-mode . flycheck-mode)
  :config
  ;; Enable global flycheck mode for better activation
  (global-flycheck-mode 1)
  
  ;; Terminal-only configuration (no fringe/margin indicators)
  (setq flycheck-indication-mode nil)                ; No visual indicators
  (setq flycheck-highlighting-mode 'lines)           ; Highlight problem lines
  (setq flycheck-check-syntax-automatically '(save idle-change new-line mode-enabled))
  (setq flycheck-idle-change-delay 0.5)
  
  ;; Show errors when cursor is on problematic line
  (setq flycheck-display-errors-function #'flycheck-display-error-messages)
  (setq flycheck-display-errors-delay 0.3)
  
  ;; Python settings
  (setq flycheck-flake8-maximum-line-length 100)
  (setq flycheck-python-flake8-executable "/opt/homebrew/bin/flake8")
  (setq flycheck-python-ruff-executable "/opt/homebrew/bin/ruff")
  
  ;; Python Ruff checker - only define if flycheck is available
  (when (fboundp 'flycheck-define-checker)
    (flycheck-define-checker python-ruff
      "A Python syntax and style checker using Ruff."
      :command ("ruff" "check" "--output-format=concise" source-original)
      :error-patterns
      ((error line-start (file-name) ":" line ":" column ": " (message) line-end)
       (warning line-start (file-name) ":" line ":" column ": " (message) line-end))
      :modes (python-mode python-ts-mode)
      :predicate (lambda () (and (buffer-file-name) (file-exists-p (buffer-file-name)))))
    
    ;; Add ruff as the preferred checker
    (add-to-list 'flycheck-checkers 'python-ruff)))

;; YAML mode with linting
(use-package yaml-mode
  :mode "\\.ya?ml\\'")

(use-package flycheck-yamllint
  :after (flycheck yaml-mode)
  :hook (flycheck-mode . flycheck-yamllint-setup))

;; JSON mode
(use-package json-mode
  :mode "\\.json\\'")

;; Markdown
(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)))

;; Dockerfile
(use-package dockerfile-mode
  :mode "Dockerfile\\'")

;; Terraform
(use-package terraform-mode
  :mode "\\.tf\\'")

;; Protocol Buffers
(use-package protobuf-mode
  :mode "\\.proto\\'")

;; Code folding
(add-hook 'prog-mode-hook (lambda () (hs-minor-mode t)))

;; Company mode for completion
(use-package company
  :hook (after-init . global-company-mode)
  :config
  (setq company-minimum-prefix-length 4))

;; Projectile
(use-package projectile
  :bind-keymap ("C-c p" . projectile-command-map)
  :ensure t
  :config
  (projectile-mode 1))

;; Magit
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
  :config
  ;; Set git executable path explicitly
  (when (executable-find "/opt/homebrew/bin/git")
    (setq magit-git-executable "/opt/homebrew/bin/git"))
  ;; Improve performance
  (setq magit-refresh-status-buffer nil)
  (setq magit-refresh-verbose t)
  )

;; Forge - GitHub/GitLab integration
;; :ensure nil because forge's MELPA tarball is intermittently unavailable.
;; Install manually with M-x package-install RET forge when needed.
(use-package forge
  :ensure nil
  :if (package-installed-p 'forge)
  :after magit)

;; Git lens (non-standard package, managed manually)
(use-package git-lens
  :ensure nil
  :if (package-installed-p 'git-lens)
  :after magit)

;; DAP mode for debugging
(use-package dap-mode
  :after lsp-mode
  :commands (dap-debug dap-mode dap-ui-mode)
  :config
  ;; Load dap-ui first before calling dap-ui-mode
  (require 'dap-ui)
  
  ;; Enable dap-mode features
  (dap-auto-configure-mode)
  
  ;; Load language-specific DAP configurations as needed
  (require 'dap-python nil t)
  (require 'dap-go nil t))

;; Optionally enable dap-ui-mode globally (uncomment if desired)
;; (add-hook 'dap-mode-hook 'dap-ui-mode)

(provide 'development)
;;; development.el ends here 
