extends Area3D
class_name InteractArea

# Detects and tracks if we have a interactable.
# issues input to the interactable (pick up / activate agnostic)

var current_interactable: InteractComponent

signal show_interactable_label(label)

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(body: Node3D):
	if body is InteractComponent:
		show_interactable_label.emit(body.label)
		print("It's a body")
		# signal interact
		
func on_body_exited(_body: Node3D):
	if get_overlapping_bodies().size() == 0:
		show_interactable_label.emit('')
		return
	
	var interactable_in_range = false
	for body in get_overlapping_bodies():
		if body is InteractComponent:
			show_interactable_label.emit(body.label)
			interactable_in_range = true
	
	if interactable_in_range == false:
		show_interactable_label.emit('')
