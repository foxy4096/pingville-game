extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var env = {}
var token = ""
var user_data = null



func load_env():
	var file = File.new()
	file.open("res://env.json", File.READ)
	if file:
		env = JSON.parse(file.get_as_text()).result
		file.close()
	else:
		print("Failed to load env.json!")



# Called when the node enters the scene tree for the first time.
func _ready():
	load_env()
	
	

func play():
	var _v = get_tree().change_scene("res://scenes/main.tscn")
	Server.connect_to_server()


func set_user(data):
	user_data = data
	

