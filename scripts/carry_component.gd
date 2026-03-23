class_name InteractCarry
extends InteractComponent

@export var tracked_velocity: Vector3
@export var tracked_angular: Vector3
@export var tracked_position: Transform3D

@export var OFFSET_FORWARD := 1.5

func _ready():
	super()
	if not is_multiplayer_authority():
		self.set_collision_layer_value(1, false)
		self.freeze = true
		self.freeze_mode = RigidBody3D.FreezeMode.FREEZE_MODE_KINEMATIC

# NOTE: This is an RPC. InteractArea calls it as such (rpc_id)
func interact(..._args):
	if owner_peer_id == 0:
		owner_peer_id = multiplayer.get_remote_sender_id()
	# Drop it if the owner activates again
	elif owner_peer_id == multiplayer.get_remote_sender_id():
		owner_peer_id = 0
	
func interact_secondary(..._args):
	var foward_dir = -owner_player.interact_area.global_transform.basis.z
	owner_peer_id = 0
	# TODO: This cuts the speed before toss. Determine if we want to preserve some momentum
	# NOTE: call with 'set_linear_velocity' skips a type check here. We are sure it's a RigidBody3D.
	self.call('set_linear_velocity', Vector3(0.0, 0.0, 0.0)) # Remove all velocity
	self.call('set_angular_velocity', Vector3(0.0, 0.0, 0.0)) # Remove all velocity
	# NOTE: Not sure if call_deferred helps, but it might help velocity to get cut first.
	self.call_deferred('apply_central_impulse', foward_dir * 10 * self.mass) 

# TODO: Most of the observable jitter comes from camera.
# https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/advanced_physics_interpolation.html#cameras
func _integrate_forces(state: PhysicsDirectBodyState3D):
	if not is_multiplayer_authority():
		var lerp_speed = 30.0 * state.step
		state.transform = state.transform.interpolate_with(tracked_position, lerp_speed)
		state.linear_velocity = tracked_velocity
		state.angular_velocity = tracked_angular
	else:		
		tracked_position = state.transform
		tracked_velocity = state.linear_velocity
		tracked_angular = state.angular_velocity

		if owner_peer_id != 0 and owner_player == null:
			owner_peer_id = 0
			return

		if owner_peer_id != 0 and owner_player:
			get_carry_location(state)

func get_carry_location(state):	
	var foward_dir = -owner_player.interact_area.global_transform.basis.z
	var offset_factor = foward_dir * OFFSET_FORWARD
	var carry_location: Vector3 = owner_player.interact_area.global_position + offset_factor
	
	var a = global_position # here
	var b = carry_location # there
	state.linear_velocity = (lerp(state.linear_velocity, (b - a) * 10, 30 * state.step))
