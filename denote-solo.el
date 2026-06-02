;;; denote-solo.el --- Switch the active Denote directory -*- lexical-binding: t -*-

;; Copyright (C) 2026 Pavlo V. Lysov

;; Author: Pavlo V. Lysov
;; Assisted-by: Claude:claude-sonnet-4-6
;; Maintainer: Pavlo V. Lysov
;; Version: 1.0.1
;; Package-Requires: ((emacs "28.1") (denote "4.0"))
;; Keywords: convenience, notes
;; URL: https://github.com/pavlo/denote-solo
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; denote-solo provides workspace-like switching between Denote
;; directories.  Denote calls such directories "silos"; denote-solo
;; keeps exactly one of them active at a time and calls it a "solo".
;; Unlike denote-silo, which prompts you to pick a directory on every
;; command, you switch once with `denote-solo-switch', and every
;; subsequent Denote command operates in that solo until you switch
;; again.
;;
;; The active solo is remembered across sessions and is shown in the
;; mode line.  Enable the package with the global minor mode:
;;
;;     (denote-solo-mode 1)
;;
;; See the README for a fuller walkthrough.

;;; Code:
(require 'denote)

(defvar denote-solo--last-directory-file
  (locate-user-emacs-file "denote-solo-last-directory")
  "File that stores the name of the last active solo across sessions.")

(defvar denote-solo--current-solo nil
  "Name of the currently active solo, or nil if none is selected.")

(defvar denote-solo--previous-solo nil
  "Name of the previously active solo, or nil if none was yet selected.
It is set as the default value for `completing-read` so that it is
possible to toggle between two solos effortlessly")

(defvar denote-solo--keyword-history nil
  "Alist mapping each solo name to its saved `denote-keyword-history'.
Used to keep keyword history separate per solo when switching.")

(defvar denote-solo--mode-line-construct
  '(:eval (denote-solo--modeline-indicator))
  "Mode line construct that displays the active solo.
Added to and removed from `mode-line-misc-info' by `denote-solo-mode'.")

(defgroup denote-solo nil
  "Switch the active Denote directory.  Keep one solo active at a time."
  :group 'denote
  :prefix "denote-solo-")

(defcustom denote-solo-directories nil
  "Alist of solos to switch between.
Each element is a cons cell (NAME . DIRECTORY), where NAME is a
string shown in the completion prompt and DIRECTORY is the path
that becomes `denote-directory' when that solo is selected."
  :type '(alist :key-type string :value-type string)
  :group 'denote-solo)

(defcustom denote-solo-display-modeline t
  "Whether to display the active solo in the mode line."
  :type 'boolean
  :group 'denote-solo)

;;;###autoload
(defun denote-solo-switch (&optional name)
  "Switch the active Denote solo to NAME.
NAME must be a key of `denote-solo-directories'.  When called
interactively, prompt for it with completion.

Set `denote-directory' to the matching path, preserve and restore
`denote-keyword-history' per solo, and remember the choice so it
can be restored in future sessions."
  (interactive
   (let ((items (mapcar (lambda (arg) (car arg)) denote-solo-directories)))
     (list (completing-read "Denote Solo: " items nil t nil nil denote-solo--previous-solo))))
  (let ((path (denote-solo--directory-for-name name)))
    (unless path
      (error "No directory configured for solo %S" name))
    (unless (equal name denote-solo--current-solo)
      ;; store keyword history for the path we're leaving
      (when denote-solo--current-solo
        (push (cons denote-solo--current-solo denote-keyword-history)
              denote-solo--keyword-history))
      (setq denote-directory path)
      ;; restore history from the one we're going into
      (setq denote-keyword-history
            (alist-get name denote-solo--keyword-history nil nil #'string=))
      (with-temp-file denote-solo--last-directory-file
        (insert name))
      (setq denote-solo--previous-solo denote-solo--current-solo)
      (setq denote-solo--current-solo name)
      (message "Denote Solo: %s (%s)" name path))))

(defun denote-solo--restore-last-solo ()
  "Restore the solo saved in `denote-solo--last-directory-file'.
Do nothing if no solo was saved or its directory no longer exists."
  (when (file-exists-p denote-solo--last-directory-file)
    (let* ((name (with-temp-buffer
                   (insert-file-contents denote-solo--last-directory-file)
                   (string-trim (buffer-string))))
	   (path (denote-solo--directory-for-name name)))
      (when (and path (file-directory-p path))
	(denote-solo-switch name)))))

(defun denote-solo--modeline-indicator ()
  "Return the mode line string for the active solo, or nil.
Return nil when no solo is active or `denote-solo-display-modeline'
is disabled."
  (when (and (bound-and-true-p denote-directory)
             denote-solo--current-solo
             denote-solo-display-modeline)
    (concat "{denote: " denote-solo--current-solo "}")))

(defun denote-solo--directory-for-name (name)
  "Return the directory associated with solo NAME, or nil if unknown."
  (let ((result (seq-find (lambda (arg) (string= name (car arg)))
                          denote-solo-directories)))
    (when result (expand-file-name (cdr result)))))

;;;###autoload
(define-minor-mode denote-solo-mode
  "Toggle Denote Solo mode.
This is a global minor mode.  When enabled, restore the last
active solo and show the active solo in the mode line.  When
disabled, remove the mode line indicator."
  :global t
  :group 'denote-solo
  :lighter nil
  (if denote-solo-mode
      (progn
        (add-to-list 'mode-line-misc-info denote-solo--mode-line-construct)
        (denote-solo--restore-last-solo))
    (setq mode-line-misc-info
          (delete denote-solo--mode-line-construct mode-line-misc-info))))


(provide 'denote-solo)
;;; denote-solo.el ends here

