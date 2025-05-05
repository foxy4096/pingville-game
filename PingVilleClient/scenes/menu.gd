extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var username_ui = $form/username
onready var password_ui = $form/password

onready var login_request = $form/login_request
onready var fetch_user_request = $form/fetch_user_request


# Called when the node enters the scene tree for the first time.
func _ready():
	if Client.env.get("TOKEN"):
		fetch_user_data(Client.env.get("TOKEN"))
		
	login_request.connect("request_completed", self, "_on_login_request_complete")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	LogText.add_log_entry("YOU CLICKED THE BUTTON")
	LogText.add_log_entry("USERNAME: " + username_ui.text)
	LogText.add_log_entry("PASSWORD: " + password_ui.text)
	login_to_server(username_ui.text, password_ui.text)

func login_to_server(username, password):
	var body = to_json({"username": username, "password": password})
	var error = login_request.request(Client.env.get("BASE_URL") + "/api/login.php", [], false, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	
func _on_login_request_complete(_result, _response_code, _header, body):
	var resp = parse_json(body.get_string_from_utf8())
	
	
	if resp.get("status") == "success":
		print("Logged In As " + username_ui.text)
		Client.token = resp.get("token")
		fetch_user_data(resp.get("token"))



func fetch_user_data(token=""):
	if token == "":
		return
	fetch_user_request.connect("request_completed", self, "_on_get_user_data_completed")
	var body = to_json({"token": token})
	fetch_user_request.request(Client.env.get("BASE_URL") + "/api/me.php", [], Client.env.get("use_ssl"), HTTPClient.METHOD_POST, body)
	
func _on_get_user_data_completed(_result, _response_code, _header, body):
	Client.user_data = parse_json(body.get_string_from_utf8()).user
	if Client.user_data != {}:
		Client.play()


func _on_LinkButton_pressed():
	var _t = OS.shell_open(Client.env.get("BASE_URL") + "/signup.php")
