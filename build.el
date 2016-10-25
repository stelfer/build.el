
(require 'projectile)
(require 'compile)

(defvar build-target-use-current-buffer-as-hint nil)
(defvar build-tool "make -w")
(defvar build-tool-parallel-flag "-j")
(defvar build-tool-root-flag "-C")
(defvar build-tool-list-targets-flag "-np")
(defvar build-tool-list-targets (concat build-tool " " build-tool-list-targets-flag))

(defun build-project ()
  (interactive)
  (let* ((args (cond
	       ((projectile-project-p) (concat build-tool-root-flag " " (projectile-project-root)))
	       (t "")))
	 (command (concat build-tool " " build-tool-parallel-flag args)))
    (compile command)))

(defun build-target-from-current ()
  (interactive)
  (let ((hint build-target-use-current-buffer-as-hint))
    (setq build-target-use-current-buffer-as-hint t)
    (call-interactively 'build-target)
    (setq build-target-use-current-buffer-as-hint hint)))

(defun build-target-dir-args ()
  (concat build-tool-parallel-flag " " build-tool-root-flag " " (or build-root (projectile-project-root))))

(defun build-get-target ()
  (let ((target-exclude-regexp "\\(^\\.\\)\\|[\\$\\%]")
	(initial (if build-target-use-current-buffer-as-hint
		     (file-name-sans-extension (buffer-name)) nil)))
    (save-window-excursion
      (with-output-to-temp-buffer "*build-targets*"
	(let* ((build-dir-args (build-target-dir-args))
	       (command (concat build-tool-list-targets build-dir-args)))
	  (shell-command command "*build-targets*")
	  (pop-to-buffer "*build-targets*")
	  (goto-char (point-max))
	  (let ((targets nil))
	    (while (re-search-backward "^\\(build/[^:\n#[:space:]]+?\\):"
				       (not 'bound) 'noerror)
	      (unless (string-match target-exclude-regexp
				    (match-string 1))
		(setq targets (cons (match-string 1) targets))))
	    (delete-windows-on "*build-targets*")
	    ;; (setq target (completing-read "target: " targets nil nil initial)))))))
	    (completing-read "target: " targets nil nil initial)))))))

(defun build-target (&optional target)
  (interactive (list (build-get-target)))
  (save-window-excursion
    (message "%s" target)
    (let ((command (concat build-tool " " (build-target-dir-args) " " target)))
      (compile command))))

(defun build ()
  (interactive)
  (save-window-excursion
    (let ((command (completing-read "Compile: " compile-history nil nil nil)))
      (compile command))))

(defvar build-compilation-progress-reporter nil)

(defun build-compilation-start-hook (process)
  (let ((delete-duplicates-save history-delete-duplicates))
    (setq build-compilation-progress-reporter (make-progress-reporter "Compiling..." 0 100))
    (setq history-delete-duplicates t)
    (add-to-history 'compile-history command)
    (setq history-delete-duplicates delete-duplicates-save)))


(defun build-compilation-finish-handle-error ()
  (delete-other-windows)
  (switch-to-buffer "*compilation*")
  (first-error))

(defun build-compilation-finish (buffer string)
  (progn
    (progress-reporter-done build-compilation-progress-reporter)
    (if (and
	 (string-match "compilation" (buffer-name buffer))
	 (string-match "finished" string)
	 (not
	  (with-current-buffer buffer
	    (goto-char 1)
	    (search-forward "warning" nil t))))
	(message (propertize "Compilation successful" 'face 'success))
      (build-compilation-finish-handle-error))))

(with-eval-after-load "compile"
  (add-hook 'compilation-finish-functions 'build-compilation-finish)
  (add-hook 'compilation-start-hook 'build-compilation-start-hook)
  (setq compilation-scroll-output 'first-error))

(provide 'build)
