extends KinematicBody2D

var speed = 200
var velocity = Vector2()
var is_local_player = false

onready var sync_timer = $SyncTimer

func setup(name):
	$Camera2D.hide()
	$name.text = name

func set_as_local():
	# Enable input or other local-only features here
	set_process_input(true)
	$Camera2D.show()
	$Camera2D.current = true
	is_local_player = true

func _ready():
	sync_timer.start()
	sync_timer.wait_time = 3
	sync_timer.one_shot = false
	sync_timer.connect("timeout", self, "_on_sync_timer_timeout")

func _process(_delta):
	if is_local_player:
		var input_velocity = Vector2()

		if Input.is_action_pressed("ui_right"):
			input_velocity.x += 1
			$Sprite.flip_h = false
		if Input.is_action_pressed("ui_left"):
			input_velocity.x -= 1
			$Sprite.flip_h = true
		if Input.is_action_pressed("ui_down"):
			input_velocity.y += 1
		if Input.is_action_pressed("ui_up"):
			input_velocity.y -= 1

		input_velocity = input_velocity.normalized()
		velocity = input_velocity * speed

		if input_velocity != Vector2.ZERO:
			var _t = move_and_slide(velocity)
			$Sprite.play("walk")
			Server.sync_position(global_position, int($Sprite.flip_h), "walk")
	$Sprite.play("default")

func _on_sync_timer_timeout():
	# You can send an HTTP request here to sync the position
	# Assuming Server.sync_position sends a request, if not you can use HTTPRequest like this:

	var http_request = HTTPRequest.new()
	add_child(http_request)  # Add HTTPRequest as a child to be part of the scene tree
	var url = Client.env.get("BASE_URL") + "/api/sync_position.php"

	# Prepare the data
	var position_data = to_json({
		"last_position": str(global_position.x) + "," + str(global_position.y),
		"token": Client.token
	})

	# Send the POST request
	var err = http_request.request(url, [], true, HTTPClient.METHOD_POST, position_data)

	if err != OK:
		print("Error sending sync request: ", err)
	else:
		print("Sync request sent successfully.")
