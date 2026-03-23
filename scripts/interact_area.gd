extends Area3D
class_name InteractArea

# Detects and tracks if we have a interactable.
# issues input to the interactable (pick up / activate agnostic)
var current_interactable: InteractComponent

signal signal_display_text(label)
signal signal_is_holding(is_holding)

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(body: Node3D):
	if body is InteractComponent:
		signal_display_text.emit(body.display_string)
		print("It's a body")
		# signal interact
		
func on_body_exited(_body: Node3D):
	if get_overlapping_bodies().size() == 0:
		signal_display_text.emit('')
		return
	
	var interactable_in_range = false
	for body in get_overlapping_bodies():
		if body is InteractComponent:
			signal_display_text.emit(body.display_string)
			interactable_in_range = true
	
	if interactable_in_range == false:
		signal_display_text.emit('')

func request_interact():
	if current_interactable:
		current_interactable.interact.rpc_id(1)
		return 
	# TODO: if we already have current intereact,abel, rop it, and return
	for body in get_overlapping_bodies():
		if body is InteractComponent:
			# TODO: Get information about the type of interact we're about to do!
			body.interact.rpc_id(1)
			return

func request_interact_secondary():
	if current_interactable:
		current_interactable.interact_secondary.rpc_id(1)
		return

	for body in get_overlapping_bodies():
		if body is InteractComponent:
			# TODO: Get information about the type of interact we're about to do from the interactable?
			body.interact_secondary.rpc_id(1)
			return

## Called from the server to the player who requested an activation
@rpc("any_peer", "call_local", 'reliable')
func set_current_interactable(path):
	if path: 
		current_interactable = get_node(path)
		signal_is_holding.emit(true)
	else:
		current_interactable = null
		signal_is_holding.emit(false)
