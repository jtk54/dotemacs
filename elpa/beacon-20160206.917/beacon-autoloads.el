;;; beacon-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (beacon-mode beacon-blink) "beacon" "beacon.el"
;;;;;;  (22239 19367 897327 976000))
;;; Generated autoloads from beacon.el

(autoload 'beacon-blink "beacon" "\
Blink the beacon at the position of the cursor.
Unlike `beacon-blink-automated', the beacon will blink
unconditionally (even if `beacon-mode' is disabled), and this can
be invoked as a user command or called from lisp code.

\(fn)" t nil)

(defvar beacon-mode nil "\
Non-nil if Beacon mode is enabled.
See the command `beacon-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `beacon-mode'.")

(custom-autoload 'beacon-mode "beacon" nil)

(autoload 'beacon-mode "beacon" "\
Toggle Beacon mode on or off.
With a prefix argument ARG, enable Beacon mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is `toggle'.
\\{beacon-mode-map}

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("beacon-pkg.el") (22239 19367 908004 692000))

;;;***

(provide 'beacon-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; beacon-autoloads.el ends here
