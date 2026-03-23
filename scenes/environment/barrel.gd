extends InteractComponent

@export var carry_component: CarryComponent
@export var tracked_velocity: Vector3
@export var tracked_angular: Vector3

@export var tracked_position: Vector3
@export var tracked_rotation: Vector3

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

func _physics_process(_delta: float) -> void:
	pass
	#if owner_peer_id != 0 and owner_player == null:
		#owner_peer_id = 0
		#return
		#
	#if owner_peer_id != 0 and owner_player:
		#carry_component.get_carry_location(owner_player)

		#var target_position =  
		#var target_dir: Vector3 = (global_transform.origin - target_position).normalized()
		#self.linear_velocity = (lerp(self.linear_velocity, target_dir * 10, 0.5))
	#if parent_body.global_position.distance_to(carry_location) > carry_break_dist:
		#parent_body.set_linear_velocity(Vector3.ZERO)
		#parent_body.owner_peer_id = 0 # Drop it by setting to 0. Setters will take care of the RPCs
		#return 
#func _integrate_forces(state: PhysicsDirectBodyState3D):
	#if is_multiplayer_authority(): 
		#tracked_position = position
	#else:
		#position = position.slerp(tracked_position, 0.5)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if owner_peer_id != 0 and owner_player == null:
		owner_peer_id = 0
		return

	if owner_peer_id != 0 and owner_player:
		carry_component.get_carry_location(owner_player, state)
	
		
	if is_multiplayer_authority():
		tracked_position = position
	else:
		position.lerp(tracked_position, 0.5)
