;;; gradle-imports --- Gradle imports for Emacs
;;
;; Copyright 2016 Jacob Kiefer
;;
;; Author: Jacob Kiefer <jtk54@cornell.edu>
;; URL: https://github.com/jtk54/gradle-imports
;; Keywords: groovy, gradle, convenience
;; Version: 1.0.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; bitch list
;; TODO: attributions
;; TODO: fix commentary

;; This is the beginning of a fix for shitty groovy/gradle importing in Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'projectile)
(require 'thingatpt)

;; imports table
(setq table (make-hash-table :test 'equal))

;; groovy script to extract classes from jar
(setq script "
import java.util.jar.*

args.inject( [] ) { alist, file ->
  new File( file ).withInputStream { ins ->
    def jis = new JarInputStream( ins )
    while( entry = jis.nextJarEntry ) {
      if( entry.name ==~ /^.+?\.class$/ ) alist << ( entry.name - '.class' ).replaceAll( '/', '.' )
    }
  }
  alist
}.sort().each { println it }
")

;; gradle task to print jar cache
(setq showCache "
task showMeCache << {
  configurations.compile.each { println it }
}
")

(defun gradle-imports-dump ()
  (interactive)
  (message "%S" table))

(defun gradle-imports-insert-import ()
  "Insert import for class under point (if known) at beginning of imports list."
  (interactive)
  (setq class (thing-at-point 'word))
  (if (equal class nil)
      (error "gradle-imports: no class under point")
    (save-excursion
      (setq class (thing-at-point 'word))
      (if (equal (gethash class table) nil)
          (error "gradle-imports: could not find class %s" class))
      (goto-char (point-min))
      (re-search-forward "^package")
      (setq packline (line-number-at-pos))
      (goto-line (+ packline '1))
      (insert "\n")
      (message "gradle-imports: imported class %s" (gethash class table))
      (insert (concat "import " (gethash class table))))
    (gradle-imports-fix-imports)))

(defun gradle-imports-load-imports ()
  "Load Gradle imports into Emacs."
  (interactive)
  (if (not (string-match "gradle" (symbol-name (projectile-project-type))))
      (error "gradle-imports: project is not a gradle project"))
  (if (file-exists-p (concat "/tmp/" (concat (projectile-project-name) ".imports")))
      (gradle-imports-read-table-from-file)
    (gradle-imports-gradle-imports))
  (message "gradle-imports: successfully loaded imports"))

(defun gradle-imports-read-table-from-file ()
  "Read Gradle imports table into Emacs from cache file."
  (with-temp-buffer
    (insert-file-contents (concat "/tmp/" (concat (projectile-project-name) ".imports")))
    (setq table (read (buffer-string)))))

(defun gradle-imports-gradle-imports ()
  "Load Gradle imports table into Emacs using Gradle cache."
  ;; modify build.gradle to include our cache task
  (save-excursion
    (find-file (concat (projectile-project-root) "build.gradle"))
    (goto-char (point-max))
    (insert showCache)
    (save-buffer))
  ;; ask for list of jars from gradle
  (setq jars (with-temp-buffer
               (setq returndir (car (last (split-string (pwd) " "))))
               (cd (projectile-project-root))
               (call-process "gradle" nil t nil "showMeCache")
               (cd returndir)
               (setq lines (split-string (buffer-string) "\n"))
               (setq imports nil)
               (while lines
                 (setq l (car lines))
                 (if (and (string-match "jar" l) (>= (string-match "jar" l) 0))
                     (setq imports (cons l imports)))
                 (setq lines (cdr lines)))
               imports))
  ;; list all classes in said jars, add to hash table
  (with-temp-buffer
    (while jars
      (setq jar (car jars))
      (call-process "groovy" nil t nil "-e" script jar)
      (setq jars (cdr jars)))
    (setq classes (split-string (buffer-string) "\n"))
    (while classes
      (setq class (car classes))
      (puthash (car (last (split-string class "\\."))) class table)
      (setq classes (cdr classes))))
  (save-excursion
    (find-file (concat (projectile-project-root) "build.gradle"))
    (goto-char (point-max))
    (setq lline (line-number-at-pos))
    (goto-line (- lline '4))
    (delete-region (point) (point-max))
    (save-buffer)
    (kill-buffer)))

(defun gradle-imports-save-imports ()
  "Write the imports table from Emacs to file."
  (interactive)
  (with-temp-file (concat "/tmp/" (concat (projectile-project-name) ".imports"))
    (print table (current-buffer))))

(defun gradle-imports-fix-imports ()
  "Sort gradle imports by Google Java coding standards."
  (interactive)
  (setq static nil)
  (setq goog nil)
  (setq stuff nil)
  (setq java nil)
  (setq javax nil)
  (setq lines (split-string (buffer-string) "\n"))
  (while lines
    (setq line (car lines))
    (if (string-match "^import" line)
        (cond
         ((string-match "static" line) (setq static (cons line static)))
         ((string-match "com.google" line) (setq goog (cons line goog)))
         ((string-match "javax" line) (setq javax (cons line javax)))
         ((string-match "java" line) (setq java (cons line java)))
         (t (setq stuff (cons line stuff)))))
    (setq lines (cdr lines)))
  (setq start nil)
  (setq end nil)

  (defun insert-import-group (group)
    (insert (mapconcat 'identity (sort group 'string<) "\n"))
    (insert "\n")
    (insert "\n"))

  (save-excursion
    (goto-char (point-min))
    (re-search-forward "^import")
    (goto-char (line-beginning-position))
    (setq start (point))
    (goto-char (point-max))
    (re-search-backward "^import")
    (goto-char (line-end-position))
    (setq end (point))
    (delete-region start end)
    (goto-char (point-min))
    (re-search-forward "^package")
    (setq packline (line-number-at-pos))
    (goto-line (+ packline '2))
    (if (not (equal static nil))
        (insert-import-group static))
    (if (not (equal goog nil))
        (insert-import-group goog))
    (if (not (equal stuff nil))
        (insert-import-group stuff))
    (if (not (equal java nil))
        (insert-import-group java))
    (if (not (equal javax nil))
        (insert-import-group javax))
    (delete-blank-lines)))

(provide 'gradle-imports)

;;; gradle-imports.el ends here
