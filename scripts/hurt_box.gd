extends Area3D

class_name HurtBox

func _ready() -> void:
	body_entered.connect(on_body_entered)
	
var bodies_hit: Array[Node3D] = []	
var current_damage: int

func on_body_entered(body: Node3D):
	if body.has_method('take_damage'):
		if bodies_hit.has(body):
			return 
			
		bodies_hit.append(body)
		replicate_take_damage.rpc_id(1, body.get_path(), current_damage)

@rpc("any_peer", "call_local")
func replicate_take_damage(path: NodePath, given_damage: int):
	var target_to_hurt = get_node_or_null(path)
	if target_to_hurt:
		target_to_hurt.take_damage(given_damage, multiplayer.get_remote_sender_id())
