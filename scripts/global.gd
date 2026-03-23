extends Node

var username := ''

var forest: Node3D
var spawn_container: Node3D

var BALL = load("uid://c1yny3sauy8yu")

@rpc("any_peer", "call_local")
func shoot_ball(pos, dir, force):
	var new_ball: RigidBody3D = BALL.instantiate()
	new_ball.source = multiplayer.get_remote_sender_id()
	new_ball.position = pos + Vector3(0.0, 1.5, 0.0) + (dir * 1.2)
	spawn_container.add_child(new_ball, true)
	new_ball.apply_central_impulse(dir * force)

func get_player(peer_id: int) -> Player:
	var player_to_find: Player
	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(peer_id):
			player_to_find = current_player
			break
	# TODO: Handle not found?
	return player_to_find
