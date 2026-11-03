;;; ai.el --- AI Assistant Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Configuration for AI assistants: gptel, Copilot, Claude Code IDE
;;; Code:

;; Ensure auth-source reads from ~/.authinfo before any package looks up keys
(require 'auth-source)
(setq auth-sources '("~/.authinfo"))

;; GPTel — chat interface supporting OpenAI, Anthropic, and other backends
(use-package gptel
  :bind (("C-c g g" . gptel)
         ("C-c g s" . gptel-send)
         ("C-c g m" . gptel-menu)
         ("C-c g r" . gptel-rewrite))
  :config
  (setq gptel-api-key (auth-source-pick-first-password :host "api.openai.com"))
  (gptel-make-anthropic "Claude"
    :stream t
    :key (auth-source-pick-first-password :host "api.anthropic.com")))

;; Claude Code IDE — bidirectional MCP integration with Claude Code CLI
;; Authenticate via API key from ~/.authinfo, bypassing the OAuth browser flow
;; (which is blocked on the Datadog network).
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :init
  (require 'auth-source)
  (when-let ((key (auth-source-pick-first-password :host "api.anthropic.com")))
    (setenv "ANTHROPIC_API_KEY" key))
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

(provide 'ai)
;;; ai.el ends here
