extends Node2D

# game gui
onready var canvas = get_node("canvas")

# scenes/resources
var Entity = load("res://space-game/entity.tscn")
var SeekingEntity = load("res://space-game/seeking-entity.tscn")
var Building = load("res://space-game/building.tscn")

# local refs
onready var camera = get_node("camera")
onready var selector = get_node("selection")
onready var ents = get_node("entities")
onready var blds = get_node("buildings")

enum Command {
	CREATE_ENTITY,
	MOVE_ENTITIES
}

func create_entity(x, y):
	return {
		type = Command.CREATE_ENTITY,
		x = x,
		y = y
	}

func move_entities(ents, x, y):
	return {
		type = Command.MOVE_ENTITIES,
		ents = ents,
		x = x,
		y = y
	}

var manager

# entity ids
var id_counter = -1

func init_state(m):
	m.connect("on_exec_turn_command", self, "_on_exec_turn_command")
	manager = m

func init_with_args(args):
	var chat_panel = args[0]
	canvas.add_child(chat_panel)

func _ready():
	
	var session = Game.get_session()
	session.connect("on_connection_lost", self, "_on_server_lost")
	
	# selection box stuff
	selector.connect("on_action_perform", self, "_on_action_perform")
	
	# create initial building yes
	var some_owner = {colour = ColorN("fuchsia")}
	var new_building = Building.instance()
	new_building.create_building(some_owner, Vector2(16, 16))
	blds.add_child(new_building)

func _on_action_perform(bodies, x, y):
	
	var ids = []
	for b in bodies:
		ids.append(b.name)
	
	var move_order = move_entities(ids, x, y)
	manager.send_turn_command(move_order, manager.turn_delay)

func _on_server_lost(session, reason):
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()
	
func _fresh_id():
	id_counter += 1
	return id_counter

func _on_exec_turn_command(pid, c):
	match c.type:
		CREATE_ENTITY:
			var new_id = _fresh_id()
			var new_ent = SeekingEntity.instance()
			new_ent.name = str(new_id)
			new_ent.owner_id = pid
			ents.add_child(new_ent)
			new_ent.position.x = c.x
			new_ent.position.y = c.y
		MOVE_ENTITIES:
			for id in c.ents:
				print("[ID: %d, T: %d] - move %s to x: %d, y: %d" % [Net.get_id(), manager.turn_number, id, c.x, c.y])
				var e = ents.get_node(id)
				e.move_to(c.x, c.y)

func _input(event):
	if event is InputEvent:
		if event.is_action_pressed("unit_place"):
			var mouse_pos = get_global_mouse_position()
			var create_ent_cmd = create_entity(mouse_pos.x, mouse_pos.y)
			manager.send_turn_command(create_ent_cmd, manager.turn_delay)
		elif event.is_action_pressed("ui_cancel"):
			SceneSwitcher.goto_scene(Game.Scenes.MAIN)
			Game.call_deferred("close_session")