extends Node

const PLAYER = preload("uid://dbcqeo103wau6")
const TUBE_CONTEXT = preload("uid://chqw3jdoon6c1")

var enet_peer := ENetMultiplayerPeer.new()
var tube_client := TubeClient.new()
var tube_enabled := true
var turn_enabled := true : set = set_turn_enabled

var new_offline := OfflineMultiplayerPeer.new()
var new_http_client := HTTPRequest.new()

var PORT = 9999
var IP_ADDRESS = '127.0.0.1'

signal signal_matchmaking_start
signal signal_matchmaking_wait
signal signal_matchmaking_error

var matchmaking_websocket := WebSocketPeer.new()
var matchmaking_websocket_url := "wss://api.androodev.com/websocket"
#var matchmaking_websocket_url := "ws://localhost:8787/websocket"
var matchmaking = true

func _ready() -> void:
	set_process(false)

	new_http_client.request_completed.connect(_on_request_completed)
	get_tree().root.add_child.call_deferred(new_http_client)


	if tube_enabled:
		tube_client.context = TUBE_CONTEXT
		get_tree().root.add_child.call_deferred(tube_client)

	await get_tree().process_frame
	new_http_client.request("https://api.androodev.com/turn")
	await new_http_client.request_completed
	if matchmaking:
		tube_client._peer_initiated.connect(func(_peer): close_matchmaking_websocket())
		signal_matchmaking_error.connect(_restart_matchmaking)
		connect_to_matchmaking()

func tube_create(custom_session_id: String = ''):
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	tube_client.create_session(custom_session_id)
	add_player(1)

func tube_join(session_id: String = ''):
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	tube_client.join_session(session_id)

func start_server():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

func join_server():
	enet_peer.create_client(IP_ADDRESS, PORT)
	multiplayer.peer_connected.connect(add_player) 
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.multiplayer_peer = enet_peer	

func on_connected_to_server():
	add_player(multiplayer.get_unique_id())

func add_player(peer_id: int):
	if peer_id == 1 and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		return
	
	var new_player = PLAYER.instantiate()
	new_player.name = str(peer_id)

	var rand_x = randf_range(-5.0, 5.0)
	var rand_z = randf_range(-5.0, 5.0)

	new_player.position = Vector3(rand_x, 1.0, rand_z)
	get_tree().current_scene.add_child(new_player, true)

func remove_player(peer_id):
	if peer_id == 1:
		leave_server()
		return
	
	var players: Array[Node] = get_tree().get_nodes_in_group('Players')
	var player_to_remove = players.find_custom(func(item): return item.name == str(peer_id))
	if player_to_remove != -1:
		players[player_to_remove].queue_free()

func leave_server():
	if tube_enabled:
		tube_client.leave_session()

	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	clean_up_signals()
	get_tree().reload_current_scene()
	
func clean_up_signals():
	multiplayer.peer_connected.disconnect(add_player) 
	multiplayer.peer_disconnected.disconnect(remove_player)
	multiplayer.connected_to_server.disconnect(on_connected_to_server)

func _exit_tree() -> void:
	if tube_enabled:
		tube_client.leave_session()

var temp_ice: Dictionary

func _on_request_completed(_result, _response_code, _headers, body):
	var response: Dictionary = JSON.parse_string(body.get_string_from_utf8())

	if response and response.has("iceServers"):
		temp_ice = response["iceServers"][1]
		tube_client.context.turn_servers.append(temp_ice)
		prints("DEBUG", tube_client.context.turn_servers)

func set_turn_enabled(is_enabled: bool):
	tube_client.context.turn_servers.clear()
	if is_enabled and temp_ice:
		tube_client.context.turn_servers.append(temp_ice)
	elif is_enabled:
		new_http_client.request("https://api.androodev.com/turn")


func delist_session(_id: int) -> void:
	tube_client._terminate_signaling()
	close_matchmaking_websocket()

func close_matchmaking_websocket() -> void:
	var state := matchmaking_websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN or state == WebSocketPeer.STATE_CONNECTING:
		matchmaking_websocket.close()

func connect_to_matchmaking() -> void:
	signal_matchmaking_start.emit()
	var err := matchmaking_websocket.connect_to_url(matchmaking_websocket_url)
	if err == OK:
		set_process(true)
		print("Connecting to matchmaking: %s..." % matchmaking_websocket_url)
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
		# NOTE: This action confirms the connection & queues for matchmaking
		matchmaking_websocket.send_text("connect")
	else:
		# TODO: Retry? Timeout?
		push_error("Unable to connect.")
		set_process(false)


func _process(_delta: float) -> void:
	matchmaking_websocket.poll()
	var state := matchmaking_websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while matchmaking_websocket.get_available_packet_count():
			var packet := matchmaking_websocket.get_packet()
			if matchmaking_websocket.was_string_packet():
				parse_packet(packet)
			else:
				print("< Got binary data from server: %d bytes" % packet.size())
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code := matchmaking_websocket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		#if multiplayer.get_peers().size() == 0:
			#signal_matchmaking_error.emit()

func parse_packet(body: PackedByteArray) -> void:
	var response: Dictionary = JSON.parse_string(body.get_string_from_utf8())

	if not response:
		signal_matchmaking_error.emit()
		return
		
	if response and response.has("action") == false:
		signal_matchmaking_error.emit()
		return

	# prints('DEBUG: packet ',response)
	match response.action:
		'connect':
			# NOTE: Not sent from the server
			# TODO: Can the server send this upon peer connect? 
			pass
		'wait':
			signal_matchmaking_wait.emit()
		'lobby':
			if response.has('payload'):
				handle_join_matchmaking(response.payload)
			else:
				signal_matchmaking_error.emit()
		'cancel':
			signal_matchmaking_error.emit()

# NOTE: The payload looks like this. Difficult to enforce a type.
#	sessionIds: string[];
#	host: bool;
#	room_id: string;
func handle_join_matchmaking(lobby_payload: Dictionary) -> void:
	if lobby_payload.host == true:
		tube_create(lobby_payload.room_id)
	else:
		tube_join(lobby_payload.room_id)

# TODO: Expontential backoff
func _restart_matchmaking() -> void:
	close_matchmaking_websocket()
	clean_up_signals()
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
	#connect_to_matchmaking()
