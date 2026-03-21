extends RigidBody3D

@onready var area_3d: Area3D = $Area3D

var source: int

func _ready() -> void:
	area_3d.body_entered.connect(on_ball_hit)

func on_ball_hit(body: Node3D):
	if not is_multiplayer_authority():
		return

	if body.has_method('take_damage'):
		body.take_damage(10, source)
	
	queue_free()
