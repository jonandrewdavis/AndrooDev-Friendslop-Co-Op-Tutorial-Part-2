extends CharacterBody3D

class_name Player

@export var sensitivity: float = 0.002

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var camera_3d: Camera3D = %Camera3D
@onready var head: Node3D = %Head
@onready var nameplate: Label3D = %Nameplate

@onready var menu: Control = %Menu
@onready var button_leave: Button = %ButtonLeave
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession
@onready var controls: VBoxContainer = %Controls
@onready var hit_marker: Label = %HitMarker
@onready var player_ui: CanvasLayer = %PlayerUi

@onready var sound_hit: AudioStreamPlayer = %SoundHit
@onready var sound_ping: AudioStreamPlayer = %SoundPing

@onready var animation_library_godot_standard: Node3D = %AnimationLibrary_Godot_Standard
@onready var animation_player: AnimationPlayer = $Head/AnimationLibrary_Godot_Standard/AnimationPlayer

#@onready var arms_root: Node3D = %ArmsRoot
#@export var sword_animation_player: AnimationPlayer

var immobile := false

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	add_to_group("Players")
	player_ui.hide()	
	nameplate.text = name
	animation_player.playback_default_blend_time = 0.2
	#sword_animation_player.playback_default_blend_time = 0.2
	#sword_animation_player.speed_scale = 0.7
	#arms_root.hide()

	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	ready_client_visuals()
	ready_client_menu()

func ready_client_visuals():
	#animation_library_godot_standard.hide()
	camera_3d.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Global.username: 
		nameplate.text = Global.username

func ready_client_menu():
	player_ui.show()
	menu.hide()
	hit_marker.hide()
	label_session.text = Network.tube_client.session_id
	button_leave.pressed.connect(func(): Network.leave_server())
	button_copy_session.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() or immobile:
		return
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)	
		camera_3d.rotate_x(-event.relative.y * sensitivity)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('menu'):
		open_menu(menu.visible)
		
	if immobile:
		return

	if Input.is_action_just_pressed('shoot'):
		shoot()	

func open_menu(current_visibility: bool):
	menu.visible = !current_visibility
	
	immobile = menu.visible
	controls.visible = !menu.visible

	if menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if immobile:
		direction = Vector3.ZERO

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	handle_animation(direction)
	move_and_slide()

func handle_animation(direction: Vector3):
	if animation_player.current_animation == "Sword_Attack":
		return

	if velocity.y == 0.0:
		if direction.x != 0.0 or direction.x != 0.0:
			animation_player.play("Walk")
		else:
			animation_player.play("Idle")
	else:
		animation_player.play("Jump")



var can_shoot := true

func shoot():
	if can_shoot == false:
		return 
		
	can_shoot = false
	var force = 100
	var pos = global_position
	var shoot_dir = get_shoot_direction()
	Global.shoot_ball.rpc_id(1, pos, shoot_dir, force)
	#sword_animation_player.play("arm_model_animations/swing_01")
	animation_player.play("Sword_Attack")
	await animation_player.animation_finished
	can_shoot = true
	
func get_shoot_direction():
	var viewport_rect = get_viewport().get_visible_rect().size
	var raycast_start = camera_3d.project_ray_origin(viewport_rect / 2)
	var raycast_end = raycast_start + camera_3d.project_ray_normal(viewport_rect / 2) * 200
	return -(raycast_start - raycast_end).normalized()

@rpc("any_peer", 'call_local')
func register_hit(is_dead = false):
	if is_dead:
		sound_ping.play()
	else:
		sound_hit.play()
	
	hit_marker.show()
	await get_tree().create_timer(0.2).timeout
	hit_marker.hide()
