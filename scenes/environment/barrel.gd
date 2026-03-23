class_name InteractCarry
extends InteractComponent

@export var carry_component: CarryComponent
@export var tracked_velocity: Vector3
@export var tracked_angular: Vector3

@export var tracked_position: Transform3D

func _ready():
	super()
	if not is_multiplayer_authority():
		#self.set_collision_layer_value(1, false)
		self.freeze = true

# NOTE: This is an RPC. InteractArea calls it as such (rpc_id)
func interact(..._args):
	if owner_peer_id == 0:
		owner_peer_id = multiplayer.get_remote_sender_id()
	# Drop it if the owner activates again
	elif owner_peer_id == multiplayer.get_remote_sender_id():
		owner_peer_id = 0
	
func interact_secondary(..._args):
	owner_peer_id = 0
	carry_component.throw(100)

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

		#if owner_peer_id != 0 and owner_player == null:
			#owner_peer_id = 0
			#return

		if owner_peer_id != 0 and owner_player:
			carry_component.get_carry_location(owner_player, state)
