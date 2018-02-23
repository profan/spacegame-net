extends Node

var my_info = {}
var peer_info = {}

signal on_player_connected(s, player_id)
signal on_player_disconnected(s, player_id)
signal on_player_sent_command(s, player_id, command)
signal on_connection_lost(s, reason)

func _init():
	Net.connect("on_peer_connected", self, "_on_peer_connected")
	Net.connect("on_peer_disconnected", self, "_on_peer_disconnected")
	Net.connect("on_connection_lost", self, "_on_connection_lost")

func start_server(port):
	pass

func join_server(ip, port):
	pass

func is_server():
	get_tree().is_network_server()

func get_host_port():
	Net.get_host_port()

func register_myself():
	rpc("register_player", Net.get_id(), my_info)

remote func register_player(id, info):
	peer_info[id] = info
	if Net.is_server():
		rpc_id(id, "register_player", 1, my_info)
		for pid in peer_info:
			rpc_id(id, "register_player", pid, peer_info[pid])
	emit_signal("on_player_connected", self, id)

remote func send_command(id, cmd):
	if Net.is_server():
		rpc_id(id, "send_command", 1, cmd)
		for pid in peer_info:
			rpc_id(id, "send_command", pid, cmd)
	emit_signal("on_player_sent_command", self, id, cmd)

func _on_peer_connected(id):
	pass

func _on_peer_disconnected(id):
	emit_signal("on_player_disconnected", self, id)
	peer_info.erase(id)

func _on_connection_lost():
	emit_signal("on_connection_lost", self, OK)