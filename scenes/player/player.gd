extends CharacterBody3D

class_name Player

const DEFAULT_SENS =  0.002
@export var sensitivity: float = DEFAULT_SENS

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var camera_3d: Camera3D = %Camera3D
@onready var head: Node3D = %Head
@onready var nameplate: Label3D = %Nameplate
@onready var player_ui: PlayerUI = %PlayerUi

@onready var sound_ping: AudioStreamPlayer = %SoundPing
@onready var sound_hit: AudioStreamPlayer = %SoundHit

@onready var animation_library_godot_standard: Node3D = %AnimationLibrary_Godot_Standard
@onready var animation_player: AnimationPlayer = $Head/AnimationLibrary_Godot_Standard/AnimationPlayer

@onready var arms_root: Node3D = %ArmsRoot
@export var sword_animation_player: AnimationPlayer
@export var sword_hurt_box: HurtBox
@onready var interact_area: InteractArea = %InteractArea
@export var tracked_velocity: Vector3

var immobile := false
var can_attack := true

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	add_to_group("Players")
	nameplate.text = name
	animation_player.playback_default_blend_time = 0.2
	sword_animation_player.playback_default_blend_time = 0.2
	sword_animation_player.speed_scale = 0.7
	arms_root.hide()

	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	ready_client_visuals()

func ready_client_visuals():
	arms_root.show()
	animation_library_godot_standard.hide()
	camera_3d.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Global.username: 
		nameplate.text = Global.username
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() or immobile:
		return
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)	
		camera_3d.rotate_x(-event.relative.y * sensitivity)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(_delta: float) -> void:
	tracked_velocity = velocity

	if Input.is_action_just_pressed('menu'):
		open_menu(player_ui.menu.visible)
		
	if immobile:
		return

	#if Input.is_action_just_pressed('shoot'):
		#shoot()	

	if Input.is_action_just_pressed('attack1'):
		attack(1)
	
	if Input.is_action_just_pressed('attack2'):
		attack(2)

	if Input.is_action_just_pressed('interact'):
		interact_area.request_interact()

	if Input.is_action_just_pressed('interact_secondary'):
		interact_area.request_interact_secondary()

func open_menu(current_visibility: bool):
	player_ui.menu.visible = !current_visibility
	
	immobile = player_ui.menu.visible
	player_ui.controls.visible = !player_ui.menu.visible

	if player_ui.menu.visible:
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

var one_shots: Array[String] = ["Sword_Attack", "PickUp_Table"]

func handle_animation(direction: Vector3):
	if animation_player.current_animation in one_shots:
		return

	if velocity.y == 0.0:
		if direction.x != 0.0 or direction.x != 0.0:
			animation_player.play("Jog_Fwd")
		else:
			animation_player.play("Idle")
	else:
		animation_player.play("Jump")

func shoot():
	var force = 100
	var pos = global_position
	var shoot_dir = get_shoot_direction()
	Global.shoot_ball.rpc_id(1, pos, shoot_dir, force)
	
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
	
	player_ui.hit_marker.show()
	await get_tree().create_timer(0.2).timeout
	player_ui.hit_marker.hide()

func attack(version: int):
	if sword_animation_player.current_animation.begins_with("arm_model_animations/swing_0"):
		return 
		
	if version == 1:
		sword_hurt_box.current_damage = 25
	elif version == 2:
		sword_hurt_box.current_damage = 50

	sensitivity = sensitivity * 0.25
	sword_hurt_box.bodies_hit.clear()
	animation_player.stop()
	animation_player.play("Sword_Attack")
	sword_animation_player.play("arm_model_animations/swing_0" + str(version))
	await sword_animation_player.animation_finished
	sword_animation_player.play("arm_model_animations/idle")
	sensitivity = DEFAULT_SENS

func update_is_holding(is_holding):
	if is_holding == false:
		sword_animation_player.play("arm_model_animations/idle")
		await get_tree().create_timer(0.3).timeout
		can_attack = true
	elif is_holding == true:
		can_attack = false
		sword_animation_player.play("arm_model_animations/hold")
	
	# Always play
	animation_player.play('PickUp_Table')
	await animation_player.animation_finished
	animation_player.play('Idle')
		
func update_interact_text(display_string = ""):
	if display_string != "":
		player_ui.label_interact.text = display_string + " (E)"
	else:
		player_ui.label_interact.text = ""
