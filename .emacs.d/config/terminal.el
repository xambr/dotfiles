;;; terminal.el --- Terminal Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Terminal emulator configuration
;;; Code:

;; VTerm terminal emulator
(use-package vterm
  :ensure nil  ; Assuming it's in libs directory
  :if (file-exists-p "~/.emacs.d/libs/emacs-libvterm")
  :config
  (add-to-list 'load-path "~/.emacs.d/libs/emacs-libvterm")
  (setq tramp-mode nil))

;; Julia VTerm (only if available)
(when (package-installed-p 'julia-vterm)
  (use-package julia-vterm
    :after vterm))

(provide 'terminal)
;;; terminal.el ends here 