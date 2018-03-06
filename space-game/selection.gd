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

# modifier state
var modifiers

# entities selected
var selected_entities

func _ready():
	connect("body_entered", self, "_on_body_entered")
	coll.shape.extents.x = 0
	coll.shape.extents.y = 0

func _on_body_entered(b):
	
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
			if selected_entities: 
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
			if selected_entities:
				emit_signal("on_action_perform", modifiers, selected_entities, mouse_pos.x, mouse_pos.y)

func _process(delta):
	if active and Input.is_action_pressed("unit_select"):
		end_pos = get_global_mouse_position()
		coll.shape.extents.x = (end_pos.x - start_pos.x) / 2
		coll.shape.extents.y = (end_pos.y - start_pos.y) / 2
		global_position = start_pos + (end_pos - start_pos) / 2
		
		# redraw yes
		update()

func _draw():
	if active:
		var size = end_pos - start_pos
		var inv = get_global_transform().inverse()
		draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale())
		draw_rect(Rect2(start_pos, size), ColorN("green", 0.25))