extends Control

var PlayerElement = load("res://space-game/player_default.tscn")

onready var players = get_node("players/elements/list")

func _ready():
	Game.connect("match_started", self, "_on_match_started")

func _on_match_started():
	
	var session = Game.get_session()
	var peers = session.get_players()
	
	if Net.is_server():
		var new_elem = PlayerElement.instance()
		players.add_child(new_elem)
		new_elem.set_colour(session.my_info.colour)
		new_elem.set_name(session.my_info.nick)
		new_elem.name = "1"
	
	for pid in peers:
		
		var color = "green" if Net.get_id() == pid else "fuchsia"
		
		var new_elem = PlayerElement.instance()
		players.add_child(new_elem)
		new_elem.set_colour(peers[pid].colour)
		new_elem.set_name(peers[pid].nick)
		new_elem.name = str(pid)
		
	players.queue_sort()