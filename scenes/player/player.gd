extends CharacterBody3D

class_name Player

@export var sensitivity: float = 0.002

const SPEED = 5.0
const DECELERATION = .1
const JUMP_VELOCITY = 4.5

@export var LOOK_SPEED = .01

@onready var camera_3d: Camera3D = %Camera3D
@onready var head: Node3D = %Head
@onready var nameplate: Label3D = %Nameplate

@onready var menu: Control = %Menu
@onready var button_leave: Button = %ButtonLeave
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession

@onready var canvas_layer: CanvasLayer = %CanvasLayer
@onready var hit_marker: Label = %HitMarker

@onready var sound_hit: AudioStreamPlayer = %SoundHit
@onready var sound_ping: AudioStreamPlayer = %SoundPing

var immobile := false


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	menu.hide()
	add_to_group("Players")
	nameplate.text = name
	hit_marker.hide()
	
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		canvas_layer.hide()
		return
	
	if Global.username: nameplate.text = Global.username
	
	label_session.text = Network.tube_client.session_id
	camera_3d.current = true
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
		
	var look_vector = Input.get_vector("lookleft","lookright","lookdown","lookup")

	if look_vector.length() > 0:
		head.rotate_y(look_vector.x*LOOK_SPEED)	
		camera_3d.rotate_x(look_vector.y*LOOK_SPEED)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func open_menu(current_visibility: bool):
	menu.visible = !current_visibility
	
	immobile = menu.visible

	if menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (camera_3d.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("backward"):
		velocity = direction*SPEED
	else:
		velocity = velocity.normalized() * max((velocity.length() - DECELERATION),0)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	
	if immobile:
		direction = Vector3.ZERO


	move_and_slide()
	
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
	
	hit_marker.show()
	await get_tree().create_timer(0.2).timeout
	hit_marker.hide()
