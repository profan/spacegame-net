extends Node

var Session = load("res://session.gd")

const Scenes = {
	
	# Scenes
	MAIN = "res://menus/main_menu.tscn",
	LOBBY = "res://menus/menu_lobby.tscn",
	OPTIONS = "res://menus/options.tscn",
	
	# Intermediate States
	CONNECTING = "res://states/connecting.tscn",
	CREATING = "res://states/creating.tscn",
	
	# Game
	PLAYING = "res://states/playing.tscn"
	
}

var session

signal session_started
signal session_closed

func _ready():
	pass

func start_session():
	var new_session = Session.new()
	session = new_session
	add_child(session)
	session.name = "session"
	emit_signal("session_started")
	return session

func close_session():
	emit_signal("session_closed")
	Net.close_connection()
	if session != null:
		remove_child(session)
		session.queue_free()
		session = null

func get_session():
	return session