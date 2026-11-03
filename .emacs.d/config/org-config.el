;;; org-config.el --- Org Mode Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Org mode configuration for note-taking and task management
;;; Code:

;; Ensure .org files open in org-mode
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;; Force org-mode to be available without autoload issues
(require 'org nil t)

;; Org mode configuration
(with-eval-after-load 'org
  (setq org-hide-emphasis-markers t)
  (setq org-jira-download-dir "~/.jira")
  ;; Custom bullet points
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•")))))))

;; Org bullets (only if available)
(when (package-installed-p 'org-bullets)
  (with-eval-after-load 'org
    (require 'org-bullets nil t)
    (when (fboundp 'org-bullets-mode)
      (add-hook 'org-mode-hook 'org-bullets-mode))))

;; Org assistant (only if available)
(when (package-installed-p 'org-assistant)
  (with-eval-after-load 'org
    (require 'org-assistant nil t)))

(define-key org-mode-map (kbd "C-c p") 'org-do-promote)
(define-key org-mode-map (kbd "C-c d") 'org-do-demote)

;; Style "anything -----" lines: purple+bold text, hidden dashes, always.
(with-eval-after-load 'org
  (font-lock-add-keywords
   'org-mode
   '(("^\\(.*?\\)\\(\\s-*-----+\\s-*\\)$"
      (1 '(face (:foreground "purple" :weight bold)) t)
      (2 '(face nil invisible t) t)))
   t))

;; Show "anything -----" lines as before-string on next visible element
;; when hidden by a fold. Org's fold state is untouched.
(defvar-local my/separator-overlays nil)

(defun my/org-refresh-separators-now ()
  (when (derived-mode-p 'org-mode)
    (mapc #'delete-overlay my/separator-overlays)
    (setq my/separator-overlays nil)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^.*-----" nil t)
        (let ((sep-pos (line-beginning-position))
              (sep-text (replace-regexp-in-string
                         "\\s-*-----+\\s-*$" ""
                         (buffer-substring-no-properties
                          (line-beginning-position) (line-end-position)))))
          (when (org-fold-folded-p sep-pos)
            (save-excursion
              (goto-char sep-pos)
              (outline-previous-heading)
              (while (and (> (point) (point-min)) (org-fold-folded-p (point)))
                (outline-previous-heading))
              (when (org-at-heading-p)
                (let* ((fold-end (save-excursion
                                   (org-end-of-subtree t t)
                                   (unless (eobp) (forward-char -1))
                                   (point)))
                       (after-fold (1+ fold-end)))
                  (when (< after-fold (point-max))
                    (let ((ov (make-overlay after-fold after-fold)))
                      (overlay-put ov 'before-string
                        (propertize (concat "\n" sep-text "\n")
                                    'face '(:foreground "purple" :weight bold)))
                      (push ov my/separator-overlays))))))))))))

(defun my/org-refresh-separators (&rest _)
  (my/org-refresh-separators-now))

(with-eval-after-load 'org
  (add-hook 'org-mode-hook #'my/org-refresh-separators)
  (advice-add 'org-cycle :after #'my/org-refresh-separators))

(with-eval-after-load 'flycheck
  (setq-default flycheck-disabled-checkers '(org-lint)))

;; Sort top-level subtrees within the current "----- section".
;; Order follows the buffer's `#+TODO:' line; `:inspiration:' goes last;
;; original order is a stable tiebreaker.

(defun org-reorder--todo-keyword-ranks ()
  "Return alist of (KEYWORD . RANK) parsed from the first `#+TODO:' line."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^#\\+TODO:[ \t]*\\(.*\\)$" nil t)
      (let ((rank 0) result)
        (dolist (tok (split-string (match-string 1) "[ \t]+" t))
          (unless (string= tok "|")
            (let ((kw (if (string-match "\\`\\([^(]+\\)" tok)
                          (match-string 1 tok)
                        tok)))
              (push (cons kw rank) result)
              (setq rank (1+ rank)))))
        (nreverse result)))))

(defun org-reorder--section-bounds ()
  "Return (START . END) for the section around point, exclusive of `-----' lines."
  (let ((boundary-re "^[^*\n]*-----"))
    (save-excursion
      (beginning-of-line)
      (when (looking-at boundary-re)
        (forward-line 1))
      (let ((start (save-excursion
                     (if (re-search-backward boundary-re nil t)
                         (progn (forward-line 1) (point))
                       (point-min))))
            (end (save-excursion
                   (if (re-search-forward boundary-re nil t)
                       (line-beginning-position)
                     (point-max)))))
        (cons start end)))))

(defun org-reorder--collect-subtrees (start end)
  "Return (PREAMBLE . SUBTREES) for level-1 subtrees between START and END.
Uses Org navigation so example/source blocks don't confuse boundaries."
  (save-excursion
    (goto-char start)
    (let (preamble subtrees first)
      (save-excursion
        (while (and (not first)
                    (outline-next-heading)
                    (< (point) end))
          (when (= (org-current-level) 1)
            (setq first (point)))))
      (setq preamble (buffer-substring-no-properties start (or first end)))
      (when first
        (goto-char first)
        (while (< (point) end)
          (let ((s (point)))
            (org-end-of-subtree t t)
            (let ((e (min (point) end)))
              (push (buffer-substring-no-properties s e) subtrees)
              (goto-char e)))))
      (cons preamble (nreverse subtrees)))))

(defun org-reorder--subtree-rank (subtree ranks unknown-rank inspiration-rank)
  "Rank SUBTREE: inspiration tag wins; else TODO keyword lookup; else unknown."
  (let* ((nl (string-match "\n" subtree))
         (first-line (substring subtree 0 (or nl (length subtree))))
         (inspiration (string-match-p ":inspiration:" first-line))
         (kw (and (string-match "\\`\\*+[ \t]+\\([^ \t\n]+\\)" first-line)
                  (match-string 1 first-line)))
         (hit (and kw (assoc kw ranks))))
    (cond
     (inspiration inspiration-rank)
     (hit (cdr hit))
     (t unknown-rank))))

(defun org-reorder--rank-subtrees (subtrees ranks unknown inspiration)
  "Return list of (RANK INDEX STRING) triples, one per subtree."
  (let ((i 0) out)
    (dolist (st subtrees)
      (push (list (org-reorder--subtree-rank st ranks unknown inspiration) i st)
            out)
      (setq i (1+ i)))
    (nreverse out)))

(defun org-reorder--locate-cursor (pt start preamble subtrees)
  "Return (INDEX . OFFSET-IN-SUBTREE) for the subtree containing PT, else nil."
  (let ((running (+ start (length preamble)))
        (i 0)
        result)
    (catch 'done
      (dolist (st subtrees)
        (let ((next (+ running (length st))))
          (when (< pt next)
            (setq result (cons i (max 0 (- pt running))))
            (throw 'done nil))
          (setq running next)
          (setq i (1+ i)))))
    result))

(defun org-reorder--restore-cursor (cursor-info start preamble sorted)
  "Move point to the subtree identified by CURSOR-INFO in the SORTED layout."
  (let ((target (car cursor-info))
        (offset (cdr cursor-info))
        (pos (+ start (length preamble))))
    (catch 'done
      (dolist (entry sorted)
        (if (= (nth 1 entry) target)
            (throw 'done nil)
          (setq pos (+ pos (length (nth 2 entry)))))))
    (goto-char (+ pos offset))))

(defun org-reorder ()
  "Sort top-level subtrees in the section containing point.
Section boundaries are lines containing `-----'. Keyword order comes from
the buffer's `#+TODO:' line; `:inspiration:'-tagged entries sort last.
Point follows the subtree it was in; the mutation is a single undo step."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (let ((ranks (org-reorder--todo-keyword-ranks)))
    (unless ranks (user-error "No `#+TODO:' line found"))
    (let* ((unknown (length ranks))
           (inspiration (1+ unknown))
           (bounds (org-reorder--section-bounds))
           (start (car bounds))
           (end (cdr bounds))
           (pair (org-reorder--collect-subtrees start end))
           (preamble (car pair))
           (subtrees (cdr pair)))
      (if (null subtrees)
          (message "org-reorder: no subtrees in section")
        (let* ((cursor-info (org-reorder--locate-cursor
                             (point) start preamble subtrees))
               (ranked (org-reorder--rank-subtrees
                        subtrees ranks unknown inspiration))
               (sorted (sort ranked
                             (lambda (a b)
                               (if (= (nth 0 a) (nth 0 b))
                                   (< (nth 1 a) (nth 1 b))
                                 (< (nth 0 a) (nth 0 b)))))))
          (atomic-change-group
           (delete-region start end)
           (goto-char start)
           (insert preamble)
           (dolist (entry sorted)
             (insert (nth 2 entry))))
          (if cursor-info
              (org-reorder--restore-cursor cursor-info start preamble sorted)
            (goto-char start))
          (when (fboundp 'my/org-refresh-separators-now)
            (my/org-refresh-separators-now)))))))

;; Jira integration via org-jira
(use-package org-jira
  :ensure t
  :defer t
  :init
  (setq jiralib-url "https://datadoghq.atlassian.net")
  :config
  (setq org-jira-working-dir "~/.jira")
  ;; Set jiralib-token directly from ~/.authinfo — jiralib uses request.el
  ;; and passes the token as an Authorization header, not via url.el auth.
  (require 'auth-source)
  (let* ((entry (car (auth-source-search :host "datadoghq.atlassian.net"
                                         :require '(:user :secret))))
         (user  (plist-get entry :user))
         (token (let ((s (plist-get entry :secret)))
                  (if (functionp s) (funcall s) s))))
    (when (and user token)
      (setq jiralib-user user)
      (setq jiralib-token
            `("Authorization" . ,(format "Basic %s"
                                         (base64-encode-string
                                          (concat user ":" token) t))))))
  :bind-keymap ("C-c j" . org-jira-mode-map))

(provide 'org-config)
;;; org-config.el ends here

