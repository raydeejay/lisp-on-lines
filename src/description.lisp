(in-package :lisp-on-lines)

(define-layered-function description-of (thing)
  (:method (thing)
    (find-description 't)))

(defun description-print-name (description)
  (description-class-name (class-of description)))

(defun find-attribute (description attribute-name)
  (slot-value description attribute-name))

#+nil(mapcar (lambda (slotd)  
	    (slot-value-using-class (class-of description) description slotd))
	    (class-slots (class-of description)))
(defun description-attributes (description)
  (mapcar #'attribute-object (class-slots (class-of description))))

(define-layered-function attributes (description)
  (:method (description)
    (remove-if-not 
     (lambda (attribute)
       (and (eq (class-of description)
		(print (slot-value attribute 'description-class)))
	    (some #'layer-active-p 
	     (mapcar #'find-layer 
		     (slot-definition-layers 
		      (attribute-effective-attribute-definition attribute))))))
     (description-attributes description))))

  
;;; A handy macro.
(defmacro define-description (name &optional superdescriptions &body options)
  (let ((description-name (defining-description name)))     
    (destructuring-bind (&optional slots &rest options) options
      (let ((description-layers (cdr (assoc :in-description options))))
	(if description-layers
	    `(eval-when (:compile-toplevel :load-toplevel :execute)
	       ,@(loop 
		    :for layer 
		    :in description-layers
		    :collect `(define-description 
				  ,name ,superdescriptions ,slots
				  ,@(acons 
				    :in-layer (defining-description layer)
				    (remove :in-description options :key #'car)))))
	    `(eval-when (:compile-toplevel :load-toplevel :execute)
					;  `(progn
	       (defclass ,description-name 
		   ,(append (mapcar #'defining-description 
				    superdescriptions) 
			    (unless (or (eq t name)    
					(assoc :mixinp options))
			      (list (defining-description t))))
		 ,(if slots slots '())
		 ,@options
		 ,@(unless (assoc :metaclass options)
			   '((:metaclass standard-description-class))))
	       (initialize-descriptions)
	       (find-description ',name)))))))







			      



		      
  




  
  
  