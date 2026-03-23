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
	#interact_area.signal_display_text.connect(update_interact_text)
	#interact_area.signal_is_holding.connect(update_is_holding)
