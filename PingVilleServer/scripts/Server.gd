extends Node

var port = 9000
var peer = NetworkedMultiplayerENet.new()
var max_players = 50
onready var players = {}
onready var logs_ui = $logs_ui

func _ready():
	randomize()
	start_server()

func start_server():
	print("Starting server...")
	peer.create_server(port, max_players)  # Max 10 players
	get_tree().set_network_peer(peer)
	peer.connect("peer_connected", self, "_on_player_connected")
	peer.connect("peer_disconnected", self, "_on_player_disconnected")



func _on_player_connected(id):
	players[id] = {"pos": Vector2(0, 0), "name": generate_gamer_tag()}
	logs_ui.add_text("\nPLAYER CONNECTED: " + str(id) + " " + players[id].get("name"))

	# ✅ Send the spawn_player RPC from the server to all clients (including the new one)
	rpc("spawn_player", id, Vector2(0, 0), players[id].get("name"))

	# ✅ Inform only the new client about the existing players
	for other_id in players.keys():
		if other_id != id:
			var player = players[other_id]
			rpc_id(id, "spawn_player", other_id, player["pos"], player["name"])



func _on_player_disconnected(id):
	
	if has_node(str(id)):
		get_node(str(id)).queue_free()
		rpc("despawn_player", id)
	logs_ui.add_text("\nPLAYER DISCONNECTD: " + str(id)  + " " + players[id].get("name"))
	players.erase(id)
	
	
remote func handle_chat_command(command: String, sender_id: int):
	if command.strip_edges() == "/list":
		var usernames = []
		for id in players:
			usernames.append(players[id].get("name"))
		rpc_id(sender_id, "show_player_list", usernames)
	
remote func broadcast_chat_message(message: String, sender_id: int):
	var sender_name = players.get(sender_id).get("name", "Unknown")
	var formatted = sender_name + ": " + message
	rpc("receive_chat_message", formatted)

remote func update_server_position(pos):
	var id = get_tree().get_rpc_sender_id()
	if players.has(id):
		players[id]["pos"] = pos
		# Broadcast to all except sender
		for pid in players.keys():
			if pid != id:
				rpc_unreliable_id(pid, "update_remote_position", id, pos)


func generate_gamer_tag() -> String:
	var adjectives = [
		"Swift", "Silent", "Fuzzy", "Crazy", "Sneaky", "Happy",
		"Chill", "Brave", "Tiny", "Witty", "Electric", "Turbo"
	]
	var animals = [
		"Sloth", "Panther", "Penguin", "Falcon", "Llama", "Otter",
		"Dragon", "Tiger", "Koala", "Wolf", "Badger", "Moose"
	]

	var adjective = adjectives[randi() % adjectives.size()]
	var animal = animals[randi() % animals.size()]
	var number = str(randi() % 1000)  # 0 to 999

	return adjective + animal + number
	

