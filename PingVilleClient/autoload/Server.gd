extends Node


var ip = "127.0.0.1"
var port = 9000
var peer = NetworkedMultiplayerENet.new()

	

func connect_to_server():
	print("Connecting to server...")
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	peer.connect("connection_succeeded", self, "_on_connection_succeeded")
	peer.connect("connection_failed", self, "_on_connection_failed")
		

	
func _on_connection_succeeded():
	print("Successfully Connected...")
	
func _on_connection_failed():
	print("Failed to connect...")
	

remote func spawn_player(player_id, position, name):
	print("Spawning player: ", player_id, " at ", position)
	if has_node(str(player_id)):
		return

	var player_scene = preload("res://prefabs/player.tscn")
	var player = player_scene.instance()
	player.name = str(player_id)
	player.position = position
	player.setup(name)

	if player_id == get_tree().get_network_unique_id():
		player.set_as_local()
		get_node("/root/main/current_player").add_child(player)
		# Assuming `last_position` is a string like "10.5, 20.3"
		var last_position_str = Client.user_data.get("last_position", "0,0")

		# Split the string into an array using ',' as the delimiter
		var position_parts = last_position_str.split(",")

		# Convert the split string values to floats and create a Vector2
		var sposition = Vector2(position_parts[0].to_float(), position_parts[1].to_float())

		# Set the player's position
		player.position = sposition

	else:
		get_node("/root/main/other_players").add_child(player)

remote func despawn_player(player_id):
	var players_root = get_node("/root/main/other_players")
	if players_root.has_node(str(player_id)):
		players_root.get_node(str(player_id)).queue_free()

func send_text_message(text):
	if text.begins_with("/"):
		rpc_id(1, "handle_chat_command", text, get_tree().get_network_unique_id())
	else:
		rpc_id(1, "broadcast_chat_message", text, get_tree().get_network_unique_id())

remote func show_player_list(usernames):
	print("Connected players:")
	var buff = ""
	for name in usernames:
		buff += name + "\n"
	LogText.add_log_entry(buff)

remote func receive_chat_message(message):
	LogText.add_log_entry(message)
	
remote func update_remote_position(player_id, pos):
	var node_path = "/root/main/other_players/" + str(player_id)
	if has_node(node_path):
		get_node(node_path).global_position = pos

func sync_position(pos):
	rpc_unreliable_id(1, "update_server_position", pos)
