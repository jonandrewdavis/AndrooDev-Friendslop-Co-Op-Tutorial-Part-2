extends Control


const HOLE_PUNCHING_COMPLIANCE_TEXT: Dictionary[TubeNetworkDiagnosisPeer.Compliance, String] = {
	TubeNetworkDiagnosisPeer.Compliance.UNKNOWN: "Unknown",
	TubeNetworkDiagnosisPeer.Compliance.YES: "likely to succeed",
	TubeNetworkDiagnosisPeer.Compliance.NO: "likely to fail",
}
const HOLE_PUNCHING_COMPLIANCE_COLOR: Dictionary[TubeNetworkDiagnosisPeer.Compliance, Color] = {
	TubeNetworkDiagnosisPeer.Compliance.UNKNOWN: Color.BEIGE,
	TubeNetworkDiagnosisPeer.Compliance.YES: Color.PALE_GREEN,
	TubeNetworkDiagnosisPeer.Compliance.NO: Color.CRIMSON,
}

@export var inspector: EditorTubeClientPanel

var client: TubeClient:
	set(x):
		client = x
		
		if not is_instance_valid(client):
			return
		
		if is_instance_valid(client_label):
			client_label.text = client.name
		
		if is_instance_valid(context_label):
			context_label.text = client.context.resource_name
		
		if is_instance_valid(app_id_label):
			app_id_label.text = client.context.app_id
		
		if is_instance_valid(root_node_label):
			root_node_label.text = client.multiplayer_root_node.get_path()
		
		detect_nat()


var network_diagnosis_peer := TubeNetworkDiagnosisPeer.new(4443)

@onready var client_label: Label = %ClientLabel
@onready var context_label: Label = %ContextLabel
@onready var app_id_label: Label = %AppIdLabel
@onready var root_node_label: Label = %RootNodeLabel
@onready var nat_detection_label: Label = %NATDetectionLabel


func _ready() -> void:
	network_diagnosis_peer.warning_raised.connect(
		_on_network_diagnosis_peer_warning_raised
	)
	network_diagnosis_peer.nat_hole_punching_compliance_updated.connect(
		_on_network_diagnosis_peer_nat_hole_punching_compliance_updated
	)


func _process(delta: float):
	network_diagnosis_peer._process(delta)


func _on_network_diagnosis_peer_warning_raised(message: String):
	if is_instance_valid(inspector):
		inspector.add_message_item_control("Network diagnosis: " + message).warning()


func _on_network_diagnosis_peer_nat_hole_punching_compliance_updated(compliance: TubeNetworkDiagnosisPeer.Compliance):
	if is_instance_valid(nat_detection_label):
		nat_detection_label.text = HOLE_PUNCHING_COMPLIANCE_TEXT[compliance]
		nat_detection_label.modulate = HOLE_PUNCHING_COMPLIANCE_COLOR[compliance]


func _on_nat_detection_button_pressed() -> void:
	detect_nat()


func detect_nat():
	if OS.get_name() == "Web":
		if is_instance_valid(inspector):
			inspector.add_message_item_control("NAT hole punching detection is not available on Web").warning()
		return
	
	if not is_instance_valid(client):
		inspector.add_message_item_control("NAT hole punching detection needs a tube client set on inspector").warning()
		return
	
	if len(client.context.stun_servers_urls) < 2:
		if is_instance_valid(inspector):
			inspector.add_message_item_control("NAT hole punching detection can only be done with 2 or more STUN urls").warning()
		return
	
	network_diagnosis_peer.start_nat_hole_punching_detection(client.context.stun_servers_urls)
