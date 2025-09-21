extends Node

var port = 9000
var peer = NetworkedMultiplayerENet.new()
var max_players = 50
onready var players = {}
onready var logs_ui = $logs_ui
var tcp_server = TCP_Server.new()

var env = {}

func load_env():
	var file = File.new()
	file.open("res://env.json", File.READ)
	if file:
		env = JSON.parse(file.get_as_text()).result
		file.close()
	else:
		print("Failed to load env.json!")

const LOG_FILE_PATH = "C:/pingville_logs/server.log"

func write_log(msg: String) -> void:
	logs_ui.add_text("[%s] %s\n" % [Time.get_datetime_string_from_system(false), msg])
	var file = File.new()
	if file.open(LOG_FILE_PATH, File.READ_WRITE) == OK:
		file.seek_end()
		file.store_line("[%s] %s" % [Time.get_datetime_string_from_system(false), msg])
		file.close()


func _ready():
	randomize()
	load_env()
	start_server()
	tcp_server.listen(9050)
	write_log("Server started on port %d" % port)

func _process(_delta):
	if tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		if conn:
			var player_count = str(players.size())
			write_log("TCP connection received. Sent player count: %s" % player_count)
			conn.put_utf8_string("players=" + player_count)
			conn.disconnect_from_host()

func start_server():
	print("Starting server...")
	write_log("Starting ENet server...")
	peer.create_server(port, max_players)
	get_tree().set_network_peer(peer)
	peer.connect("peer_connected", self, "_on_player_connected")
	peer.connect("peer_disconnected", self, "_on_player_disconnected")

func _on_player_connected(id):
	var name = generate_gamer_tag()
	players[id] = {"pos": Vector2(0, 0), "name": name}
	write_log("Player connected: ID=%d, Name=%s" % [id, name])

	rpc("spawn_player", id, Vector2(0, 0), name)

	for other_id in players.keys():
		if other_id != id:
			var player = players[other_id]
			rpc_id(id, "spawn_player", other_id, player["pos"], player["name"])

func _on_player_disconnected(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free()
		rpc("despawn_player", id)
	var name = players.get(id, {}).get("name", "Unknown")
	write_log("Player disconnected: ID=%d, Name=%s" % [id, name])
	players.erase(id)

remote func handle_chat_command(command: String, sender_id: int, token: String):
	var cmd = command.strip_edges()
	write_log("Received chat command '%s' from ID=%d" % [cmd, sender_id])

	if cmd == "/list":
		var usernames = []
		for id in players:
			usernames.append(players[id].get("name"))
		rpc_id(sender_id, "show_player_list", usernames)
		write_log("Sent player list to ID=%d: [%s]" % [sender_id, ", ".join(usernames)])

	elif cmd.begins_with("/kick "):
		kick_player(token, cmd.get_slice(" ", 1), sender_id)
		

remote func broadcast_chat_message(message: String, sender_id: int):
	var sender_name = players.get(sender_id).get("name", "Unknown")
	var formatted = sender_name + ": " + message
	rpc("receive_chat_message", formatted)
	write_log("Chat from %s (ID=%d): %s" % [sender_name, sender_id, message])

remote func update_server_position(pos, direction, animation):
	var id = get_tree().get_rpc_sender_id()
	if players.has(id):
		players[id]["pos"] = pos
		players[id]["direction"] = direction
		players[id]["animation"] = animation
		for pid in players.keys():
			if pid != id:
				rpc_unreliable_id(pid, "update_remote_position", id, pos, direction, animation)

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
	var number = str(randi() % 1000)
	return adjective + animal + number


func kick_player(token: String, name: String, sender_id: int):
	var url = str(env.get("BASE_URL")) + "/api/check_admin.php?token=" + token
	print(url)
	var http = HTTPRequest.new()
	add_child(http)

	var err = http.request(url)
	if err != OK:
		write_log("Failed to request admin status")
		return false

	# Wait for response
	var result = yield(http, "request_completed")

	# result is an array: [result, response_code, headers, body]
	var body = result[3]  # The response body is at index 3
	var response_text = body.get_string_from_utf8()

	var json = parse_json(response_text)
	http.queue_free()
	var is_admin = json.get("admin", false)
	if is_admin:
		var target_name = name
		var kicked = false
		for id in players:
			if players[id].get("name") == target_name:
				write_log("Admin ID=%d kicked player %s (ID=%d)" % [sender_id, target_name, id])
				rpc_id(id, "kick_from_server", "You were kicked by an admin.")
				rpc("despawn_player", id)
				rpc("receive_chat_message", "Player %s was kicked by admin %s" % [target_name, players[sender_id].get("name")])
				players.erase(id)
				kicked = true
				break
		if not kicked:
			rpc_id(sender_id, "receive_chat_message", "Player not found: " + target_name)
	else:
		rpc_id(sender_id, "receive_chat_message", "You are not authorized to use this command.")
		write_log("Unauthorized kick attempt by ID=%d" % sender_id)


