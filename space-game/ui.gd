extends Control

var PlayerElement = load("res://space-game/player_default.tscn")

onready var players = get_node("players/elements/list")

var update_ping_ctr = 0
var update_ping_interval = 10

func _ready():
	Game.connect("match_started", self, "_on_match_started")

func _physics_process(delta):
	update_ping_ctr += 1
	if update_ping_ctr == update_ping_interval:
		var session = Game.get_session()
		session.send_pings()
		update_ping_ctr = 0
		_update_pings()

func _update_pings():
	var session = Game.get_session()
	for pid in session.get_players():
		if pid != Net.get_id():
			if session.pings.has(pid):
				var player_elem = players.get_node(str(pid))
				player_elem.set_ping(session.pings[pid].last)

func _on_match_started():
	
	# start updating pingas
	set_physics_process(true)
	
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