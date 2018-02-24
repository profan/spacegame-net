extends Node2D

# scenes/resources
var Entity = load("res://entity.tscn")

# local refs
onready var ents = get_node("entities")

enum Command {
	CREATE_ENTITY
}

func create_entity(x, y):
	return {
		type = Command.CREATE_ENTITY,
		x = x,
		y = y
	}

var manager

func init_state(m):
	m.connect("on_exec_turn_command", self, "_on_exec_turn_command")
	manager = m

func _ready():
	var session = Game.get_session()
	session.connect("on_connection_lost", self, "_on_server_lost")

func _on_server_lost(session, reason):
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()

func _on_exec_turn_command(c):
	match c.type:
		CREATE_ENTITY:
			var new_ent = Entity.instance()
			ents.add_child(new_ent)
			new_ent.position.x = c.x
			new_ent.position.y = c.y
	

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("mouse_left"):
			var mouse_pos = get_global_mouse_position()
			var create_ent_cmd = create_entity(mouse_pos.x, mouse_pos.y)
			manager.send_turn_command(create_ent_cmd)