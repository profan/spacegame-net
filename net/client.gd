extends Node

const DEFAULT_HOST_PORT = 27015
const DEFAULT_MAX_CLIENTS = 32

enum Type {
	None,
	Server,
	Client
}

enum Status {
	Connected,
	Connecting,
	Disconnected
}

var enet_peer
var enet_peer_type
var enet_peer_status

var host_peer_ip
var host_peer_port

# server only signals
signal on_creation_successful
signal on_creation_failure(reason)

# client and server signals
signal on_peer_connected(id)
signal on_peer_disconnected(id)

# client only, after connected
signal on_connection_lost

# client only, when connecting
signal on_connection_successful
signal on_connection_failure

func _ready():
	pass

func _on_peer_connected(id):
	emit_signal("on_peer_connected", id)

func _on_peer_disconnected(id):
	emit_signal("on_peer_disconnected", id)

# server stuff
func is_server():
	return enet_peer_type == Type.Server

func get_id():
	return enet_peer.get_unique_id()

func get_type():
	return enet_peer_type

func get_status():
	return enet_peer_status

func get_host_ip():
	return host_peer_ip

func get_host_port():
	return host_peer_port

func close_connection():
	enet_peer_type = Type.None
	enet_peer_status = Status.Disconnected
	enet_peer.close_connection()
	enet_peer = null
	
	# deregister from tree
	get_tree().call_deferred("set_network_peer", null)

func start_server(host_ip, port, max_clients = 32):
	
	enet_peer = NetworkedMultiplayerENet.new()
	enet_peer.connect("peer_connected", self, "_on_peer_connected")
	enet_peer.connect("peer_disconnected", self, "_on_peer_disconnected")
	
	var error = enet_peer.create_server(port, max_clients)
	enet_peer_type = Type.Server
	host_peer_ip = "localhost"
	host_peer_port = port
	
	if error == OK:
		emit_signal("on_creation_successful")
		enet_peer_status = Status.Connected
		# register with tree
		get_tree().set_network_peer(enet_peer)
	else:
		emit_signal("on_creation_failure", error)
		enet_peer_status = Status.Disconnected	

func join_server(host_ip, port):
	
	enet_peer = NetworkedMultiplayerENet.new()
	enet_peer.connect("peer_connected", self, "_on_peer_connected")
	enet_peer.connect("peer_disconnected", self, "_on_peer_disconnected")
	
	enet_peer.create_client(host_ip, port)
	enet_peer_type = Type.Client
	host_peer_ip = host_ip
	host_peer_port = port
	enet_peer_status = Status.Connecting
	enet_peer.connect("connection_succeeded", self, "_on_connection_successful")
	enet_peer.connect("connection_failed", self, "_on_connection_failure")
	enet_peer.connect("server_disconnected", self, "_on_server_lost")
	
	# register with tree
	get_tree().set_network_peer(enet_peer)

# specific to "client"
func _on_server_lost():
	enet_peer_type = Type.None
	enet_peer_status = Status.Disconnected
	emit_signal("on_connection_lost")

# intermediate status functions for client joining a potential server
func _on_connection_successful():
	enet_peer_status = Status.Connecting
	emit_signal("on_connection_successful")

func _on_connection_failure():
	emit_signal("on_connection_failure")
