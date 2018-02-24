extends Node2D

onready var coll = get_node("collision")

var has_order = false
var move_target = Vector2()
var move_speed = 2 # pixels per.. tick?
var move_dir = Vector2(1, 0)

func id():
	return name

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

func move_to(x, y):
	has_order = true
	move_target.x = x
	move_target.y = y
	print("move order to x: %d, y: %d" % [x, y])
