extends Camera

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("click"):
			translate(Vector3(event.relative.x * -0.01, event.relative.y * 0.01, 0.0));
		elif Input.is_action_pressed("rmb_click"):
			#look_at(Vector3.ZERO, Vector3.UP);
			self.rotation_degrees += Vector3(event.relative.y*.1, event.relative.x*.1, 0)


func _process(delta):
	if Input.is_action_pressed("ui_up"):
			translate(-transform.basis.z)
	if Input.is_action_pressed("ui_down"):
			translate(transform.basis.z)
	if Input.is_action_pressed("ui_right"):
			translate(transform.basis.x)
	if Input.is_action_pressed("ui_left"):
			translate(-transform.basis.x)
	if Input.is_action_pressed("ui_up1"):
			translate(transform.basis.y)
	if Input.is_action_pressed("ui_down1"):
			translate(-transform.basis.y)
	
