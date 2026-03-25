extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $AnimationLibrary_Godot_Standard/AnimationPlayer
@onready var mannequin: MeshInstance3D = $AnimationLibrary_Godot_Standard/Rig/Skeleton3D/Mannequin
@onready var timer_damage: Timer = %TimerDamage

@export var health := 100

var is_dying := false
var is_damaged := false

func _ready():
	add_to_group('Targets')
	animation_player.playback_default_blend_time = 0.2
	
	var material: StandardMaterial3D = mannequin.get_active_material(0)
	var new_material = material.duplicate()
	new_material.albedo_color = Color.DARK_MAGENTA
	mannequin.set_surface_override_material(0, new_material)
	look_at(target)
	
	if multiplayer.is_server():
		timer_damage.wait_time = 2.5
		timer_damage.timeout.connect(func(): Global.damage_crystal(10))

func take_damage(damage: int, source: int):
	if is_dying:
		return 
		
	var next_health = health - damage

	var player_to_notify: Player
	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(source):
			player_to_notify = current_player
			break
	
	if not player_to_notify:
		return
	
	if next_health <= 0:
		death(source)
		player_to_notify.register_hit.rpc_id(source, true )
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)
		is_damaged = true
		animation_player.play("Hit_Chest")
		await animation_player.animation_finished
		is_damaged = false

func death(source: int):
	Global.update_score_for(source)
	set_collision_layer_value(1, false)
	is_dying = true
	animation_player.play("Death01")
	await animation_player.animation_finished
	queue_free()

var SPEED := 2.0
var target := Vector3.ZERO
var direction := Vector3.ZERO

func _physics_process(delta: float) -> void:
	if is_dying or is_damaged or not is_multiplayer_authority():
		return 

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if position.distance_to(target) > 3.0:
		direction = position.direction_to(target)
		animation_player.play("Walk_Formal")
	else:
		direction = Vector3.ZERO
		animation_player.play("Spell_Simple_Shoot")
		start_crystal_damage()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func start_crystal_damage():
	if timer_damage.is_stopped():
		timer_damage.start()
