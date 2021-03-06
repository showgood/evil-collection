;;; evil-collection-integration.el --- Integrate `evil' with other modules. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; Pierre Neidhardt <ambrevar@gmail.com>
;; URL: https://github.com/jojojames/evil-collection
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: evil, emacs, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;; Integrate `evil' with other modules.
;;; This is an initial copy of evil-integration.el

;; Previous Author/Maintainer:
;; Author: Vegard Øye <vegard_oye at hotmail.com>
;; Maintainer: Vegard Øye <vegard_oye at hotmail.com>

;;; Code:

(require 'evil-maps)
(require 'evil-core)
(require 'evil-macros)
(require 'evil-types)
(require 'evil-repeat)

;;; Code:

;;; Evilize some commands

;; unbound keys should be ignored
(evil-declare-ignore-repeat 'undefined)

(mapc #'(lambda (cmd)
          (evil-set-command-property cmd :keep-visual t)
          (evil-declare-not-repeat cmd))
      '(digit-argument
        negative-argument
        universal-argument
        universal-argument-minus
        universal-argument-more
        universal-argument-other-key))
(mapc #'evil-declare-not-repeat
      '(what-cursor-position))
(mapc #'evil-declare-change-repeat
      '(dabbrev-expand
        hippie-expand
        quoted-insert))
(mapc #'evil-declare-abort-repeat
      '(balance-windows
        eval-expression
        execute-extended-command
        exit-minibuffer
        compile
        delete-window
        delete-other-windows
        find-file-at-point
        ffap-other-window
        recompile
        redo
        save-buffer
        split-window
        split-window-horizontally
        split-window-vertically
        undo
        undo-tree-redo
        undo-tree-undo))

(evil-set-type #'previous-line 'line)
(evil-set-type #'next-line 'line)

(dolist (cmd '(keyboard-quit keyboard-escape-quit))
  (evil-set-command-property cmd :suppress-operator t))

;;; Mouse
(evil-declare-insert-at-point-repeat 'mouse-yank-primary)
(evil-declare-insert-at-point-repeat 'mouse-yank-secondary)

;;; key-binding

;; Calling `keyboard-quit' should cancel repeat
(defadvice keyboard-quit (before evil activate)
  (when (fboundp 'evil-repeat-abort)
    (evil-repeat-abort)))

;;; Buffer-menu

(evil-add-hjkl-bindings Buffer-menu-mode-map 'motion)

;; dictionary.el

(evil-add-hjkl-bindings dictionary-mode-map 'motion
  "?" 'dictionary-help        ; "h"
  "C-o" 'dictionary-previous) ; "l"

;;; Dired

(eval-after-load 'wdired
  '(progn
     (add-hook 'wdired-mode-hook #'evil-change-to-initial-state)
     (defadvice wdired-change-to-dired-mode (after evil activate)
       (evil-change-to-initial-state nil t))))

;;; ELP

(eval-after-load 'elp
  '(defadvice elp-results (after evil activate)
     (evil-motion-state)))

;;; ERT

(evil-add-hjkl-bindings ert-results-mode-map 'motion)

;;; Info

(evil-add-hjkl-bindings Info-mode-map 'motion
  "0" 'evil-digit-argument-or-evil-beginning-of-line
  (kbd "\M-h") 'Info-help   ; "h"
  "\C-t" 'Info-history-back ; "l"
  "\C-o" 'Info-history-back
  " " 'Info-scroll-up
  "\C-]" 'Info-follow-nearest-node
  (kbd "DEL") 'Info-scroll-down)

;;; Speedbar

(evil-add-hjkl-bindings speedbar-key-map 'motion
  "h" 'backward-char
  "j" 'speedbar-next
  "k" 'speedbar-prev
  "l" 'forward-char
  "i" 'speedbar-item-info
  "r" 'speedbar-refresh
  "u" 'speedbar-up-directory
  "o" 'speedbar-toggle-line-expansion
  (kbd "RET") 'speedbar-edit-line)

;;; Undo tree
(when (and (require 'undo-tree nil t)
           (fboundp 'global-undo-tree-mode))
  (global-undo-tree-mode 1))

(eval-after-load 'undo-tree
  '(with-no-warnings
     (defun evil-collection-integration-turn-on-undo-tree-mode ()
       "Enable `undo-tree-mode' if evil is enabled.
This function enables `undo-tree-mode' when Evil is activated in
some buffer, but only if `global-undo-tree-mode' is also
activated."
       (when (and (boundp 'global-undo-tree-mode)
                  global-undo-tree-mode)
         (turn-on-undo-tree-mode)))

     (add-hook 'evil-local-mode-hook #'evil-collection-integration-turn-on-undo-tree-mode)

     (defadvice undo-tree-visualize (after evil activate)
       "Initialize Evil in the visualization buffer."
       (when evil-local-mode
         (evil-initialize-state)))

     (when (fboundp 'undo-tree-visualize)
       (evil-ex-define-cmd "undol[ist]" 'undo-tree-visualize)
       (evil-ex-define-cmd "ul" 'undo-tree-visualize))

     (when (boundp 'undo-tree-visualizer-mode-map)
       (define-key undo-tree-visualizer-mode-map
         [remap evil-backward-char] 'undo-tree-visualize-switch-branch-left)
       (define-key undo-tree-visualizer-mode-map
         [remap evil-forward-char] 'undo-tree-visualize-switch-branch-right)
       (define-key undo-tree-visualizer-mode-map
         [remap evil-next-line] 'undo-tree-visualize-redo)
       (define-key undo-tree-visualizer-mode-map
         [remap evil-previous-line] 'undo-tree-visualize-undo)
       (define-key undo-tree-visualizer-mode-map
         [remap evil-ret] 'undo-tree-visualizer-set))

     (when (boundp 'undo-tree-visualizer-selection-mode-map)
       (define-key undo-tree-visualizer-selection-mode-map
         [remap evil-backward-char] 'undo-tree-visualizer-select-left)
       (define-key undo-tree-visualizer-selection-mode-map
         [remap evil-forward-char] 'undo-tree-visualizer-select-right)
       (define-key undo-tree-visualizer-selection-mode-map
         [remap evil-next-line] 'undo-tree-visualizer-select-next)
       (define-key undo-tree-visualizer-selection-mode-map
         [remap evil-previous-line] 'undo-tree-visualizer-select-previous)
       (define-key undo-tree-visualizer-selection-mode-map
         [remap evil-ret] 'undo-tree-visualizer-set))))

;;; Auto-complete
(eval-after-load 'auto-complete
  '(progn
     (evil-add-command-properties 'auto-complete :repeat 'evil-collection-integration-ac-repeat)
     (evil-add-command-properties 'ac-complete :repeat 'evil-collection-integration-ac-repeat)
     (evil-add-command-properties 'ac-expand :repeat 'evil-collection-integration-ac-repeat)
     (evil-add-command-properties 'ac-next :repeat 'ignore)
     (evil-add-command-properties 'ac-previous :repeat 'ignore)

     (defvar evil-collection-integration-ac-prefix-len nil
       "The length of the prefix of the current item to be completed.")

     (defvar ac-prefix)
     (defun evil-collection-integration-ac-repeat (flag)
       "Record the changes for auto-completion."
       (cond
        ((eq flag 'pre)
         (setq evil-collection-integration-ac-prefix-len (length ac-prefix))
         (evil-repeat-start-record-changes))
        ((eq flag 'post)
         ;; Add change to remove the prefix
         (evil-repeat-record-change (- evil-collection-integration-ac-prefix-len)
                                    ""
                                    evil-collection-integration-ac-prefix-len)
         ;; Add change to insert the full completed text
         (evil-repeat-record-change
          (- evil-collection-integration-ac-prefix-len)
          (buffer-substring-no-properties (- evil-repeat-pos
                                             evil-collection-integration-ac-prefix-len)
                                          (point))
          0)
         ;; Finish repeation
         (evil-repeat-finish-record-changes))))))

;;; Company
(eval-after-load 'company
  '(progn
     (mapc #'evil-declare-change-repeat
           '(company-complete-mouse
             company-complete-number
             company-complete-selection
             company-complete-common))

     (mapc #'evil-declare-ignore-repeat
           '(company-abort
             company-select-next
             company-select-previous
             company-select-next-or-abort
             company-select-previous-or-abort
             company-select-mouse
             company-show-doc-buffer
             company-show-location
             company-search-candidates
             company-filter-candidates))))

;; Eval last sexp
(cond
 ((version< emacs-version "25")
  (defadvice preceding-sexp (around evil activate)
    "In normal-state or motion-state, last sexp ends at point."
    (if (and (not evil-move-beyond-eol)
             (or (evil-normal-state-p) (evil-motion-state-p)))
        (save-excursion
          (unless (or (eobp) (eolp)) (forward-char))
          ad-do-it)
      ad-do-it))

  (defadvice pp-last-sexp (around evil activate)
    "In normal-state or motion-state, last sexp ends at point."
    (if (and (not evil-move-beyond-eol)
             (or (evil-normal-state-p) (evil-motion-state-p)))
        (save-excursion
          (unless (or (eobp) (eolp)) (forward-char))
          ad-do-it)
      ad-do-it)))
 (t
  (defun evil-collection-integration--preceding-sexp (command &rest args)
    "In normal-state or motion-state, last sexp ends at point."
    (if (and (not evil-move-beyond-eol)
             (or (evil-normal-state-p) (evil-motion-state-p)))
        (save-excursion
          (unless (or (eobp) (eolp)) (forward-char))
          (apply command args))
      (apply command args)))

  (advice-add 'elisp--preceding-sexp :around 'evil-collection-integration--preceding-sexp '((name . evil)))
  (advice-add 'pp-last-sexp          :around 'evil-collection-integration--preceding-sexp '((name . evil)))))

;; Show key
(defadvice quail-show-key (around evil activate)
  "Temporarily go to Emacs state"
  (evil-with-state emacs ad-do-it))

(defadvice describe-char (around evil activate)
  "Temporarily go to Emacs state"
  (evil-with-state emacs ad-do-it))

;; ace-jump-mode
(declare-function 'ace-jump-char-mode "ace-jump-mode")
(declare-function 'ace-jump-word-mode "ace-jump-mode")
(declare-function 'ace-jump-line-mode "ace-jump-mode")

(defvar evil-collection-integration-ace-jump-active nil)

(defmacro evil-collection-integration-enclose-ace-jump-for-motion (&rest body)
  "Enclose ace-jump to make it suitable for motions.
This includes restricting `ace-jump-mode' to the current window
in visual and operator state, deactivating visual updates, saving
the mark and entering `recursive-edit'."
  (declare (indent defun)
           (debug t))
  `(let ((old-mark (mark))
         (ace-jump-mode-scope
          (if (and (not (memq evil-state '(visual operator)))
                   (boundp 'ace-jump-mode-scope))
              ace-jump-mode-scope
            'window)))
     (ignore ace-jump-mode-scope) ;; Make byte compiler happy.
     (remove-hook 'pre-command-hook #'evil-visual-pre-command t)
     (remove-hook 'post-command-hook #'evil-visual-post-command t)
     (unwind-protect
         (let ((evil-collection-integration-ace-jump-active 'prepare))
           (add-hook 'ace-jump-mode-end-hook
                     #'evil-collection-integration-ace-jump-exit-recursive-edit)
           ,@body
           (when evil-collection-integration-ace-jump-active
             (setq evil-collection-integration-ace-jump-active t)
             (recursive-edit)))
       (remove-hook 'post-command-hook
                    #'evil-collection-integration-ace-jump-exit-recursive-edit)
       (remove-hook 'ace-jump-mode-end-hook
                    #'evil-collection-integration-ace-jump-exit-recursive-edit)
       (if (evil-visual-state-p)
           (progn
             (add-hook 'pre-command-hook #'evil-visual-pre-command nil t)
             (add-hook 'post-command-hook #'evil-visual-post-command nil t)
             (set-mark old-mark))
         (push-mark old-mark)))))

(eval-after-load 'ace-jump-mode
  `(defadvice ace-jump-done (after evil activate)
     (when evil-collection-integration-ace-jump-active
       (add-hook 'post-command-hook #'evil-collection-integration-ace-jump-exit-recursive-edit))))

(defun evil-collection-integration-ace-jump-exit-recursive-edit ()
  "Exit a recursive edit caused by an evil jump."
  (cond
   ((eq evil-collection-integration-ace-jump-active 'prepare)
    (setq evil-collection-integration-ace-jump-active nil))
   (evil-collection-integration-ace-jump-active
    (remove-hook 'post-command-hook #'evil-collection-integration-ace-jump-exit-recursive-edit)
    (exit-recursive-edit))))

(evil-define-motion evil-ace-jump-char-mode (_)
  "Jump visually directly to a char using ace-jump."
  :type inclusive
  (evil-without-repeat
    (let ((pnt (point))
          (buf (current-buffer)))
      (evil-collection-integration-enclose-ace-jump-for-motion
        (call-interactively 'ace-jump-char-mode))
      ;; if we jump backwards, motion type is exclusive, analogously
      ;; to `evil-find-char-backward'
      (when (and (equal buf (current-buffer))
                 (< (point) pnt))
        (setq evil-this-type
              (cond
               ((eq evil-this-type 'exclusive) 'inclusive)
               ((eq evil-this-type 'inclusive) 'exclusive)))))))

(evil-define-motion evil-ace-jump-char-to-mode (_)
  "Jump visually to the char in front of a char using ace-jump."
  :type inclusive
  (evil-without-repeat
    (let ((pnt (point))
          (buf (current-buffer)))
      (evil-collection-integration-enclose-ace-jump-for-motion
        (call-interactively 'ace-jump-char-mode))
      (if (and (equal buf (current-buffer))
               (< (point) pnt))
          (progn
            (or (eobp) (forward-char))
            (setq evil-this-type
                  (cond
                   ((eq evil-this-type 'exclusive) 'inclusive)
                   ((eq evil-this-type 'inclusive) 'exclusive))))
        (backward-char)))))

(evil-define-motion evil-ace-jump-line-mode (_)
  "Jump visually to the beginning of a line using ace-jump."
  :type line
  :repeat abort
  (evil-without-repeat
    (evil-collection-integration-enclose-ace-jump-for-motion
      (call-interactively 'ace-jump-line-mode))))

(evil-define-motion evil-ace-jump-word-mode (_)
  "Jump visually to the beginning of a word using ace-jump."
  :type exclusive
  :repeat abort
  (evil-without-repeat
    (evil-collection-integration-enclose-ace-jump-for-motion
      (call-interactively 'ace-jump-word-mode))))

(define-key evil-motion-state-map [remap ace-jump-char-mode] #'evil-ace-jump-char-mode)
(define-key evil-motion-state-map [remap ace-jump-line-mode] #'evil-ace-jump-line-mode)
(define-key evil-motion-state-map [remap ace-jump-word-mode] #'evil-ace-jump-word-mode)

;;; avy
(declare-function 'avy-goto-word-or-subword-1 "avy")
(declare-function 'avy-goto-line "avy")
(declare-function 'avy-goto-char "avy")
(declare-function 'avy-goto-char-2 "avy")
(declare-function 'avy-goto-char-2-above "avy")
(declare-function 'avy-goto-char-2-below "avy")
(declare-function 'avy-goto-char-in-line "avy")
(declare-function 'avy-goto-word-0 "avy")
(declare-function 'avy-goto-word-1 "avy")
(declare-function 'avy-goto-word-1-above "avy")
(declare-function 'avy-goto-word-1-below "avy")
(declare-function 'avy-goto-subword-0 "avy")
(declare-function 'avy-goto-subword-1 "avy")
(declare-function 'avy-goto-char-timer "avy")

(defmacro evil-collection-integration-enclose-avy-for-motion (&rest body)
  "Enclose avy to make it suitable for motions.
Based on `evil-collection-integration-enclose-ace-jump-for-motion'."
  (declare (indent defun)
           (debug t))
  `(let ((avy-all-windows
          (if (and (not (memq evil-state '(visual operator)))
                   (boundp 'avy-all-windows))
              avy-all-windows
            nil)))
     (ignore avy-all-windows) ;; Make byte compiler happy.
     ,@body))

(defmacro evil-collection-integration-define-avy-motion (command type)
  (declare (indent defun)
           (debug t))
  (let ((name (intern (format "evil-%s" command))))
    `(evil-define-motion ,name (_count)
       ,(format "Evil motion for `%s'." command)
       :type ,type
       :jump t
       :repeat abort
       (evil-without-repeat
         (evil-collection-integration-enclose-avy-for-motion
           (call-interactively ',command))))))

;; define evil-avy-* motion commands for avy-* commands
(evil-collection-integration-define-avy-motion avy-goto-char inclusive)
(evil-collection-integration-define-avy-motion avy-goto-char-2 inclusive)
(evil-collection-integration-define-avy-motion avy-goto-char-2-above inclusive)
(evil-collection-integration-define-avy-motion avy-goto-char-2-below inclusive)
(evil-collection-integration-define-avy-motion avy-goto-char-in-line inclusive)
(evil-collection-integration-define-avy-motion avy-goto-char-timer inclusive)
(evil-collection-integration-define-avy-motion avy-goto-line line)
(evil-collection-integration-define-avy-motion avy-goto-line-above line)
(evil-collection-integration-define-avy-motion avy-goto-line-below line)
(evil-collection-integration-define-avy-motion avy-goto-subword-0 exclusive)
(evil-collection-integration-define-avy-motion avy-goto-subword-1 exclusive)
(evil-collection-integration-define-avy-motion avy-goto-symbol-1 exclusive)
(evil-collection-integration-define-avy-motion avy-goto-symbol-1-above exclusive)
(evil-collection-integration-define-avy-motion avy-goto-symbol-1-below exclusive)
(evil-collection-integration-define-avy-motion avy-goto-word-0 exclusive)
(evil-collection-integration-define-avy-motion avy-goto-word-1 exclusive)
(evil-collection-integration-define-avy-motion avy-goto-word-1-above exclusive)
(evil-collection-integration-define-avy-motion avy-goto-word-1-below exclusive)
(evil-collection-integration-define-avy-motion avy-goto-word-or-subword-1 exclusive)

;; remap avy-* commands to evil-avy-* commands
(dolist (command '(avy-goto-char
                   avy-goto-char-2
                   avy-goto-char-2-above
                   avy-goto-char-2-below
                   avy-goto-char-in-line
                   avy-goto-char-timer
                   avy-goto-line
                   avy-goto-line-above
                   avy-goto-line-below
                   avy-goto-subword-0
                   avy-goto-subword-1
                   avy-goto-symbol-1
                   avy-goto-symbol-1-above
                   avy-goto-symbol-1-below
                   avy-goto-word-0
                   avy-goto-word-1
                   avy-goto-word-1-above
                   avy-goto-word-1-below
                   avy-goto-word-or-subword-1))
  (define-key evil-motion-state-map
    (vector 'remap command) (intern-soft (format "evil-%s" command))))

;;; nXhtml/mumamo
;; ensure that mumamo does not toggle evil through its globalized mode
(eval-after-load 'mumamo
  '(with-no-warnings
     (push 'evil-mode-cmhh mumamo-change-major-mode-no-nos)))

;; visual-line-mode integration
(when evil-respect-visual-line-mode
  (let ((swaps '((evil-next-line . evil-next-visual-line)
                 (evil-previous-line . evil-previous-visual-line)
                 (evil-beginning-of-line . evil-beginning-of-visual-line)
                 (evil-end-of-line . evil-end-of-visual-line))))
    (dolist (swap swaps)
      (define-key visual-line-mode-map (vector 'remap (car swap)) (cdr swap))
      (define-key visual-line-mode-map (vector 'remap (cdr swap)) (car swap)))))

;;; abbrev.el
(when evil-want-abbrev-expand-on-insert-exit
  (eval-after-load 'abbrev
    '(add-hook 'evil-insert-state-exit-hook 'expand-abbrev)))


(provide 'evil-collection-integration)
;;; evil-collection-integration.el ends here
