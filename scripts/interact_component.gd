extends Node3D

# Detects and connects interact actions 

class_name InteractComponent

signal signal_interact

@export var label: = 'Interact'

# Enum of the type of pickup or activate

var component: Node3D 


# TODO: better way to search, or just use export.
func _ready() -> void:
	pass
	#for child in get_children():
		#if child is PickupComponent:
			#print(child)
			#
		#if child is ActivateComponent:
			#print(child)
