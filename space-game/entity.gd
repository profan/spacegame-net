extends Node2D

onready var coll = get_node("collision")
onready var sprite = get_node("sprite")

var owner_id

var orders = []
var has_order = false
var is_selected = false

var move_target = Vector2()
var move_speed = 2 # pixels per.. tick?
var move_dir = Vector2(1, 0)

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	
	rotation_degrees += 1
	
	if has_order:
		var dist = position.distance_to(move_target)
		move_dir = (move_target - global_position).normalized()
		position += move_dir * move_speed
		update()
		
		if dist <= 16:
			has_order = false
			update()

func _draw():
	var w = coll.shape.extents.x
	var h = coll.shape.extents.y
	if owner_id == Net.get_id():
		draw_rect(Rect2(-(w / 2), -(h / 2), w, h), ColorN("green"), false)
	else:
		draw_rect(Rect2(-(w / 2), -(h / 2), w, h), ColorN("fuchsia"), false)
		
	if is_selected:
		draw_rect(Rect2(-(w / 2) - 4, -(h / 2) - 4, w + 8, h + 8), ColorN("yellow"), false)
		
	if has_order and is_selected:
		var inv = get_global_transform().inverse()
		draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale())
		draw_line(global_position, move_target, ColorN("orange"))

func move_to(x, y):
	has_order = true
	move_target.x = x
	move_target.y = y

func is_selectable_by(id):
	return id == owner_id

func select():
	is_selected = true
	update()

func deselect():
	is_selected = false
	update()