extends Node3D
class_name CarryComponent

# TODO: Calculate offset from Collision Shape?
@export var OFFSET_FORWARD := 1.2
@export var throw_enabled := true
@export var carry_break_dist := 4.5

@onready var parent_body: RigidBody3D = get_parent()

#func _ready():
	#if not is_multiplayer_authority():
		#parent_body.set_physics_process_internal(false)
		#parent_body.set_process(false)
		#parent_body.set_physics_process(false)

func throw(impulse):
	# TODO: Determine if we want to preserve some momentum
	parent_body.set_angular_velocity(Vector3(0.0, 0.0, 0.0)) # Remove all velocity before throw
	parent_body.set_linear_velocity(Vector3(0.0, 0.0, 0.0)) # Remove all velocity before throw
	# WARNING: Not sure if call_deferred helps, but it might help velocity to get cut first.
	parent_body.apply_central_impulse(impulse) 

func get_carry_location(owner_player: Player, state: PhysicsDirectBodyState3D) -> void:
	var foward_dir = -owner_player.interact_area.global_transform.basis.z
	var offset_factor = foward_dir * OFFSET_FORWARD
	var carry_location: Vector3 = owner_player.interact_area.global_position + offset_factor
	
	var a = parent_body.global_position # here
	var b = carry_location # there
	state.linear_velocity = (lerp(state.linear_velocity, (b - a) * 10, 0.5))
