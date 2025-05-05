extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var avatar_ui = $Control/avatar_ui
onready var username_ui = $username_ui


# Called when the node enters the scene tree for the first time.
func _ready():
	populate_ui(Client.user_data.username, Client.user_data.avatar)

func populate_ui(username, avatar):
	username_ui.text = username
	load_avatar(avatar) # Gravatar URL

func load_avatar(url):
	var image_loader = HTTPRequest.new()
	add_child(image_loader)
	image_loader.connect("request_completed", self, "_on_avatar_loaded")
	image_loader.request(url)

func _on_avatar_loaded(_result, response_code, _headers, body):
	if response_code == 200:
		var img = Image.new()
		var err = img.load_png_from_buffer(body)
		if err == OK:
			var texture = ImageTexture.new()
			texture.create_from_image(img)
			avatar_ui.texture = texture
		else:
			print("Failed to load avatar image")
	else:
		print("Failed to download avatar:", response_code)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
