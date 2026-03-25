class_name PlayerUI
extends CanvasLayer

@onready var menu: Control = %Menu
@onready var button_leave: Button = %ButtonLeave
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession
@onready var controls: VBoxContainer = %Controls
@onready var hit_marker: Label = %HitMarker

@onready var scoreboard: ItemList = %Scoreboard
@onready var progress_bar_crystal: ProgressBar = %ProgressBarCrystal
@onready var button_start_rond: Button = %ButtonStartRond

func _ready() -> void:
	if is_multiplayer_authority():
		ready_client_menu()
	else:
		hide()

func ready_client_menu():
	show()
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
	Global.signal_crystal_health_updated.connect(render_crystal_health)
	
	progress_bar_crystal.max_value = Global.CRYSTAL_DEFAULT_HEALTH
	progress_bar_crystal.value = Global.CRYSTAL_DEFAULT_HEALTH
	progress_bar_crystal.hide()
	
	button_start_rond.pressed.connect(Global.crystal_game_start)
	
func render_scoreboard(new_scores: Dictionary):
	scoreboard.clear()
	for peer_id in new_scores.keys(): 
		# Add the nickname
		var player = Global.get_player(peer_id)
		scoreboard.add_item(player.nameplate.text)
		
		# Add the score or 
		if peer_id in new_scores:
			scoreboard.add_item(str(new_scores[peer_id]))
		else:
			scoreboard.add_item("0")	

func render_crystal_health(current_health: int):
	if not progress_bar_crystal.visible:
		progress_bar_crystal.show()
	progress_bar_crystal.value = current_health
