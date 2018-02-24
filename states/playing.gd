extends Node2D

# debug ui stuff
onready var turn_state_label = get_node("canvas/debug/metrics/labels/turn_state")
onready var turn_id_label = get_node("canvas/debug/metrics/labels/turn_id")
onready var turn_part_label = get_node("canvas/debug/metrics/labels/turn_part")
onready var turn_delay_label = get_node("canvas/debug/metrics/labels/turn_delay")

enum Command {
	PASS,
	SELECT_UNITS,
	MOVE_UNITS
}

# lockstep state
enum TurnState {
	RUNNING,
	WAITING	
}

var turn_part = 0
var turn_number = -1
var turn_length = 4 # ticks

var turn_delay = 1 # turns
var turn_state = TurnState.WAITING
var turn_commands = {}

# local
var turn_queue = {}

func pass_turn():
	return {
		type = Command.PASS
	}

func select_units(units):
	return {
		type = Command.SELECT_UNITS,
		units = units
	}

func move_units(units, x, y):
	return {
		type = Command.MOVE_UNITS,
		units = units,
		x = x,
		y = y
	}

func exec_turn_command(c):
	pass

func send_turn_command(c):
	
	var turn_cmd = {
		turn = turn_number + turn_delay,
		cmd = c
	}
	
	var session = Game.get_session()
	session.rpc("send_command", Net.get_id(), turn_cmd)
	
	# execute also for self MAYBE? HACK
	_on_player_sent_command(session, Net.get_id(), turn_cmd)

func _update_debug_ui():
	match turn_state:
		RUNNING: turn_state_label.text = "turn_state: RUNNING"
		WAITING: turn_state_label.text = "turn_state: WAITING"
	turn_id_label.text = "turn_id: %d" % turn_number
	turn_part_label.text = "turn_part: %d" % turn_part
	turn_delay_label.text = "turn_delay: %d" % turn_delay

func _ready():
	var session = Game.get_session()
	session.connect("on_player_sent_command", self, "_on_player_sent_command")
	session.connect("on_player_disconnected", self, "_on_player_disconnect")
	set_physics_process(true)

func _on_player_sent_command(session, pid, cmd):
	
	if not cmd.has("turn"):
		printerr("INVALID COMMAND, DIDN'T CONTAIN TURN!")
		return
		
	if not turn_commands.has(cmd.turn):
		turn_commands[cmd.turn] = {}
	
	if not turn_commands[cmd.turn].has(pid):
		turn_commands[cmd.turn][pid] = []
	
	turn_commands[cmd.turn][pid].append(cmd)
	

func _on_player_disconnect(pid):
	pass

func _all_turns_received(session, tid):
	
	var peers = session.get_players()
	var confirmed = {}
	
	for pid in peers:
		if turn_commands[tid].has(pid):
			confirmed[pid] = true
	
	if confirmed.size() == peers.size():
		return true
	else:
		return false

func _physics_process(delta):
	
	match turn_state:
		
		TurnState.RUNNING:
			
			var session = Game.get_session()
			var peers = session.get_players()
			
			# always send a PASS command, as a turn marker, even if nothing else is sent
			send_turn_command(pass_turn())
			
			# if all players have not sent their turn command, switch to waiting
			if turn_part == 0:
				if _all_turns_received(session, turn_number):
					_execute()
				else:
					turn_state = TurnState.WAITING
			
			turn_part += 1
			if turn_part == turn_length - 1:
				turn_number += 1
				turn_part = 0
			
		TurnState.WAITING:
			
			if turn_number == -1: 
				send_turn_command(pass_turn())
				turn_number = 0
			
			var session = Game.get_session()
			var peers = session.get_players()
			
			# if all players have sent their turn command for given turn, switch to running
			if _all_turns_received(session, turn_number):
				turn_state = TurnState.RUNNING
			
	_update_debug_ui()

func _execute():
	
	# execute all commands for turn
	var turn_cmds = turn_commands[turn_number]
	for pid in turn_cmds:
		var cmds = turn_cmds[pid]
		for cmd in cmds:
			exec_turn_command(cmd)
	
	# clear turn and its commands
	turn_commands.erase(turn_number)
	