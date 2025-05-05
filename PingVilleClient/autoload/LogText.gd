extends CanvasLayer

onready var log_label = $Panel/RichTextLabel
onready var panel = $Panel

func add_log_entry(entry: String):
	log_label.add_text("\n" + Time.get_datetime_string_from_system() + " - " + entry)


func _on_toggle_pressed():
	if panel.visible:
		panel.hide()
		$toggle.text = "SHOW LOG"
	else:
		panel.show()
		$toggle.text = "HIDE LOG"


func _on_clear_pressed():
	log_label.text = ""



func _on_cmd_text_entered(command:String):
	Server.send_text_message(command)
	var tokens = command.split(" ")
	if tokens[0].to_lower() == "/me":
		if not Client.user_data.empty():
			add_log_entry("USER: " + str(Client.user_data.username))
		else:
			add_log_entry("YOU ARE NOT AUTHENTICATED")
		
	$Panel/cmd.text = ""
	$Panel/cmd.grab_focus()
