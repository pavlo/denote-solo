;;; denote-solo.el --- Switch active Denote directory -*- lexical-binding: t -*-

;; Author: Pavlo V. Lysov
;; Version: 1.0.1
;; Package-Requires: ((emacs "28.1") (denote "4.0"))
;; Keywords: convenience, notes
;; URL: https://github.com/pavlo/denote-solo

;;; Commentary:

;; Provides workspace-like switching between Denote directories (silos).
;; Unlike denote-silo, maintains a single active context rather than
;; prompting per command.

;;; Code:
(require 'denote)

(defvar denote-solo--last-directory-file (locate-user-emacs-file "denote-solo-last-directory"))
(defvar denote-solo--current-solo nil)
(defvar denote-solo--keyword-history nil)
(defvar denote-solo--mode-line-construct '(:eval (denote-solo--modeline-indicator))
  "TODO: document this one")

(defgroup denote-solo nil
  "Switch active Denote directory. A Silo alernative."
  :group 'denote
  :prefix "denote-solo-")

(defcustom denote-solo-directories nil
  "List of Denote name/directory pairs to switch between."
  :type '(alist :key-type string :value-type string)
  :group 'denote-solo)

(defcustom denote-solo-modeline-indicator-p t
  "Whether to display the current Silo in the modeline."
  :type 'boolean
  :group 'denote-solo)

(defun denote-solo-switch (&optional name)
  "Switch denote directory to NAME.
оWhen called interactively, prompt for selection.
Saves the choice for future sessions."
  (interactive
   (let ((items (mapcar (lambda (arg) (car arg)) denote-solo-directories)))
     (list (completing-read "Denote Solo directory: " items nil t))))
  (let ((path (denote-solo--directory-for-name name)))
    (unless path
      (error "Failed to find directory for Silo with %s name" name))
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
    (setq denote-solo--current-solo name)))

(defun denote-solo--restore-last-solo ()
  "Restore the last used denote solo directory."

  (message "Restoring Denote Solo...")
  (when (file-exists-p denote-solo--last-directory-file)
    (let* ((name (with-temp-buffer
                   (insert-file-contents denote-solo--last-directory-file)
                   (string-trim (buffer-string))))
	   (path (denote-solo--directory-for-name name)))
      (if (file-directory-p path)
	  (denote-solo-switch name)))))

;; List denote "silo" on modeline
(defun denote-solo--modeline-indicator ()
  (when (and (bound-and-true-p denote-directory)
             denote-solo--current-solo
             denote-solo-modeline-indicator-p)
    (concat "{denote: " denote-solo--current-solo "}")))

(defun denote-solo--directory-for-name (name)
  "Find directory path for given solo name."
  (let ((result (seq-find (lambda (arg) (string= name (car arg))) denote-solo-directories)))
    (when result (cdr result))))

;;;###autoload
(define-minor-mode denote-solo-mode
  "TODO: documentation - displays active solo dir + restores the last used solo."

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

