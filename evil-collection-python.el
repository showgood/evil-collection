;;; evil-collection-python.el --- Bindings for `python'. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; Pierre Neidhardt <ambrevar@gmail.com>
;; URL: https://github.com/jojojames/evil-collection
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: emacs, tools

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
;;; Bindings for `python'.

;;; Code:
(require 'evil)
(require 'python)

(defun evil-collection-python-set-evil-shift-width ()
  "Set `evil-shift-width' according to `python-indent-offset'."
  (setq evil-shift-width python-indent-offset))

(defun evil-collection-python-setup ()
  "Set up `evil' bindings for `python'."
  (add-hook 'python-mode-hook #'evil-collection-python-set-evil-shift-width)

  (evil-define-key 'normal python-mode-map
    "gz" 'python-shell-switch-to-shell))

(provide 'evil-collection-python)
;;; evil-collection-python.el ends here
