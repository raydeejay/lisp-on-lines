(in-package :mewa)

;;;one-line objects
(defcomponent mewa-one-line-presentation (mewa one-line-presentation)
  ()
  (:default-initargs :attributes-getter #'one-line-attributes-getter))

(defmethod one-line-attributes-getter ((self mewa))
  (or (meta-model:list-keys (instance self))))

;;;objects
(defcomponent mewa-object-presentation (mewa ucw:object-presentation) ())

;;;lists
(defcomponent mewa-list-presentation (mewa ucw:list-presentation) 
  ((instances :accessor instances :initarg :instances :initform nil)
   (instance :accessor instance)
   (select-label :accessor select-label :initform "select" :initarg :select-label)
   (selectablep :accessor selectablep :initform t :initarg :selectablep)))

(defaction select-from-listing ((listing mewa-list-presentation) object index)
  (answer object))

(defmethod render-list-row ((listing mewa-list-presentation) object index)
  (<:tr :class "item-row"
    (<:td :align "center" :valign "top"
      (when (ucw::editablep listing)
	(let ((object object))
	  (<ucw:input :type "submit"
		      :action (edit-from-listing listing object index)
		      :value (ucw::edit-label listing))))
      (<:as-is " ")
      (when (ucw::deleteablep listing)
	(let ((index index))
	  (<ucw:input :type "submit"
		      :action (delete-from-listing listing object index)
		      :value (ucw::delete-label listing))))
      (when (selectablep listing)
	(let ((index index))
	  (<ucw:input :type "submit"
		      :action (select-from-listing listing object index)
		      :value (select-label listing)))))
    (dolist (slot (slots listing))
      (<:td :class "data-cell" (present-slot slot object)))
    (<:td :class "index-number-cell"
      (<:i (<:as-html index)))
    ))

(defmethod get-all-instances ((self mewa-list-presentation))
  (instances self))
