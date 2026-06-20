extends VBoxContainer


## Emitted when the player picks a lobby from the list; carries its session id.
signal signal_update_lobby_code(session_id: String)


const SCRAPE_INTERVAL := 10.0

# Throwaway tracker used to scrape the lobby list without joining a session
# (the client only owns trackers while in a session). RefCounted, so it must be
# pumped each frame to poll its socket; dropping the reference closes it.
var _scrape_tracker: TubeTracker


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = SCRAPE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_request_lobbies)
	add_child(timer)

	# Populate immediately rather than waiting for the first interval.
	await get_tree().create_timer(3.0).timeout
	_request_lobbies()

func _process(delta: float) -> void:
	if null == _scrape_tracker:
		return

	_scrape_tracker._process(delta)
	if null != _scrape_tracker and _scrape_tracker.is_close():
		_scrape_tracker = null


func _request_lobbies() -> void:
	# A scrape is already in flight; let it finish before starting another.
	if _scrape_tracker:
		return

	var context := _get_context()
	if null == context:
		return

	if context.trackers_urls.is_empty():
		push_warning("Lobby list: no tracker url configured")
		return

	var tracker := TubeTracker.new()
	if tracker.connect_to_url(context.trackers_urls[0]):
		push_warning("Lobby list: cannot connect to tracker")
		return

	tracker.connected.connect(_on_tracker_connected)
	tracker.received_scrape.connect(_on_lobbies_received)
	_scrape_tracker = tracker


func _on_tracker_connected() -> void:
	var context := _get_context()
	if _scrape_tracker and context:
		# Only this app's lobbies.
		_scrape_tracker.send_scrape(context.app_id)


func _on_lobbies_received(lobbies: Dictionary) -> void:
	var context := _get_context()
	var app_id := context.app_id if context else ""
	
	print(app_id)
	_rebuild_list(lobbies.get(app_id, []))

	# Done; dropping the only reference frees it and closes the socket.
	_scrape_tracker = null


func _rebuild_list(session_ids: Array) -> void:
	_clear_lobbies()

	for session_id in session_ids:
		_add_lobby_row(session_id)


func _clear_lobbies() -> void:
	print('Clear')
	for child in get_children():
		if child is HBoxContainer:
			# Detach now so it leaves the layout immediately, then free it.
			remove_child(child)
			child.queue_free()


func _add_lobby_row(session_id: String) -> void:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = session_id
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var button := Button.new()
	button.text = "Join"
	button.pressed.connect(_on_lobby_button_pressed.bind(session_id))
	row.add_child(button)

	add_child(row)


func _on_lobby_button_pressed(session_id: String) -> void:
	signal_update_lobby_code.emit(session_id)


func _get_context() -> TubeContext:
	if not is_instance_valid(Network.tube_client):
		return null

	return Network.tube_client.context
