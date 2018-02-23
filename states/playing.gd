extends Node2D

enum Command {
	PASS,
	SELECT_UNITS,
	MOVE_UNITS
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

func _ready():
	var session = Game.get_session()
	session.connect("on_player_sent_command", self, "_on_player_sent_command")
	session.connect("on_player_disconnected", self, "_on_player_disconnect")

func _on_player_sent_command(player, cmd):
	pass

func _on_player_disconnect(player):
	pass

func _fixed_process():
	pass