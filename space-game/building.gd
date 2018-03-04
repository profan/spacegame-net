extends KinematicBody2D

onready var coll = get_node("collision")

var building_size = Vector2(16, 16)
var building_owner

func create_building(o, s):
	building_owner = o
	building_size = s

func _ready():
	set_physics_process(true)
	coll.position.x = building_size.x / 2
	coll.position.y = building_size.y / 2
	coll.shape.extents.x = building_size.x / 2
	coll.shape.extents.y = building_size.y / 2

func _physics_process(delta):
	pass

func _draw():
	draw_rect(Rect2(0, 0, building_size.x, building_size.y), building_owner.colour)