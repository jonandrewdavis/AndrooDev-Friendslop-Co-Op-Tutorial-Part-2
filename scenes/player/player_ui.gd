class_name PlayerUI
extends CanvasLayer

@onready var menu: Control = %Menu
@onready var button_leave: Button = %ButtonLeave
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession
@onready var controls: VBoxContainer = %Controls
@onready var hit_marker: Label = %HitMarker
@onready var player_ui: CanvasLayer = %PlayerUi
@onready var label_interact: Label = %LabelInteract

@onready var scoreboard: ItemList = %Scoreboard

func _ready() -> void:
	if is_multiplayer_authority():
		ready_client_menu()
	else:
		hide()

func ready_client_menu():
	player_ui.show()
	menu.hide()
	hit_marker.hide()
	label_session.text = Network.tube_client.session_id
	button_leave.pressed.connect(func(): Network.leave_server())
	button_copy_session.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)
	
	scoreboard.max_columns = 2
	scoreboard.same_column_width = true
	scoreboard.auto_height = true
	scoreboard.auto_width = true
	
	Global.signal_score_updated.connect(render_scoreboard)

func render_scoreboard(new_scores: Dictionary):
	scoreboard.clear()
	for player in get_tree().get_nodes_in_group('Players'):
		scoreboard.add_item(player.nameplate.text)
		var player_peer_id = player.get_multiplayer_authority()
		if player_peer_id in new_scores:
			scoreboard.add_item(str(new_scores[player_peer_id]))
		else:
			scoreboard.add_item("0")
