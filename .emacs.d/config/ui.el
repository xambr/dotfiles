;;; ui.el --- UI Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; User interface configuration including themes, powerline, and visual settings
;;; Code:

;; Theme
(use-package solarized-theme
  :config
  (load-theme 'solarized-light t)
  (setq custom-safe-themes
        '("a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e"
          default)))

;; Powerline
(use-package powerline
  :config
  (setq mode-line-percent-position nil)
  (setq mode-line-position-column-line-format '(" [%l,%c]"))
  (setq mode-line-format
        '("%e"
          (:eval
           (let*
               ((active (powerline-selected-window-active))
                (mode-line-buffer-id
                 (if active 'mode-line-buffer-id
                   'mode-line-buffer-id-inactive))
                (mode-line (if active 'mode-line 'mode-line-inactive))
                (face1 (if active 'powerline-active1 'powerline-inactive1))
                (face2 (if active 'powerline-active2 'powerline-inactive2))
                (separator-left
                 (intern
                  (format "powerline-%s-%s" (powerline-current-separator)
                          (car powerline-default-separator-dir))))
                (separator-right
                 (intern
                  (format "powerline-%s-%s" (powerline-current-separator)
                          (cdr powerline-default-separator-dir))))
                (lhs
                 (list (powerline-raw "%*" mode-line 'l)
                       (powerline-buffer-id mode-line-buffer-id 'l)
                       (funcall separator-left mode-line face2)
                       (powerline-raw "%4l" face2 'l)
                       (powerline-raw " " face2) (powerline-raw ":" face2)
                       (powerline-raw "%3c" face2 'l)
                       (powerline-raw " " face2)
                       (funcall separator-left face2 face1)
                       (powerline-narrow face1 'l) (powerline-vc face1)))
                (rhs
                 (list (powerline-raw global-mode-string face1 'r)
                       (funcall separator-right face1 mode-line)
                       (powerline-raw " " mode-line)
                       (powerline-raw "%6p" mode-line 'r)
                       (powerline-hud face2 face1)))
                (center
                 (list (powerline-raw " " face1)
                       (funcall separator-left face1 face2)
                       (when
                           (and (boundp 'erc-track-minor-mode)
                                erc-track-minor-mode)
                         (powerline-raw erc-modified-channels-object face2
                                        'l))
                       (powerline-major-mode face2 'l)
                       (powerline-process mode-line)
                       (powerline-raw " " face2)
                       (funcall separator-right face2 face1))))
             (concat (powerline-render lhs)
                     (powerline-fill-center face1
                                            (/ (powerline-width center) 2.0))
                     (powerline-render center)
                     (powerline-fill face1 (powerline-width rhs))
                     (powerline-render rhs)))))))

;; Global highlight line mode
(use-package hl-line
  :ensure nil
  :config
  (global-hl-line-mode t))

;; Window management
(use-package ace-window
  :bind (("C-x o" . ace-window)
         ("C-x d" . ace-delete-window))
  :config
  ;; Use character literals instead of numeric codes
  (setq aw-keys '(?a ?s ?d ?f ?g))
  ;; Enable ace-window-display-mode properly
  (ace-window-display-mode 1)
  ;; Show labels in minibuffer too
  (setq aw-minibuffer-flag t)
  ;; Make sure labels are visible
  (setq aw-background t)
  ;; Set scope to frame for better visibility
  (setq aw-scope 'frame))

;; Vertical border styling
(set-face-background 'vertical-border "gray")
(set-face-foreground 'vertical-border (face-background 'vertical-border))

;; Mode line buffer identification
(setq mode-line-buffer-identification
      '(:eval (abbreviate-file-name (buffer-file-name))))

;; Custom faces
(custom-set-faces
 '(powerline-active1 ((t (:foreground "black" :background "lightgray" :inherit mode-line))))
 '(powerline-active2 ((t (:background "lightgray" :inherit mode-line))))
 '(powerline-inactive1 ((t (:background "lavender" :inherit mode-line-inactive))))
 '(powerline-inactive2 ((t (:background "lavender" :inherit mode-line-inactive))))
 ;; Ace-window faces to ensure labels are visible
 '(aw-leading-char-face ((t (:foreground "red" :background "white" :weight bold :height 3.0))))
 '(aw-background-face ((t (:foreground "gray50")))))

(provide 'ui)
;;; ui.el ends here 