extends Node2D

onready var coll = get_node("collision")

var has_order = false
var move_target = Vector2()
var move_speed = 2 # pixels per.. tick?
var move_dir = Vector2(1, 0)
var owner_id

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	
	rotation_degrees += 1
	
	if has_order:
		var dist = position.distance_to(move_target)
		move_dir = (move_target - global_position).normalized()
		position += move_dir * move_speed
		
		if dist <= 16:
			has_order = false

func _draw():
	var w = coll.shape.extents.x
	var h = coll.shape.extents.y
	if owner_id == Net.get_id():
		draw_rect(Rect2(-(w / 2), -(h / 2), w, h), ColorN("green"), false)
	else:
		draw_rect(Rect2(-(w / 2), -(h / 2), w, h), ColorN("fuchsia"), false)

func move_to(x, y):
	has_order = true
	move_target.x = x
	move_target.y = y

func is_selectable_by(id):
	return id == owner_id