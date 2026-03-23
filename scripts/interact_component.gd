@abstract
extends Node3D
class_name InteractComponent

@export var display_string: String
@export var label: Label3D

@export var owner_peer_id: int = 0: set = _set_owner_peer_id	
var owner_player: Player = null

@abstract
@rpc('any_peer', 'call_local')
func interact(...args)

@abstract
@rpc('any_peer', 'call_local') 
func interact_secondary(...args)

func _ready() -> void:
	if not display_string:
		printerr("No display name for interactable", name)
		
	if not label:
		printerr("No label for interactable", name)

func _set_owner_peer_id(id):
	owner_peer_id = id
	if id == 0:
		if owner_player:
			owner_player.interact_area.set_current_interactable.rpc_id(owner_player.get_multiplayer_authority(), null)
			owner_player = null
	else:
		owner_player = Global.get_player(id)
		owner_player.interact_area.set_current_interactable.rpc_id(owner_player.get_multiplayer_authority(), self.get_path())
