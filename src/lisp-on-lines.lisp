(in-package :lisp-on-lines)

;;;; *LoL Entry points
;;;; 

;;;; This file contains the high level functions and macros 
;;;; that are part of LoL proper, that is to say, not Mewa 
;;;; or Meta-Model.

;;;; ** Initialisation
(defmethod find-default-attributes ((object t))
  "return the default attributes for a given object using the meta-model's meta-data"
  (append (mapcar #'(lambda (s) 
		      (cons (car s) 
			    (gen-pslot 
			     (if (meta-model:foreign-key-p object (car s))
				 'foreign-key
				 (cadr s))
			     (string (car s)) (car s)))) 
		  (meta-model:list-slot-types object))
	  (mapcar #'(lambda (s) 
		      (cons s (append (gen-pslot 'has-many (string s) s) 
				      `(:presentation 
					(make-presentation 
					 ,object 
					 :type :one-line)))))
		  (meta-model:list-has-many object))
	  (find-default-presentation-attribute-definitions)))

(defmethod set-default-attributes ((object t))
  "Set the default attributes for MODEL"
  (clear-attributes object)
  (mapcar #'(lambda (x) 
	      (setf (find-attribute object (car x)) (cdr x)))
	  (find-default-attributes object)))

;;;; This automagically initialises any meta model

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmethod meta-model::generate-base-class-expander :after (meta-model name args)
    (set-default-attributes name)))

;;;; The following macros are used to initialise a set of database tables as LoL objects.


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun generate-define-view-for-table (table)
    "
Generates a form that, when evaluated, initialises the given table as an lol object.
This involves creating a meta-model, a clsql view-class, and the setting up the default attributes for a mewa presentation"

    `(progn 
      (def-view-class-from-table ,table)
      (set-default-attributes (quote ,(meta-model::sql->sym table))))))
    
(defmacro define-view-for-table (&rest tables)
  " expand to a form which initialises TABLES for use with LOL"
  `(progn
    ,@(loop for tbl in tables collect (generate-define-view-for-table tbl))
    (values)))

(defmacro define-views-for-database ()
  "expands to init-i-f-t using the listing of tables provided by meta-model"
  `(define-view-for-table ,@(meta-model::list-tables)))



;;;; These are some macros over the old presentation system.
;;;; Considered depreciated, they will eventually be implemented in terms of the new
;;;; display system, and delegated to backwards-compat-0.2.lisp

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %make-view (object type attributes args)
   
    (when attributes
      (setf args
	    (cons `(:attributes ,attributes) args)))
    `(mewa::make-presentation
      ,object
      :type ,type
      ,@(when args
	      `(:initargs
		'(,@ (mapcan #'identity args)))))))

(defmethod make-view (object &rest args &key (type :viewer)
		      &allow-other-keys )
  (remf args :type)
  ;(warn "~A ~A" args `(:type ,type :initargs ,@args))
  (apply #'make-presentation object `(:type ,type ,@ (when args
						       `(:initargs ,args)))))

(defmacro present-view ((object &optional (type :viewer) (parent 'self))
			&body attributes-and-args)
  (arnesi:with-unique-names (view)
    `(let ((,view (lol::make-view ,object
				 :type ,type
				 ,@(when (car attributes-and-args)
					 `(:attributes ',(car attributes-and-args))) 
				 ,@ (cdr attributes-and-args))))
      (setf (ucw::parent ,view) ,parent)
      (lol::present ,view))))


(defmacro call-view ((object &optional (type :viewer) (component 'self component-supplied-p))
		     &body attributes-and-args)  
  `(ucw:call-component
    ,component
    ,(%make-view object type (car attributes-and-args) (cdr attributes-and-args))))

(defmethod slot-view ((self mewa) slot-name)
  (mewa::find-attribute-slot self slot-name))

(defmethod present-slot-view ((self mewa) slot-name &optional (instance (instance self)))
  (let ((v (slot-view self slot-name)))

     (if v
	 (present-slot v instance)
	 (<:as-html slot-name))))


(defmethod find-slots-of-type (model &key (type 'string)
			      (types '((string)) types-supplied-p))
  "returns a list of slots matching TYPE, or matching any of TYPES"
  (let (ty)
    (if types-supplied-p 
	(setf ty types)
	(setf ty (list type)))
    (remove nil (mapcar #'(lambda (st) (when (member (second st) ty)
					 (first st)))
	     (lisp-on-lines::list-slot-types model)))))






(defmethod word-search (class-name slots search-terms 
			&key (limit 10) (where (sql-and t)))
  (select class-name 
	  :where (sql-and
		  where
		  (word-search-where class-name slots search-terms :format-string "~a%"))
			   :flatp t
			   :limit limit))


(defmethod word-search (class-name slots (s string) &rest args)
  (apply #'word-search class-name slots (list s) args))

(defmethod word-search-where (class-name slots search-terms &key (format-string "%~a%"))
  (sql-or 
   (mapcar #'(lambda (term)
	       (apply #'sql-or 
		      (mapcar #'(lambda (slot)  
				  (sql-uplike
				   (sql-slot-value class-name slot)
				   (format nil format-string  term)))
			      slots)))
	   search-terms)))


  