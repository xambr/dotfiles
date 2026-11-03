;;; keybindings.el --- Custom Keybindings -*- lexical-binding: t -*-
;;; Commentary:
;; Custom keybindings and utility functions
;;; Code:

;; No easy keys mode
(use-package no-easy-keys
  :ensure nil
  :config
  (add-to-list 'load-path "~/.emacs.d/libs/emacs-no-easy-keys")
  (no-easy-keys 1))

;; Disable problematic keys
(global-unset-key [(control z)])
(global-unset-key [(control x)(control z)])

;; Movement keys
(global-set-key (kbd "M-g a") 'beginning-of-buffer)
(global-set-key (kbd "M-g e") 'end-of-buffer)
(global-set-key (kbd "C-t") 'scroll-down-command)

;; Window management
(global-set-key (kbd "C-x 5") 'toggle-frame-split)

;; Copy utility functions
(defun get-point (symbol &optional arg)
  "Get the point of the given SYMBOL with optional ARG."
  (funcall symbol arg)
  (point))

(defun copy-thing (begin-of-thing end-of-thing &optional arg)
  "Copy thing between beg & end into kill ring.  ARG, BEGIN-OF-THING, END-OF-THING are functions to determine the start and end points respectively."
  (save-excursion
    (let ((beg (get-point begin-of-thing 1))
          (end (get-point end-of-thing arg)))
      (copy-region-as-kill beg end))))

(defun copy-line (&optional arg)
  "Save current line into `kill-ring` without mark the line.  ARG is passed to `copy-thing` to specify the number of lines to copy."
  (interactive "P")
  (copy-thing 'beginning-of-line 'end-of-line arg)
  (message "Copied: %s" (current-kill 0)))

(defun copy-word (&optional arg)
  "Copy words at point into `kill-ring` without marking the word.  ARG is passed to `copy-thing` to specify the number of words to copy."
  (interactive "P")
  (copy-thing 'backward-word 'forward-word arg)
  (message "Copied: %s" (current-kill 0)))

(defun backward-word-whole (&optional arg)
  "Move backward over a word, treating underscores as part of words.  ARG is passed to specify the number of words to move."
  (interactive)
  (with-syntax-table (copy-syntax-table)
    (modify-syntax-entry ?_ "w")  ;; Treat _ as part of words
    (backward-word)))

(defun forward-word-whole (&optional arg)
  "Move to the end of the current word, treating underscores as part of words.  ARG is passed to specify the number of words to move."
  (interactive)
  (skip-syntax-forward "w_")
  (while (looking-at "_")
    (forward-char)))

(defun copy-full-word (&optional arg)
  "Copy the whole word at point, treating underscores as part of words.  ARG is passed to `copy-thing` to specify the number of whole words to copy."
  (interactive)
  (copy-thing #'backward-word-whole #'forward-word-whole)
  (message "Copied: %s" (current-kill 0)))

;; Copy function keybindings
(global-set-key (kbd "C-h l") 'copy-line)
(global-set-key (kbd "C-h w") 'copy-word)
(global-set-key (kbd "C-h z") 'copy-full-word)

;; Window split toggle function
(defun toggle-frame-split ()
  "If the frame is split vertically, split it horizontally or vice versa.
Assumes that the frame is only split into two."
  (interactive)
  (unless (= (length (window-list)) 2) 
    (error "Can only toggle a frame split in two"))
  (let ((split-vertically-p (window-combined-p)))
    (delete-window) ; closes current window
    (if split-vertically-p
        (split-window-horizontally)
      (split-window-vertically)) ; gives us a split with the other window twice
    (switch-to-buffer nil))) ; restore the original window in this part of the frame

;; Terminal Emacs: limit mouse drag selection to the window where the drag started.
;; Replaces mouse-drag-region ([down-mouse-1]) which crosses window boundaries
;; because terminal mouse coordinates are absolute screen positions.
(unless window-system
  (defun my/mouse-drag-confined (start-event)
    "Drag-select text, but never cross into another Emacs window."
    (interactive "e")
    (let* ((start-window (posn-window (event-start start-event)))
           (start-pt (progn (select-window start-window)
                            (mouse-set-point start-event)
                            (point)))
           ev)
      (track-mouse
        (while (mouse-movement-p (setq ev (read-event)))
          (when (eq (posn-window (event-end ev)) start-window)
            (mouse-set-point ev)
            (unless (= (point) start-pt)
              (or (region-active-p) (push-mark start-pt t t))
              (activate-mark)))))
      ;; ev now holds the mouse-1 release event; it was consumed by read-event
      ;; so it won't re-trigger [mouse-1] binding — no cleanup needed.
      (unless (region-active-p)
        (deactivate-mark))))
  (global-set-key [down-mouse-1] #'my/mouse-drag-confined))

(provide 'keybindings)
;;; keybindings.el ends here 