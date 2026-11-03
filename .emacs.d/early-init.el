;;; early-init.el --- Early Init File -*- lexical-binding: t -*-
;;; Commentary:
;; Early initialization file loaded before package.el and GUI is initialized
;;; Code:

;; FIX PATH ISSUES EARLY - before any packages load
(setenv "PATH" (concat "/opt/homebrew/bin:" (getenv "PATH")))
(add-to-list 'exec-path "/opt/homebrew/bin")

;; Defer package activation until package-initialize is called explicitly below
(setq package-enable-at-startup nil)

;; Increase GC threshold during startup for better performance
(setq gc-cons-threshold (* 50 1000 1000))

;; Package archives
(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")
                         ("melpa-stable" . "https://stable.melpa.org/packages/")))

;; Initialize package system
(package-initialize)

;; Install use-package if not available
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Configure use-package
(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t)
(setq use-package-verbose t)

;; Force early loading of helm-core to prevent helm-source class errors
(when (package-installed-p 'helm-core)
  (require 'helm-core nil t)
  (require 'helm-source nil t))

;; Disable GUI elements early
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;; No splash screen
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)

;;; early-init.el ends here 