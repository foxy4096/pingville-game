extends KinematicBody2D

var speed = 200
var velocity = Vector2()

func _ready():
	if is_network_master():  # Only allow local player to move
		set_process(true)
	else:
		set_process(false)

func _process(delta):
	if is_network_master():  # Only local player sends movement
		velocity = Vector2()
		if Input.is_action_pressed("ui_right"):
			velocity.x += speed
		if Input.is_action_pressed("ui_left"):
			velocity.x -= speed
		if Input.is_action_pressed("ui_down"):
			velocity.y += speed
		if Input.is_action_pressed("ui_up"):
			velocity.y -= speed

		velocity = velocity.normalized() * speed
		move_and_slide(velocity)

		# Send movement to the server
		rpc_unreliable("update_position", global_position)

remote func update_position(new_position):
	global_position = new_position
