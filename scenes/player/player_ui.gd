extends CanvasLayer

class_name PlayerUI

@onready var menu: Control = %Menu
@onready var button_leave: Button = %ButtonLeave
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession
@onready var hit_marker: Label = %HitMarker
@onready var item_list: ItemList = %ItemList

@onready var crystal_health_root: VBoxContainer = %CrystalHealthRoot
@onready var progress_bar_crystal: ProgressBar = %ProgressBarCrystal

@onready var option_button_color: OptionButton = %OptionButtonColor
@onready var button_start_round: Button = %ButtonStartRound
@onready var controls_root: VBoxContainer = %ControlsRoot

var COLORS: Array[Color] = [
	Color.MAGENTA,
	Color.CRIMSON,
	Color.GREEN,
	Color.SKY_BLUE
]

func _ready() -> void:
	menu.hide()
	hit_marker.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	button_leave.pressed.connect(func(): Network.leave_server())
	button_copy_session.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)
	label_session.text = Network.tube_client.session_id

	for single_color in COLORS:
		var new_texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.add_point(0, single_color)
		gradient.remove_point(1)
		new_texture.gradient = gradient	
		option_button_color.add_icon_item(new_texture, "")

	# username, score
	item_list.max_columns = 2
	item_list.same_column_width = true
	item_list.auto_height = true
	item_list.auto_width = true
	
	Global.signal_session_info.connect(render_item_list)
	Global.signal_crystal_health.connect(render_crystal_health)
	progress_bar_crystal.max_value = Global.CRYSTAL_DEFAULT_HEALTH
	progress_bar_crystal.value = Global.CRYSTAL_DEFAULT_HEALTH

	button_start_round.pressed.connect(Global.crystal_game_start)

func render_item_list(new_info: Dictionary):
	item_list.clear()
	for peer_id in new_info.keys():
		var player_info = new_info[peer_id]
		
		item_list.add_item(player_info.username)
		item_list.add_item(str(player_info.score))

func render_crystal_health(new_health: int):
	progress_bar_crystal.value = new_health
	
