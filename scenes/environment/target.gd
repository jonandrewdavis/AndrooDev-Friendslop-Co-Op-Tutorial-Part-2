extends CharacterBody3D

@export var health := 100

func _ready():
	add_to_group('Targets')

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
		queue_free()
		player_to_notify.register_hit.rpc_id(source, true)
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)
