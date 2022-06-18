;;; core/cli/sync.el --- synchronize config command -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(load! "packages")


;;
;;; Variables

(defvar doom-after-sync-hook ()
  "Hooks run after 'doom sync' synchronizes the user's config with Doom.")

(defvar doom-before-sync-hook ()
  "Hooks run before 'doom sync' synchronizes the user's config with Doom.")


;;
;;; Commands

(defalias! (:before (sync s)) (:before build))

(defcli! ((sync s))
    ((noenvvar? ("-e") "Don't regenerate the envvar file")
     (noelc?    ("-c") "Don't recompile config")
     (update?   ("-u") "Update installed packages after syncing")
     (purge?    ("-p") "Purge orphaned package repos & regraft them"))
  "Synchronize your config with Doom Emacs.

This is the equivalent of running autoremove, install, autoloads, then
recompile. Run this whenever you:

  1. Modify your `doom!' block,
  2. Add or remove `package!' blocks to your config,
  3. Add or remove autoloaded functions in module autoloaded files.
  4. Update Doom outside of Doom (e.g. with git)

It will ensure that unneeded packages are removed, all needed packages are
installed, autoloads files are up-to-date and no byte-compiled files have gone
stale."
  :benchmark t
  (run-hooks 'doom-before-sync-hook)
  (add-hook 'kill-emacs-hook #'doom-sync--abort-warning-h)
  (print! (start "Synchronizing your config with Doom Emacs..."))
  (unwind-protect
      (print-group!
       (when (and (not noenvvar?)
                  (file-exists-p doom-env-file))
         (call! '("env")))
       (doom-packages-install)
       (doom-packages-build)
       (when update?
         (doom-packages-update))
       (doom-packages-purge purge? 'builds-p purge? purge? purge?)
       (run-hooks 'doom-after-sync-hook)
       (when (doom-autoloads-reload)
         (print! (item "Restart Emacs or use 'M-x doom/reload' for changes to take effect")))
       t)
    (remove-hook 'kill-emacs-hook #'doom-sync--abort-warning-h)))

;; DEPRECATED Remove when v3.0 is released
(defobsolete! ((refresh re)) "doom sync" "v3.0.0")


;;
;;; Helpers

(defun doom-sync--abort-warning-h ()
  (print! (warn "Script was abruptly aborted, leaving Doom in an incomplete state!"))
  (print! (item "Run 'doom sync' to repair it.")))

(provide 'core-cli-sync)
;;; sync.el ends here
