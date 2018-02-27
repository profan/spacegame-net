extends Node2D

# debug ui stuff
onready var peer_id_label = get_node("canvas/debug/metrics/labels/peer_id")
onready var turn_state_label = get_node("canvas/debug/metrics/labels/turn_state")
onready var turn_id_label = get_node("canvas/debug/metrics/labels/turn_id")
onready var turn_part_label = get_node("canvas/debug/metrics/labels/turn_part")
onready var turn_delay_label = get_node("canvas/debug/metrics/labels/turn_delay")
onready var turn_ms_label = get_node("canvas/debug/metrics/labels/turn_ms")

# game scene
onready var game = get_node("test_game")

const PASS_TURN = -1

# lockstep state
enum TurnState {
	RUNNING,
	WAITING
}

var turn_part = 0
var turn_number = -1
var turn_length = 16 # ticks

var turn_delay = 1 # turns
var turn_state = TurnState.WAITING
var turn_commands = {}
var turn_queue = []

signal on_exec_turn_command(cmd)

func pass_turn():
	return PASS_TURN
	
func send_queued_commands():
	
	var session = Game.get_session()
	
	for t in turn_queue:
		
		# always send to server, even if server
		# if Net.is_server(): session.send_command(Net.get_id(), t)
		# else: session.rpc_id(1, "send_command", Net.get_id(), t)
		session.rpc("send_command", Net.get_id(), t)
		
		# send to self locally first always
		_on_player_sent_command(session, Net.get_id(), t)
		
		if typeof(t.cmd) == TYPE_INT:
			#print("sent command: PASS_TURN for turn: %d" % (turn_number + turn_delay))
			pass
		else:
			# print("sent command: %s for turn: %d" % [t.cmd, turn_number + turn_delay])
			pass
			
	turn_queue.clear()

func send_turn_command(c):
	
	var turn_cmd = {
		turn = turn_number + turn_delay,
		cmd = c
	}
	
	turn_queue.append(turn_cmd)

func _send_turn_command(c):
	
	var turn_cmd = {
		turn = turn_number + turn_delay,
		cmd = c
	}
	
	var session = Game.get_session()
	session.rpc("send_command", Net.get_id(), turn_cmd)
	
	# send to self locally first always
	_on_player_sent_command(session, Net.get_id(), turn_cmd)
	
	# if typeof(turn_cmd.cmd) == TYPE_INT:
	# 	print("sent command: PASS_TURN for turn: %d" % (turn_number + turn_delay))
	# else:
	# 	print("sent command: %s for turn: %d" % [c, turn_number + turn_delay])

func _update_debug_ui():
	peer_id_label.text = "peer_id: %d" % Net.get_id()
	match turn_state:
		RUNNING: turn_state_label.text = "turn_state: RUNNING"
		WAITING: turn_state_label.text = "turn_state: WAITING"
	turn_id_label.text = "turn_id: %d" % turn_number
	turn_part_label.text = "turn_part: %d" % turn_part
	turn_delay_label.text = "turn_delay: %d" % turn_delay
	turn_ms_label.text = "turn_ms: %f" % (turn_length * (1000.0 / Engine.iterations_per_second))

func _ready():
	var session = Game.get_session()
	session.connect("on_player_sent_command", self, "_on_player_sent_command")
	session.connect("on_player_disconnected", self, "_on_player_disconnect")
	session.connect("on_connection_lost", self, "_on_server_lost")
	set_physics_process(true)
	
	# game hookup
	game.init_state(self)
	get_tree().paused = true

func _on_player_sent_command(session, pid, cmd):
	
	# print("[ID: %d] - cmd: %s calllback for pid: %d! (cmd for turn: %d)" % [Net.get_id(), cmd.cmd, pid, cmd.turn])
	# print("[ID: %d] > peers: %s" % [Net.get_id(), session.get_players()])
	
	if not cmd.has("turn"):
		printerr("INVALID COMMAND, DIDN'T CONTAIN TURN!")
		return
	
	if not turn_commands.has(cmd.turn):
		turn_commands[cmd.turn] = {}
	
	if not turn_commands[cmd.turn].has(pid):
		turn_commands[cmd.turn][pid] = []
	
	var cmds = turn_commands[cmd.turn][pid]
	if cmds.size() >= 1 and typeof(cmd.cmd) == TYPE_INT:
		pass # don't add a PASS then
	else:
		cmds.append(cmd.cmd)
	

func _on_player_disconnect(session, pid):
	pass

func _on_server_lost(session, reason):
	pass

func _all_turns_received(session, tid):
	
	var adjustment = 1 if not Net.is_server() else 0
	var peers = session.get_players()
	var confirmed_peers = 0
	
	for pid in peers:
		if pid != Net.get_id() and turn_commands.has(tid) and turn_commands[tid].has(pid):
			confirmed_peers += 1
	
	# if confirmed_peers != 0:
	# 	printt("[ID: %d] - peers:" % Net.get_id(), peers.size(), confirmed_peers)
	
	if confirmed_peers == peers.size() - adjustment:
		return true
	else:
		return false

func _check_pass_turn():
	# always send a PASS command, as a turn marker, if nothing else is sent
	if not turn_commands.has(turn_number + turn_delay):
		send_turn_command(pass_turn())
	elif turn_commands.has(turn_number + turn_delay):
		if not turn_commands[turn_number + turn_delay].has(Net.get_id()):
			send_turn_command(pass_turn())

func _physics_process(delta):
	
	var state_changed = false
	
	match turn_state:
		
		RUNNING:
			
			var session = Game.get_session()
			var peers = session.get_players()
			
			if turn_part == turn_length - 1:
				_check_pass_turn()
				send_queued_commands()
				
				if _all_turns_received(session, turn_number + turn_delay):
					_execute()
					turn_number += 1
					turn_part = 0
				else:
					turn_state = TurnState.WAITING
					state_changed = true
			else:
				turn_part += 1
			
		WAITING:
			
			if turn_number == -1:
				send_turn_command(pass_turn())
				send_queued_commands()
			
			var session = Game.get_session()
			var peers = session.get_players()
			
			# if all players have sent their turn command for given turn, switch to running
			if _all_turns_received(session, turn_number + turn_delay):
				turn_state = TurnState.RUNNING
				state_changed = true
	
	_update_debug_ui()
	
	# check if time to pause
	if state_changed:
		if turn_state == TurnState.RUNNING:
			get_tree().paused = false
			print("UNPAUSE")
		elif turn_state == TurnState.WAITING:
			get_tree().paused = true
			print("PAUSE")
	

func _execute():
	
	if turn_number == -1: return
	
	# execute all commands for turn
	var turn_cmds = turn_commands[turn_number]
	for pid in turn_cmds:
		var cmds = turn_cmds[pid]
		for cmd in cmds:
			if typeof(cmd) != TYPE_INT:
				# print("[ID: %d] - [T: %d] executing: %s" % [Net.get_id(), turn_number, cmd])
				emit_signal("on_exec_turn_command", cmd)
	
	# clear turn and its commands
	turn_commands.erase(turn_number)
	