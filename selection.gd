extends Area2D

onready var coll = get_node("collision")

var active = false
var start_pos = Vector2()
var end_pos = Vector2()

signal on_action_perform(bodies, x, y)

var selected_entities

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(b):
	
	if not selected_entities:
		selected_entities = []
	
	if not selected_entities.has(b):
		selected_entities.append(b)

func _on_body_exited(b):
	selected_entities.erase(b)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("unit_select"):
			if selected_entities: selected_entities.clear()
			var mouse_pos = get_global_mouse_position()
			coll.shape.extents.x = 0
			coll.shape.extents.y = 0
			start_pos = mouse_pos
			global_position = mouse_pos
			active = true
		elif event.is_action_released("unit_select"):
			var mouse_pos = get_global_mouse_position()
			# var bodies = get_overlapping_bodies()
			# selected_entities = bodies
			end_pos = mouse_pos
			active = false
		elif event.is_action_pressed("unit_order"):
			var mouse_pos = get_global_mouse_position()
			if selected_entities:
				emit_signal("on_action_perform", selected_entities, mouse_pos.x, mouse_pos.y)

func _process(delta):
	if active and Input.is_action_pressed("unit_select"):
		end_pos = get_global_mouse_position()
		coll.shape.extents.x = (end_pos.x - start_pos.x) / 2
		coll.shape.extents.y = (end_pos.y - start_pos.y) / 2
		global_position = start_pos + (end_pos - start_pos) / 2

func _draw():
	pass