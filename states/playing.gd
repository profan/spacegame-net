extends Node2D

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

var turn_number = 0
var turn_length = 4 # ticks

var turn_delay = 4 # turns
var turn_state = TurnState.WAITING
var turn_commands = {}

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

func _ready():
	var session = Game.get_session()
	session.connect("on_player_sent_command", self, "_on_player_sent_command")
	session.connect("on_player_disconnected", self, "_on_player_disconnect")

func _on_player_sent_command(session, pid, cmd):
	
	if not turn_commands.has(pid):
		turn_commands[pid] = []
	
	turn_commands[pid] = cmd
	

func _on_player_disconnect(pid):
	pass

func _fixed_process():
	
	match turn_state:
		
		TurnState.RUNNING:
			pass
			
		TurnState.WAITING:
			pass
			

func _execute():
	pass