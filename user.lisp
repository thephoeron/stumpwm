;; Copyright (C) 2003 Shawn Betts
;;
;;  This file is part of stumpwm.
;;
;; stumpwm is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
 
;; stumpwm is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
 
;; You should have received a copy of the GNU General Public License
;; along with this software; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
;; Boston, MA 02111-1307 USA

;; Commentary:
;;
;; Window Manager commands that users can use to manipulate stumpwm
;; and write custos.
;;
;; Code:

(in-package :stumpwm)

(defvar *root-map* nil
  "The default bindings that hang off the prefix key.")

;; Do it this way so its easier to wipe the map and get a clean one.
(when (null *root-map*)
  (setf *root-map*
	(let ((m (make-sparse-keymap)))
	  (define-key m (kbd "c") "exec xterm")
	  (define-key m (kbd "C-c") "exec xterm")
	  (define-key m (kbd "e") "exec emacs")
	  (define-key m (kbd "C-e") "exec emacs")
	  (define-key m (kbd "n") "next")
	  (define-key m (kbd "C-n") "next")
	  (define-key m (kbd "SPC") "next")
	  (define-key m (kbd "p") "prev")
	  (define-key m (kbd "C-p") "prev")
	  (define-key m (kbd "w") "windows")
	  (define-key m (kbd "C-w") "windows")
	  (define-key m (kbd "k") "delete")
	  (define-key m (kbd "C-k") "delete")
	  (define-key m (kbd "K") "kill")
	  (define-key m (kbd "b") "banish")
	  (define-key m (kbd "C-b") "banish")
	  (define-key m (kbd "a") "time")
	  (define-key m (kbd "C-a") "time")
	  (define-key m (kbd "'") "select")
	  (define-key m (kbd "C-t") "other")
	  (define-key m (kbd "!") "exec")
	  (define-key m (kbd "C-g") "abort")
	  (define-key m (kbd "0") "pull 0")
	  (define-key m (kbd "1") "pull 1")
	  (define-key m (kbd "2") "pull 2")
	  (define-key m (kbd "3") "pull 3")
	  (define-key m (kbd "4") "pull 4")
	  (define-key m (kbd "5") "pull 5")
	  (define-key m (kbd "6") "pull 6")
	  (define-key m (kbd "7") "pull 7")
	  (define-key m (kbd "8") "pull 8")
	  (define-key m (kbd "9") "pull 9")
	  (define-key m (kbd "r") "remove")
	  (define-key m (kbd "s") "vsplit")
	  (define-key m (kbd "S") "hsplit")
	  (define-key m (kbd "o") "fnext")
	  (define-key m (kbd "TAB") "sibling")
	  (define-key m (kbd "f") "fselect")
	  (define-key m (kbd "F") "curframe")
	  (define-key m (kbd "t") "meta C-t")
	  (define-key m (kbd "C-N") "number")
	  (define-key m (kbd ";") "colon")
	  (define-key m (kbd ":") "eval")
	  (define-key m (kbd "C-h") "help")
	  (define-key m (kbd "-") "fclear")
	  (define-key m (kbd "Q") "only")
	  (define-key m (kbd "Up") "move-focus up")
	  (define-key m (kbd "Down") "move-focus down")
	  (define-key m (kbd "Left") "move-focus left")
	  (define-key m (kbd "Right") "move-focus right")
	  (define-key m (kbd "v") "version")
	  m)))

(defstruct command
  name args fn)

(defvar *command-hash* (make-hash-table :test 'equal)
  "A list of interactive stumpwm commands.")

(defmacro define-stumpwm-command (name (screen &rest args) &body body)
  `(setf (gethash ,name *command-hash*)
	 (make-command :name ,name
		       :args ',args
		       :fn (lambda (,screen ,@(mapcar 'first args))
			      ,@body))))

(defun focus-next-window (screen)
  (focus-forward screen (frame-sort-windows screen
					    (screen-current-frame screen))))

(defun focus-prev-window (screen)
  (focus-forward screen
		 (reverse
		  (frame-sort-windows screen
				      (screen-current-frame screen)))))

(define-stumpwm-command "next" (screen)
  (focus-next-window screen))

(define-stumpwm-command "prev" (screen)
  (focus-prev-window screen))

;; In the future, this window will raise the window into the current
;; frame.
(defun focus-forward (screen window-list)
 "Set the focus to the next item in window-list from the focused window."
  ;; The window with focus is the "current" window, so find it in the
  ;; list and give that window focus
  (let* ((w (xlib:input-focus *display*))
	 (wins (member w window-list))
	 nw)
    ;;(assert wins)
    (setf nw (if (null (cdr wins))
		 ;; If the last window in the list is focused, then
		 ;; focus the first one.
		 (car window-list)
	       ;; Otherwise, focus the next one in the list.
	       (cadr wins)))
    (when nw
      (frame-raise-window screen (window-frame nw) nw))))

(defun delete-current-window (screen)
  "Send a delete event to the current window."
  (when (screen-current-window screen)
    (delete-window (screen-current-window screen))))

(define-stumpwm-command "delete" (screen)
  (delete-current-window screen))

(defun kill-current-window (screen)
  "Kill the client of the current window."
  (when (screen-current-window screen)
    (kill-window (screen-current-window screen))))

(define-stumpwm-command "kill" (screen)
  (kill-current-window screen))

(defun banish-pointer (screen)
  "Move the pointer to the lower right corner of the screen"
  (warp-pointer screen
		(1- (screen-width screen))
		(1- (screen-height screen))))

(define-stumpwm-command "banish" (screen)
  (banish-pointer screen))

(define-stumpwm-command "ratwarp" (screen (x :number "X: ") (y :number "Y: "))
  (warp-pointer screen x y))

(define-stumpwm-command "ratrelwarp" (screen (dx :number "Delta X: ") (dy :number "Delta Y: "))
  (declare (ignore screen))
  (warp-pointer-relative dx dy))

(defun echo-windows (screen fmt)
  "Print a list of the windows to the screen."
  (let* ((wins (sort-windows screen))
	 (highlight (position (screen-current-window screen) wins :test #'xlib:window-equal))
	 (names (mapcar (lambda (w)
			  (format-expand *window-formatters* fmt w)) wins)))
    (if (null wins)
	(echo-string screen "No Managed Windows")
      (echo-string-list screen names highlight))))

(defun fmt-screen-window-list (screen)
  "Using *window-format*, return a 1 line list of the windows, space seperated."
  (format nil "~{~a~^ ~}" 
	  (mapcar (lambda (w)
		    (format-expand *window-formatters* *window-format* w)) (sort-windows screen))))

(define-stumpwm-command "windows" (screen)
  (echo-windows screen *window-format*))

(defun echo-date (screen)
  "Print the output of the 'date' command to the screen."
  (let* ((month-names
	  #("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
	 (day-names
	  #("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"))
	 (date-string (multiple-value-bind (sec min hour dom mon year dow)
			 (get-decoded-time)
		       (format nil "~A ~A ~A ~A:~2,,,'0@A:~2,,,'0@A ~A"
			       (aref day-names dow)
			       (aref month-names (- mon 1))
			       dom hour min sec year))))
    (echo-string screen date-string)))

(define-stumpwm-command "time" (screen)
  (echo-date screen))

(defun select-window (screen query)
  "Read input from the user and go to the selected window."
    (let (match)
      (labels ((match (win)
		      (let* ((wname (window-name win))
			     (end (min (length wname) (length query))))
			(string-equal wname query :end1 end :end2 end))))
	(unless (null query)
	  (setf match (find-if #'match (screen-mapped-windows screen))))
	(when match
	  (frame-raise-window screen (window-frame match) match)))))

(define-stumpwm-command "select" (screen (win :string "Select: "))
  (select-window screen win))

(defun select-window-number (screen num)
  (labels ((match (win)
		  (= (window-number win) num)))
    (let ((win (find-if #'match (screen-mapped-windows screen))))
      (when win
	(frame-raise-window screen (window-frame win) win)))))

(defun other-window (screen)
  (let* ((f (screen-current-frame screen))
	 (wins (frame-windows screen f))
	 ;; the frame could be empty
	 (win (if (frame-window f)
		  (second wins)
		  (first wins))))
  (if win
      (frame-raise-window screen (window-frame win) win)
      (echo-string screen "No other window."))))

(define-stumpwm-command "other" (screen)
  (other-window screen))

(defun run-shell-command (cmd &optional collect-output-p)
  "Run a shell command in the background or wait for it to finish
and collect the output if COLLECT-OUTPUT-P is T. Warning! if
COLLECT-OUTPUT-P is stumpwm will hang until your command
returns..which could be forever if you're not careful."
  (if collect-output-p
      (run-prog-collect-output *shell-program* "-c" cmd)
      (run-prog *shell-program* :args (list "-c" cmd) :wait nil)))

(define-stumpwm-command "exec" (screen (cmd :rest "/bin/sh -c "))
  (declare (ignore screen))
  (run-shell-command cmd))

(defun horiz-split-frame (screen)
  (split-frame screen (lambda (f) (split-frame-h screen f)))
  (let ((f (screen-current-frame screen)))
    (when (frame-window f)
      (update-window-border screen (frame-window f))))
  (show-frame-indicator screen))

(define-stumpwm-command "hsplit" (screen)
  (horiz-split-frame screen))

(defun vert-split-frame (screen)
  (split-frame screen (lambda (f) (split-frame-v screen f)))
  (let ((f (screen-current-frame screen)))
    (when (frame-window f)
      (update-window-border screen (frame-window f))))
  (show-frame-indicator screen))

(define-stumpwm-command "vsplit" (screen)
  (vert-split-frame screen))

(defun remove-split (screen)
  (let* ((s (sibling (screen-frame-tree screen)
		    (screen-current-frame screen)))
	 ;; grab a leaf of the sibling. The sibling doesn't have to be
	 ;; a frame.
	 (l (tree-accum-fn s
                           (lambda (x y)
                             (declare (ignore y))
                             x)
                           #'identity)))
    ;; Only remove the current frame if it has a sibling
    (dformat "~S~%" s)
    (when s
      (dformat "~S~%" l)
      ;; Move the windows from the removed frame to its sibling
      (migrate-frame-windows screen (screen-current-frame screen) l)
      ;; If the frame has no window, give it the current window of
      ;; the current frame.
      (unless (frame-window l)
	(setf (frame-window l)
	      (frame-window (screen-current-frame screen))))
      ;; Unsplit
      (setf (screen-frame-tree screen)
	    (remove-frame (screen-frame-tree screen)
			  (screen-current-frame screen)))
      ;; update the current frame and sync all windows
      (setf (screen-current-frame screen) l)
      (tree-iterate (screen-frame-tree screen)
		    (lambda (leaf)
		      (sync-frame-windows screen leaf)))
      (frame-raise-window screen l (frame-window l))
      (when (frame-window l)
	(update-window-border screen (frame-window l)))
      (show-frame-indicator screen))))

(define-stumpwm-command "remove" (screen)
  (remove-split screen))

(define-stumpwm-command "only" (screen)
  (let ((frame (make-initial-frame (screen-x screen) (screen-y screen)
				   (screen-width screen) (screen-height screen)))
	(win (frame-window (screen-current-frame screen))))
    (mapc (lambda (w)
	    ;; windows in other frames disappear
	    (unless (eq (window-frame w) (screen-current-frame screen))
	      (hide-window w))
	    (setf (window-frame w) frame))
	  (screen-mapped-windows screen))
    (setf (frame-window frame) win
	  (screen-frame-tree screen) frame)
    (focus-frame screen frame)
    (when (frame-window frame)
      (update-window-border screen (frame-window frame)))
    (sync-frame-windows screen (screen-current-frame screen))))

(define-stumpwm-command "curframe" (screen)
  (show-frame-indicator screen))

(defun focus-frame-sibling (screen)
  (let* ((sib (sibling (screen-frame-tree screen)
		      (screen-current-frame screen))))
    (when sib
      (focus-frame screen (tree-accum-fn sib
                                         (lambda (x y)
                                           (declare (ignore y))
                                           x)
                                         'identity))
      (show-frame-indicator screen))))

(defun focus-frame-after (screen frames)
  "Given a list of frames focus the next one in the list after
the current frame."
  (let ((rest (cdr (member (screen-current-frame screen) frames :test 'eq))))
    (focus-frame screen
		 (if (null rest)
		     (car frames)
		     (car rest)))))

(defun focus-next-frame (screen)
  (focus-frame-after screen (screen-frames screen))
  (show-frame-indicator screen))

(defun focus-prev-frame (screen)
  (focus-frame-after screen (nreverse (screen-frames screen)))
  (show-frame-indicator screen))

(define-stumpwm-command "fnext" (screen)
  (focus-next-frame screen))

(define-stumpwm-command "sibling" (screen)
  (focus-frame-sibling screen))

(defun choose-frame-by-number (screen)
  "show a number in the corner of each frame and wait for the user to
select one. Returns the selected frame or nil if aborted."
  (let* ((wins (progn
		 (draw-frame-outlines screen)
		 (draw-frame-numbers screen)))
	 (ch (read-one-char screen))
	 (num (read-from-string (string ch))))
    (dformat "read ~S ~S~%" ch num)
    (mapc #'xlib:destroy-window wins)
    (clear-frame-outlines screen)
    (find ch (screen-frames screen)
	  :test 'char=
	  :key 'get-frame-number-translation)))


(define-stumpwm-command "fselect" (screen (f :frame))
  (focus-frame screen f)
  (show-frame-indicator screen))

(define-stumpwm-command "resize" (screen (w :number "+ Width: ")
                                         (h :number "+ Height: "))
  (let ((f (screen-current-frame screen)))
    (resize-frame screen f w 'width)
    (resize-frame screen f h 'height)))

(defun eval-line (screen cmd)
  (echo-string screen
	       (handler-case (prin1-to-string (eval (read-from-string cmd)))
		 (error (c)
		   (format nil "~A" c)))))

(define-stumpwm-command "eval" (screen (cmd :rest "Eval: "))
  (eval-line screen cmd))

(define-stumpwm-command "echo" (screen (s :rest "Echo: "))
  (echo-string screen s))

;; Simple command & arg parsing
(defun split-by-one-space (string)
  "Returns a list of substrings of string divided by ONE space each.
Note: Two consecutive spaces will be seen as if there were an empty
string between them."
  (loop for i = 0 then (1+ j)
	as j = (position #\Space string :start i)
	collect (subseq string i j)
	while j))

(defun parse-and-run-command (input screen)
  "Parse the command and its arguments given the commands argument
specifications then execute it. Returns a string or nil if user
aborted."
  (macrolet ((skip-spaces (string-list)
			  ;; A nice'n'gross side-effect loop
			  `(do ((s #1=(car ,string-list) #1#))
			       ((or (null s)
				    (string/= s "")) ,string-list)
			     (pop ,string-list)))
	     (pop-or-read (l prompt scrn)
			  `(or (pop ,l)
			       ;; If prompt is nil, then the argument is
			       ;; considered optional.
			       (unless (null ,prompt)
				 (or (read-one-line ,scrn ,prompt)
				     ;; read-one-line returns nil when the user aborts
				     (throw 'error "Abort."))))))
    (let (str cmd arg-specs args)
      ;; Catch parse errors
      (catch 'error
	;; Setup the input
	(setf str (split-by-one-space input))
	;; Make sure we have a valid command
	(skip-spaces str)
	(setf cmd (gethash (pop str) *command-hash*))
	(if cmd
	    (setf arg-specs (command-args cmd))
	  (throw 'error (format nil "Command '~a' not found." input)))
	;; Create a list of args to pass to the function. If str is
	;; snarfed and we have more args, then prompt the user for a
	;; value.
	(dformat "str: ~A~%" str)
	(setf args (mapcar (lambda (spec)
			     (let ((type (second spec))
				   (prompt (third spec)))
			       (skip-spaces str)
			       (case type
				 (:number 
				  (let ((n (pop-or-read str prompt screen)))
				    (when n
				      (parse-integer n))))
				 (:string 
				  (pop-or-read str prompt screen))
				 (:key
				  (let ((s (pop-or-read str prompt screen)))
				    (when s
				      (kbd s))))
				 (:frame
				  (let ((arg (pop str)))
				    (if arg
					(or (find arg (screen-frames screen)
						  :key (lambda (f)
							 (string (get-frame-number-translation f)))
						  :test 'string=)
					    (throw 'error "Frame not found."))
					(or (choose-frame-by-number screen)
					    (throw 'error "Abort.")))))
				  (:rest
				      (if (null str)
					  (when prompt
					    (or (read-one-line screen prompt)
						(throw 'error "Abort.")))
					(prog1
					    (format nil "~{~A~^ ~}" str)
					  (setf str nil))))
				 (t (throw 'error "Bad argument type")))))
			     arg-specs))
	;; Did the whole string get parsed? (get rid of trailing
	;; spaces)
	(dformat "arguments: ~S~%" args)
	(unless (null (skip-spaces str))
	  (throw 'error (format nil "Trailing garbage: ~{~A~^ ~}" str)))
	;; Success
	(apply (command-fn cmd) screen args)))))

(defun interactive-command (cmd screen)
  "exec cmd and echo the result."
  (let ((result (handler-case (parse-and-run-command cmd screen)
			      (error (c)
				     (format nil "~A" c)))))
    ;; interactive commands update the modeline
    (when (screen-mode-line screen)
      (redraw-mode-line-for (screen-mode-line screen) screen))
    (when (stringp result)
      (echo-string screen result))))

(define-stumpwm-command "colon" (screen (cmd :rest ": "))
  (interactive-command cmd screen))

(defun pull-window-by-number (screen n)
  "Pull window N from another frame into the current frame and focus it."
  (let ((win (find n (screen-mapped-windows screen) :key 'window-number :test '=)))
    (when win
      (let ((f (window-frame win)))
	(setf (window-frame win) (screen-current-frame screen))
	(sync-frame-windows screen (screen-current-frame screen))
	(frame-raise-window screen (screen-current-frame screen) win)
	;; if win was focused in its old frame then give the old
	;; frame the frame's last focused window.
	(when (eq (frame-window f) win)
	  ;; the current value is no longer valid.
	  (setf (frame-window f) nil)
	  (frame-raise-window screen f (first (frame-windows screen f)) nil))))))

(define-stumpwm-command "pull" (screen (n :number "Pull: "))
  (pull-window-by-number screen n))

(defun send-meta-key (screen key)
  "Send the prefix key"
  (when (screen-current-window screen)
    (send-fake-key (screen-current-window screen) key)))

(define-stumpwm-command "meta" (screen (key :key "Key: "))
  (send-meta-key screen key))

(defun renumber (screen nt)
  "Renumber the current window"
  (let ((nf (window-number (screen-current-window screen)))
	(win (find-if #'(lambda (win)
			  (= (window-number win) nt))
		      (screen-mapped-windows screen))))
    ;; Is it already taken?
    (if win
	(progn
	  ;; swap the window numbers
	  (setf (window-number win) nf)
	  (setf (window-number (screen-current-window screen)) nt))
      ;; Just give the window the number
      (setf (window-number (screen-current-window screen)) nt))))

(define-stumpwm-command "number" (screen (n :number "Number: "))
  (renumber screen n))

(define-stumpwm-command "reload" (screen)
  (echo-string screen "Reloading StumpWM...")
  (asdf:operate 'asdf:load-op :stumpwm)
  (echo-string screen "Reloading StumpWM...Done."))

(define-stumpwm-command "loadrc" (screen)
  (multiple-value-bind (success err rc) (load-rc-file)
    (echo-string screen
		 (if success
		     "RC File loaded successfully."
		     (format nil "Error loading ~A: ~A" rc err)))))

(defun display-keybinding (screen kmap)
  (echo-string-list screen (mapcar-hash #'(lambda (k v) (format nil "~A -> ~A" (print-key k) v)) kmap)))

(define-stumpwm-command "help" (screen)
  (display-keybinding screen *root-map*))

;; Trivial function
(define-stumpwm-command "abort" (screen)
  (declare (ignore screen)))

(defun set-prefix-key (key)
  "Change the stumpwm prefix key to KEY."
  (check-type key key)
  (let (prefix)
    (dolist (i (lookup-command *top-map* '*root-map*))
      (setf prefix i)
      (undefine-key *top-map* i))
    (define-key *top-map* key '*root-map*)
    (let* ((meta (make-key :keysym (key-keysym key)))
	   (old-cmd (concatenate 'string "meta " (print-key prefix)))
	   (cmd (concatenate 'string "meta " (print-key key))))
      (dolist (i (lookup-command *root-map* old-cmd))
	(undefine-key *root-map* i))
      (define-key *root-map* meta cmd))
    (define-key *root-map* key "other")
    (sync-keys)))

(define-stumpwm-command "quit" (screen)
  (declare (ignore screen))
  (throw :quit nil))

(defun clear-frame (frame screen)
  "Clear the given frame."
  (frame-raise-window screen frame nil (eq (screen-current-frame screen) frame)))

(define-stumpwm-command "fclear" (screen)
  (clear-frame (screen-current-frame screen) screen))

(defun find-closest-frame (ref-frame framelist closeness-func lower-bound-func
			   upper-bound-func)
  (loop for f in framelist
     with r = nil
     do (when (and
	       ;; Frame is on the side that we want.
	       (<= 0 (funcall closeness-func f))
	       ;; Frame is within the bounds set by the reference frame.
	       (or (<= (funcall lower-bound-func ref-frame)
		       (funcall lower-bound-func f)
		       (funcall upper-bound-func ref-frame))
		   (<= (funcall lower-bound-func ref-frame)
		       (funcall upper-bound-func f)
		       (funcall upper-bound-func ref-frame))
		   (<= (funcall lower-bound-func f)
		       (funcall lower-bound-func ref-frame)
		       (funcall upper-bound-func f)))
	       ;; Frame is closer to the reference and the origin than the
	       ;; previous match
	       (or (null r)
		   (< (funcall closeness-func f) (funcall closeness-func r))
		   (and (= (funcall closeness-func f) (funcall closeness-func r))
			(< (funcall lower-bound-func f) (funcall lower-bound-func r)))))
	  (setf r f))
     finally (return r)))

(define-stumpwm-command "move-focus" (screen (dir :string "Direction: "))
  (destructuring-bind (perp-coord perp-span parall-coord parall-span)
      (cond
	((or (string= dir "left") (string= dir "right"))
	 (list #'frame-y #'frame-height #'frame-x #'frame-width))
	((or (string= dir "up") (string= dir "down"))
	 (list #'frame-x #'frame-width #'frame-y #'frame-height))
	(t
	 (echo-string screen "Valid directions: up, down, left, right")
	 '(nil nil nil nil)))
    (when perp-coord
      (let ((new-frame (find-closest-frame
			(screen-current-frame screen)
			(screen-frames screen)
			(if (or (string= dir "left") (string= dir "up"))
			    (lambda (f)
			      (- (funcall parall-coord (screen-current-frame screen))
				 (funcall parall-coord f) (funcall parall-span f)))
			    (lambda (f)
			      (- (funcall parall-coord f)
				 (funcall parall-coord (screen-current-frame screen))
				 (funcall parall-span (screen-current-frame screen)))))
			perp-coord
			(lambda (f)
			  (+ (funcall perp-coord f) (funcall perp-span
							     f))))))
	(when new-frame
	  (focus-frame screen new-frame))
	(show-frame-indicator screen)))))

(defun run-or-raise (screen cmd &key class instance title)
  "If any of class, title, or instance are set and a matching window can
be found, select it.  Otherwise simply run cmd."
  (labels ((win-app-info (win)
	     (list (window-class win)
		   (window-res-name win)
		   (window-name win)))
	   ;; Raise the window win and select its frame.  For now, it
	   ;; does not select the screen.
	   (goto-win (win)
	     (let* ((screen (window-screen win))
		    (frame (window-frame win)))
	       ;; Select screen?
	       (frame-raise-window screen frame win)
	       (focus-frame screen frame)))
	   ;; Compare two lists of strings representing window
	   ;; attributes.  If an element is nil it matches anything.
	   ;; Doesn't handle lists of different lengths: extra
	   ;; elements in one list will be ignored.
	   (app-info-cmp (match1 match2)
	     (or (not match1)
		 (not match2)
		 (let ((a (car match1))
		       (b (car match2)))
		   (and
		    (or (not a)
			(not b)
			(string= a b))
		    (app-info-cmp (cdr match1) (cdr match2)))))))
    (let ((win
	   ;; If no qualifiers are set don't bother looking for a match.
	   (and (or class instance title)
		(find (list class instance title)
		      (screen-mapped-windows screen)
		      :key #'win-app-info
		      :test #'app-info-cmp))))
      (if win
	  (goto-win win)
	  (run-shell-command cmd)))))

(define-stumpwm-command "shell" (screen)
  (run-or-raise screen "xterm -title '*shell*'" :title "*shell*"))

(define-stumpwm-command "web" (screen)
  (run-or-raise screen "firefox" :class "mozilla-firefox"))

(define-stumpwm-command "escape" (screen (key :string "Key: "))
  (declare (ignore screen))
  (set-prefix-key (kbd key)))

