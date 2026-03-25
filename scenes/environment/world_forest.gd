extends Node3D

class_name WorldForest


@onready var spawn_container: Node3D = %SpawnContainer
@onready var timer_target: Timer = %TimerTarget

const TARGET = preload("uid://w08mo482g7si")

func _ready() -> void:
	Global.forest = self
	Global.spawn_container = spawn_container
	timer_target.timeout.connect(spawn_target)

func spawn_target():
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('Targets') < 20:
		for i in get_tree().get_node_count_in_group('Players'):
			var new_target = TARGET.instantiate()
			var rand_x = randf_range(-25.0, 25.0)
			var rand_z = randf_range(-25.0, 25.0)
			new_target.position = Vector3(rand_x, 1.5, rand_z)
			spawn_container.add_child(new_target, true)
