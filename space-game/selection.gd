extends Area2D

enum Modifier {
	SHIFT = 0x1,
	ALT = 0x2
}

onready var coll = get_node("collision")

var active = false
var start_pos = Vector2()
var end_pos = Vector2()

signal on_action_perform(mods, bodies, x, y)
signal on_action_perform_line(bodies, targets)
signal on_action_delete(bodies)

# intermediate
var pos_clicked = Vector2()
var pos_click_distance = 1
var pos_segments = PoolVector2Array()
var pos_targets = []

# modifier state
var modifiers

# entities selected
var selected_entities

func _ready():
	set_physics_process(true)
	connect("body_entered", self, "_on_body_entered")
	coll.shape.extents.x = 0
	coll.shape.extents.y = 0

func _on_body_entered(b):
	
	if active:
		if not b.has_method("is_selectable_by"): return
		if not b.is_selectable_by(Net.get_id()): return
		
		if not selected_entities:
			selected_entities = []
		
		if not selected_entities.has(b):
			selected_entities.append(b)
			b.select()

func _on_body_exited(b):
	
	if active:
		selected_entities.erase(b)
		b.deselect()

func _deselect_entities():
	for e in selected_entities:
		e.deselect()

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("unit_order_mod"):
			modifiers = true
		elif event.is_action_released("unit_order_mod"):
			modifiers = false
			

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("unit_select"):
			if selected_entities and not modifiers:
				_deselect_entities()
				selected_entities.clear()
			var mouse_pos = get_global_mouse_position()
			coll.shape.extents.x = 0
			coll.shape.extents.y = 0
			start_pos = mouse_pos
			global_position = mouse_pos
			active = true
		elif event.is_action_released("unit_select"):
			var mouse_pos = get_global_mouse_position()
			end_pos = mouse_pos
			active = false
			update() # redraw
		elif event.is_action_pressed("unit_order"):
			var mouse_pos = get_global_mouse_position()
			pos_clicked = mouse_pos
		elif event.is_action_released("unit_order"):
			var mouse_pos = get_global_mouse_position()
			if selected_entities and pos_segments.size() > 0 and not modifiers:
				
				# average things and collect only those necessary
				var step_size = pos_segments.size() / selected_entities.size()
				pos_targets.resize(selected_entities.size())
				
				var cur_step = 0
				while cur_step < selected_entities.size():
					pos_targets[cur_step] = pos_segments[cur_step * step_size]
					cur_step += 1
				
				emit_signal("on_action_perform_line", selected_entities, pos_targets)
				pos_segments.resize(0)
				update()
			else:
				if selected_entities:
					emit_signal("on_action_perform", modifiers, selected_entities, mouse_pos.x, mouse_pos.y)
					pos_segments.resize(0)
					update()
	elif event is InputEventKey:
		if event.is_action_released("unit_delete"):
			if selected_entities:
				emit_signal("on_action_delete", selected_entities)
				selected_entities.clear()
				update()

func _process(delta):
	pass

func _deselect_non_overlapping():
	var bodies_to_remove = []
	for b in selected_entities:
		if not overlaps_body(b):
			bodies_to_remove.append(b)
	
	for b in bodies_to_remove:
		selected_entities.erase(b)
		b.deselect()

func _physics_process(delta):
	
	if Input.is_action_pressed("unit_order") and selected_entities and not modifiers:
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.distance_to(pos_clicked) > pos_click_distance:
			if pos_segments.size() == 0:
				pos_segments.append(pos_clicked)
				pos_segments.append(mouse_pos)
			elif pos_segments[pos_segments.size() - 1].distance_to(mouse_pos) > 16:
				
				var cur_pos = pos_segments[pos_segments.size() - 1]
				var steps = cur_pos.distance_to(mouse_pos) / 16.0
				var cur_step = 0
				
				while cur_step < steps:
					var new_seg = pos_segments[pos_segments.size() - 1].linear_interpolate(mouse_pos, cur_step / steps)
					pos_segments.append(pos_segments[pos_segments.size() - 1])
					pos_segments.append(new_seg)
					cur_step += 1
				
				update()
	
	if active and Input.is_action_pressed("unit_select"):
		end_pos = get_global_mouse_position()
		coll.shape.extents.x = (end_pos.x - start_pos.x) / 2
		coll.shape.extents.y = (end_pos.y - start_pos.y) / 2
		global_position = start_pos + (end_pos - start_pos) / 2
		
		if selected_entities and not modifiers:
			_deselect_non_overlapping()
		
		# redraw yes
		update()

func _draw():
	
	var inv = get_global_transform().inverse()
	draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale())
	
	if active:
		var size = end_pos - start_pos
		draw_rect(Rect2(start_pos, size), ColorN("green", 0.25))
	
	if pos_segments.size() > 0:
		for v in pos_segments:
			draw_multiline(pos_segments, ColorN("green"))
	