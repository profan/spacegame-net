extends Node2D

# game gui
onready var canvas = get_node("canvas")

# scenes/resources
var Entity = load("res://space-game/entity.tscn")
var SeekingEntity = load("res://space-game/seeking_entity.tscn")
var Building = load("res://space-game/building.tscn")

# local refs
onready var camera = get_node("camera")
onready var selector = get_node("selection")
onready var ents = get_node("entities")
onready var blds = get_node("buildings")

enum Command {
	REGISTER_OWNER,
	CREATE_INITIAL,
	CREATE_ENTITY,
	MOVE_ENTITIES,
	MOVE_ENTITIES_LINE,
	DELETE_ENTITIES
}

func register_owner(id, colour):
	return {
		type = Command.REGISTER_OWNER,
		id = id, colour = colour
	}

func create_initial(x, y):
	return {
		type = Command.CREATE_INITIAL,
		x = x,
		y = y
	}

func create_entity(x, y):
	return {
		type = Command.CREATE_ENTITY,
		x = x,
		y = y
	}

func move_entities(ents, x, y, is_grouped):
	return {
		type = Command.MOVE_ENTITIES,
		ents = ents,
		x = x,
		y = y,
		grouped = is_grouped
	}

func move_entities_line(ents, ts):
	return {
		type = Command.MOVE_ENTITIES_LINE,
		ents = ents,
		targets = ts
	}

func delete_entities(ents):
	return {
		type = Command.DELETE_ENTITIES,
		ents = ents
	}

# network
var manager

# game state
var owners

# entity ids
var id_counter = -1

func init_state(m):
	m.connect("on_exec_turn_command", self, "_on_exec_turn_command")
	m.connect("on_ready", self, "_on_manager_ready")
	manager = m

func init_with_args(args):
	var chat_panel = args[0]
	canvas.add_child(chat_panel)

func _ready():

	var session = Game.get_session()
	session.connect("on_connection_lost", self, "_on_server_lost")

	# selection box stuff
	selector.connect("on_action_perform", self, "_on_action_perform")
	selector.connect("on_action_perform_line", self, "_on_action_perform_line")
	selector.connect("on_action_delete", self, "_on_action_delete")
	# manager.send_turn_command(register_owner(Net.get_id(), "fuchsia"))

func _on_manager_ready():
	# send initial command
	manager.send_turn_command(create_initial(0, 0), manager.turn_delay)

func _on_action_perform(modifiers, bodies, x, y):

	var ids = []
	for b in bodies:
		ids.append(b.name)

	var move_order = move_entities(ids, x, y, modifiers)
	manager.send_turn_command(move_order, manager.turn_delay)

func _on_action_delete(bodies):
	
	var ids = []
	for b in bodies:
		ids.append(b.name)
		
	var delete_order = delete_entities(ids)
	manager.send_turn_command(delete_order, manager.turn_delay)

class DistanceSorter:
	
	var first
	
	func _init(f):
		first = f
	
	func sort_bodies(a, b):
		return a.position.distance_squared_to(first) < b.position.distance_squared_to(first)

func _find_closest_target(point, targets, matched):
	
	var closest = 0
	var min_distance = targets[0].distance_to(point)
	
	var idx = 0
	for t in targets:
		if idx != closest and not matched.has(targets[idx]):
			var dist = t.distance_to(point)
			if dist < min_distance:
				min_distance = dist
				closest = idx
		idx += 1
	
	return closest

func _on_action_perform_line(bodies, targets):
	
	var sorter = DistanceSorter.new(targets[0])
	
	# sort bodies first
	bodies.sort_custom(sorter, "sort_bodies")
	
	var ids = []
	for b in bodies:
		ids.append(b.name)
	
	var ts = []
	for t in targets:
		ts.append(t)
	
	var move_order = move_entities_line(ids, ts)
	manager.send_turn_command(move_order, manager.turn_delay)

func _on_server_lost(session, reason):
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()

func _fresh_id():
	id_counter += 1
	return id_counter

func _geometric_mean(things):
	var total = things[0]
	for t in range(1, things.size()):
		total += t
	return total / things.size()

func _on_exec_turn_command(pid, c):

	match c.type:

		# during setup
		CREATE_INITIAL:
			
			# set location for host's building to 0, 0
			
			var x = 0
			var y = 0
			if pid == 1:
				x = 0
				y = 0
			else:
				x = 128
				y = 128
			var new_building = Building.instance()
			new_building.create_building(pid, Vector2(128, 128), Vector2(x, y))
			blds.add_child(new_building)
		
		REGISTER_OWNER:
			owners[c.id] = c.colour
		
		# during gameplay
		CREATE_ENTITY:
			var new_id = _fresh_id()
			var new_ent = Entity.instance()
			new_ent.name = str(new_id)
			new_ent.owner_id = pid
			ents.add_child(new_ent)
			new_ent.position.x = c.x
			new_ent.position.y = c.y
		
		MOVE_ENTITIES:
			if c.grouped:
				
				# calc geo mean
				var total = Vector2(0, 0)
				for id in c.ents:
					total += ents.get_node(id).position
				var center = total / c.ents.size()
				
				# move em
				for id in c.ents:
					# print("[ID: %d, T: %d] - move %s to x: %d, y: %d" % [Net.get_id(), manager.turn_number, id, c.x, c.y])
					var e = ents.get_node(id)
					var offset = (center - e.position)
					e.move_to(c.x - offset.x, c.y - offset.y)
					
			else:
				for id in c.ents:
					# print("[ID: %d, T: %d] - move %s to x: %d, y: %d" % [Net.get_id(), manager.turn_number, id, c.x, c.y])
					var e = ents.get_node(id)
					e.move_to(c.x, c.y)
		
		MOVE_ENTITIES_LINE:
			
			for i in range(0, c.ents.size()):
				var id = c.ents[i]
				var t = c.targets[i]
				# print("[ID: %d, T: %d] - move %s to x: %d, y: %d" % [Net.get_id(), manager.turn_number, id, t.x, t.y])
				var e = ents.get_node(id)
				e.move_to(t.x, t.y)
		
		DELETE_ENTITIES:
			
			for id in c.ents:
				# print("[ID: %d, T:%d] - deleted %s" % [Net.get_id(), manager.turn_number, id])
				var e = ents.get_node(id)
				ents.remove_child(e)
				e.free()

func _physics_process(delta):
	if Input.is_action_pressed("unit_place"):
		var mouse_pos = get_global_mouse_position()
		var create_ent_cmd = create_entity(mouse_pos.x, mouse_pos.y)
		manager.send_turn_command(create_ent_cmd, manager.turn_delay)

func _input(event):
	if event is InputEvent:
		if event.is_action_pressed("ui_cancel"):
			SceneSwitcher.goto_scene(Game.Scenes.MAIN)
			Game.call_deferred("close_session")