extends CanvasLayer

const WORLD_FOREST = preload("uid://yubh30707eb7")

@onready var line_edit_session: LineEdit = %LineEditSession
@onready var line_edit_username: LineEdit = %LineEditUsername
@onready var button_join: Button = %ButtonJoin
@onready var button_host: Button = %ButtonHost
@onready var button_quit: Button = %ButtonQuit
@onready var label_error: Label = %LabelError

func _ready() -> void:
	line_edit_session.text_changed.connect(update_session)
	line_edit_username.text_changed.connect(update_username)
	
	button_join.pressed.connect(on_join)
	button_host.pressed.connect(on_host)
	button_quit.pressed.connect(func(): get_tree().quit())

	Network.signal_error_raised.connect(on_error)
	label_error.hide()

func on_host():
	Network.host()
	add_world()

func on_join():
	multiplayer.connected_to_server.connect(add_world)
	Network.join(line_edit_session.text)

func add_world():
	var new_world = WORLD_FOREST.instantiate()
	get_tree().current_scene.add_child(new_world)
	hide()

func update_session(new_text: String):
	if new_text != "":
		button_join.disabled = false

func update_username(new_text: String):
	Global.username = new_text

func on_error():
	if multiplayer.connected_to_server.is_connected(add_world):
		multiplayer.connected_to_server.disconnect(add_world)
	line_edit_session.text_changed.emit("")
	label_error.show()
