extends CharacterBody3D

@export var health := 100
@export var animation_player: AnimationPlayer
@export var mesh: MeshInstance3D
@onready var crystal_timer: Timer = %CrystalTimer

var is_hurt := false
var is_dying := false

func _ready():
	animation_player.playback_default_blend_time = 0.2
	add_to_group('Targets')
	look_at(goal_position)

	if multiplayer.is_server():
		crystal_timer.wait_time = 2.5
		crystal_timer.timeout.connect(func(): Global.damage_crystal(10))

func take_damage(damage: int, source: int):
	var next_health = health - damage
	
	var player_to_notify: Player
	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(source):
			player_to_notify = current_player
			break
	
	if not player_to_notify:
		return
	
	if next_health <= 0:
		player_to_notify.register_hit.rpc_id(source, true)
		death(source)
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)
		is_hurt = true
		animation_player.play("Hit_Chest")
		await animation_player.animation_finished
		is_hurt = false

func death(source):
	Global.update_score_for(source)
	set_collision_layer_value(1, false)
	is_dying = true
	animation_player.play("Death01")
	await animation_player.animation_finished
	queue_free()


var SPEED := 2.0
var direction := Vector3.ZERO
var goal_position := Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if is_dying or is_hurt:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if position.distance_to(goal_position) > 3.0: 
		direction = position.direction_to(goal_position)
		animation_player.play("Walk_Formal")
	else:
		direction = Vector3.ZERO
		animation_player.play("Spell_Simple_Shoot")
		if crystal_timer.is_stopped():
			crystal_timer.start()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
