@icon("../icons/tube_inspector.svg")
class_name EditorTubeClientPanel extends Control
## @experimental: This class is used as part of the TubeClientDebugPanel scene, and is part of a scene. Should not be used as itself 


const TRACKER_ITEM_CONTROL_SCENE := preload("uid://bc0iqgoaed12")
const PEER_ITEM_CONTROL_SCENE := preload("uid://dq2d125kftur6")

const MESSAGE_ITEM_CONTROL_SCENE := preload("uid://cfsei3airwx4s")


const STATE_COLORS := {
	TubeClient.State.IDLE: Color.BEIGE,
	TubeClient.State.CREATING_SESSION: Color.CYAN,
	TubeClient.State.JOINING_SESSION: Color.CYAN,
	TubeClient.State.SESSION_CREATED: Color.PALE_GREEN,
	TubeClient.State.SESSION_JOINED: Color.PALE_GREEN,
}


const SIGNALING_COLORS := {
	false: Color.CRIMSON,
	true: Color.PALE_GREEN,
}


@export var client: TubeClient:
	set(x):
		if client != x:
			if null != client:
				
				client.error_raised.disconnect(
					_on_client_error_raised
				)
				client.session_created.disconnect(
					_on_client_session_created
				)
				client.session_joined.disconnect(
					_on_client_session_joined
				)
				client.session_left.disconnect(
					_on_client_session_left
				)
				client.lobbies_received.disconnect(
					_on_client_lobbies_received
				)
				client.peer_refused.disconnect(
					_on_client_peer_refused
				)
				client.peer_connected.disconnect(
					_on_client_peer_connected
				)
				client.peer_disconnected.disconnect(
					_on_client_peer_disconnected
				)
				client.peer_unstabilized.disconnect(
					_on_client_peer_unstabilized
				)
				client.peer_stabilized.disconnect(
					_on_client_peer_stabilized
				)
				
				client._session_initiated.disconnect(
					_on_client_session_initiated
				)
				client._local_signaling_peer_initiated.disconnect(
					_on_client_local_signaling_initiated
				)
				client._tracker_initiated.disconnect(
					_on_client_tracker_initiated
				)
				client._peer_initiated.disconnect(
					_on_client_peer_initiated
				)
			
			
			if null != x:
				x.error_raised.connect(
					_on_client_error_raised
				)
				x.session_created.connect(
					_on_client_session_created
				)
				x.session_joined.connect(
					_on_client_session_joined
				)
				x.session_left.connect(
					_on_client_session_left
				)
				x.lobbies_received.connect(
					_on_client_lobbies_received
				)
				x.peer_refused.connect(
					_on_client_peer_refused
				)
				x.peer_connected.connect(
					_on_client_peer_connected
				)
				x.peer_disconnected.connect(
					_on_client_peer_disconnected
				)
				x.peer_unstabilized.connect(
					_on_client_peer_unstabilized
				)
				x.peer_stabilized.connect(
					_on_client_peer_stabilized
				)
				
				x._session_initiated.connect(
					_on_client_session_initiated
				)
				x._local_signaling_peer_initiated.connect(
					_on_client_local_signaling_initiated
				)
				x._tracker_initiated.connect(
					_on_client_tracker_initiated
				)
				x._peer_initiated.connect(
					_on_client_peer_initiated
				)
				
				
		
		client = x
		if is_instance_valid(client_control):
			client_control.client = client
	
		if is_instance_valid(peer_control):
			peer_control.client = client
		
		update()

## Maximum of messages available, the oldest message will be removed when a new message is pushed. It is to prevent memory leak.
## [br][br]
## The amount is by item, meaning is max_messages_amount is set to 100. Client can store 100 messages, each trackers 100 messages, each peers 100 messages...
@export var max_messages_amount: int = 100

var message_item_controls: Array[EditorTubeMessagesItemControl] = []
var message_item_button_group := ButtonGroup.new()

@onready var peer_label: Label = %PeerLabel
@onready var session_line_edit: LineEdit = %SessionLineEdit
@onready var session_state_indicator: Control = %SessionIndicator

@onready var join_button: Button = %JoinButton
@onready var create_button: Button = %CreateButton
@onready var refuse_new_button: Button = %RefuseNewButton
@onready var close_button: Button = %CloseButton

@onready var local_signaling_indicator: Control = %LocalSignalingIndicator
@onready var trackers_indicator: Control = %TrackersIndicator
@onready var trackers_container: Container = %TrackersContainer
@onready var peers_container: Container = %PeersContainer

@onready var client_control: Control = %ClientControl
@onready var local_signaling_control: EditorTubeLocalSignalingControl = %LocalSignalingControl
@onready var tracker_control: EditorTubeTrackerControl = %TrackerControl
@onready var peer_control: EditorTubePeerControl = %PeerControl
@onready var chat_control: Control = %ChatControl
@onready var messages_container: EditorTubeMessagesContainer = %MessagesContainer


func _ready() -> void:
	messages_container.max_messages_amount = max_messages_amount
	chat_control.max_messages_amount = max_messages_amount
	local_signaling_control.max_messages_amount = max_messages_amount
	client_control.show()
	
	message_item_button_group.allow_unpress = true
	switch_to_idle_config()
	messages_container.display_messages([], self)
	
	client = client
	update()


func clear():
	for child in trackers_container.get_children():
		trackers_container.remove_child(child)
		child.queue_free()
	
	for child in peers_container.get_children():
		peers_container.remove_child(child)
		child.queue_free()
	
	message_item_controls.clear()
	messages_container.display_messages(
		message_item_controls,
		self
	)
	update()


func switch_to_idle_config():
	session_state_indicator.modulate = STATE_COLORS[TubeClient.State.IDLE]
	local_signaling_indicator.modulate = session_state_indicator.modulate
	trackers_indicator.modulate = session_state_indicator.modulate
	session_line_edit.editable = true
	#session_line_edit.clear()

	join_button.visible = true
	create_button.visible = true
	refuse_new_button.visible = false
	close_button.visible = false


func switch_to_joined_config():
	session_line_edit.editable = false
	join_button.visible = false
	create_button.visible = false
	close_button.visible = true


func switch_to_created_config():
	session_line_edit.editable = false
	join_button.visible = false
	create_button.visible = false
	refuse_new_button.visible = true
	close_button.visible = true


func update():
	if not is_instance_valid(client):
		return
	
	if is_instance_valid(session_state_indicator):
		session_state_indicator.modulate = STATE_COLORS[client.state]
	
	if is_instance_valid(local_signaling_indicator):
		local_signaling_indicator.modulate = SIGNALING_COLORS[client._is_local_signaling()]
		if TubeClient.State.IDLE == client.state:
			local_signaling_indicator.modulate = STATE_COLORS[client.state]
	
	if is_instance_valid(trackers_indicator):
		trackers_indicator.modulate = SIGNALING_COLORS[client._is_online_signaling()]
		if TubeClient.State.IDLE == client.state:
			trackers_indicator.modulate = STATE_COLORS[client.state]
	
	if is_instance_valid(peer_label):
		peer_label.text = EditorTubePeerItemControl.get_peer_string(client.peer_id)
		peer_label.modulate = EditorTubePeerItemControl.get_peer_color(client.peer_id)
	
	if is_instance_valid(session_line_edit):
		session_line_edit.text = client.session_id
	
	if is_instance_valid(messages_container):
		if messages_container.is_displaying_from(self):
			messages_container.display_messages(
				message_item_controls,
				self
			)


func add_message_item_control(data) -> EditorTubeMessagesItemControl:
	if max_messages_amount <= message_item_controls.size():
		var item := message_item_controls.pop_front()
		item.queue_free()
	
	var message_item_control := MESSAGE_ITEM_CONTROL_SCENE.instantiate()
	message_item_controls.append(message_item_control)
	message_item_control.data = data
	message_item_control.button_group = message_item_button_group
	update()
	return message_item_control


func add_tracker(p_tracker: TubeTracker):
	var item_control := TRACKER_ITEM_CONTROL_SCENE.instantiate()
	trackers_container.add_child(item_control)
	
	#item_control.client = client
	item_control.tracker = p_tracker
	item_control.tracker_control = tracker_control
	item_control.max_messages_amount = max_messages_amount


func add_peer(peer: TubePeer):
	for i_control in peers_container.get_children():
		if i_control.peer.id == peer.id:
			i_control.peer = peer
			return
	
	var item_control := PEER_ITEM_CONTROL_SCENE.instantiate()
	peers_container.add_child(item_control)
	
	item_control.client = client
	item_control.peer = peer
	item_control.peer_control = peer_control
	item_control.max_messages_amount = max_messages_amount


func _on_header_button_pressed() -> void:
	client_control.show()
	prepare_scrape_timer()
	if not messages_container.is_displaying_from(self):
		messages_container.display_messages(
			message_item_controls,
			self
		)

var scrape_timer = Timer.new()

func prepare_scrape_timer():
	scrape_timer.timeout.connect(perform_scrape)
	scrape_timer.autostart = true
	scrape_timer.wait_time = 10.0
	scrape_timer.one_shot = false
	get_tree().current_scene.add_child.call_deferred(scrape_timer)

func perform_scrape():
	if not is_instance_valid(client):
		return

	client.perform_scrape()


func _on_join_button_pressed() -> void:
	if not is_instance_valid(client):
		return
	
	var session_id := session_line_edit.text
	client.join_session(session_id)


func _on_create_button_pressed() -> void:
	if not is_instance_valid(client):
		return

	client.create_session()


# Throwaway tracker used by the "List" button to scrape lobbies without joining
# a session (the client only owns trackers while in a session).
var _scrape_tracker: TubeTracker


func _on_list_button_pressed() -> void:
	if not is_instance_valid(client) or null == client.context:
		push_warning("List: no client or context")
		return

	if client.context.trackers_urls.is_empty():
		push_warning("List: no tracker url configured")
		return

	# Open a throwaway connection to the tracker just to scrape the lobby list.
	var tracker := TubeTracker.new()
	var url: String = client.context.trackers_urls[0]
	if tracker.connect_to_url(url):
		push_warning("List: cannot connect to tracker {url}".format({ "url": url }))
		return

	tracker.connected.connect(_on_scrape_tracker_connected)
	tracker.received_scrape.connect(_on_scrape_tracker_lobbies)
	_scrape_tracker = tracker


func _on_scrape_tracker_connected() -> void:
	if _scrape_tracker:
		_scrape_tracker.send_scrape()


func _on_scrape_tracker_lobbies(lobbies: Dictionary) -> void:
	prints("Lobbies:", lobbies)
	for app_id in lobbies:
		prints("  app_id", app_id, "->", lobbies[app_id])

	# Done; dropping the only reference frees it and closes the socket.
	_scrape_tracker = null


func _process(_delta: float) -> void:
	if null == _scrape_tracker:
		return

	# TubeTracker is a RefCounted, so it must be pumped to poll its socket.
	_scrape_tracker._process(_delta)
	if null != _scrape_tracker and _scrape_tracker.is_close():
		_scrape_tracker = null


func _on_refuse_new_button_toggled(toggled_on: bool) -> void:
	client.refuse_new_connections = toggled_on


func _on_close_button_pressed() -> void:
	if not is_instance_valid(client):
		return
	
	client.leave_session()


func _on_client_error_raised(code: int, message: String):
	var item := add_message_item_control(message)
	item.error()
	
	match code:
		TubeClient.SessionError.CREATE_SESSION_FAILED, TubeClient.SessionError.JOIN_SESSION_FAILED:
			switch_to_idle_config()
	
	update()


func _on_client_session_initiated():
	clear()
	match client.state:
		TubeClient.State.JOINING_SESSION:
			switch_to_joined_config()
		
		TubeClient.State.CREATING_SESSION:
			switch_to_created_config()
		
		TubeClient.State.IDLE:
			switch_to_idle_config()
	
	update()


func _on_client_session_created():
	switch_to_created_config()
	local_signaling_indicator.modulate = SIGNALING_COLORS[true]
	trackers_indicator.modulate = SIGNALING_COLORS[true]
	add_message_item_control("Create session {id}".format({
		"id": client.session_id
	})).success()


func _on_client_session_joined():
	switch_to_joined_config()
	local_signaling_indicator.modulate = SIGNALING_COLORS[true]
	trackers_indicator.modulate = SIGNALING_COLORS[true]
	add_message_item_control("Join session {id}".format({
		"id": client.session_id
	})).success()


func _on_client_session_left():
	switch_to_idle_config()
	add_message_item_control("Leave session {id}".format({
		"id": client.session_id
	}))


func _on_client_lobbies_received(lobbies: Dictionary):
	var session_count := 0
	for app_id in lobbies:
		session_count += lobbies[app_id].size()

	add_message_item_control("Scrape: {apps} app(s), {sessions} lobby(s)".format({
		"apps": lobbies.size(),
		"sessions": session_count,
	}))


func _on_client_peer_refused(peer_id: int):
	add_message_item_control("Peer {peer_id} connection refused".format({
		"peer_id": peer_id,
	})).warning()


func _on_client_peer_connected(peer_id: int):
	var will_add_peer := true
	for i_control in peers_container.get_children():
		if i_control.peer.id == peer_id:
			will_add_peer = false
			break
	
	if will_add_peer:
		var peer := TubePeer.new(peer_id)
		peer.connection_state = WebRTCPeerConnection.STATE_CONNECTED
		add_peer(peer)
	
	add_message_item_control("Peer {peer_id} connected".format({
		"peer_id": peer_id,
	})).success()


func _on_client_peer_disconnected(peer_id: int):
	add_message_item_control("Peer {peer_id} disconnected".format({
		"peer_id": peer_id,
	}))


func _on_client_peer_unstabilized(peer_id: int):
	add_message_item_control("Peer {peer_id} unstabilized".format({
		"peer_id": peer_id,
	})).warning()


func _on_client_peer_stabilized(peer_id: int):
	add_message_item_control("Peer {peer_id} stabilized".format({
		"peer_id": peer_id,
	}))


func _on_client_local_signaling_initiated(local_signaling_peer: TubeLocalSignalingPeer):
	local_signaling_control.local_signaling_peer = local_signaling_peer
	add_message_item_control("Local signaling on {port} initiated".format({
		"port": local_signaling_peer.udp_peer.get_local_port()
	}))
	update.call_deferred()


func _on_client_tracker_initiated(tracker: TubeTracker):
	tracker.failed.connect(update.call_deferred)
	tracker.disconnected.connect(update.call_deferred)
	add_tracker(tracker)
	add_message_item_control("Tracker {tracker} initiated".format({
		"tracker": str(tracker)
	}))
	update.call_deferred()


func _on_client_peer_initiated(peer: TubePeer):
	add_peer(peer)
	add_message_item_control("Peer {peer_id} initiated".format({
		"peer_id": peer.id,
	}))
	update.call_deferred()
