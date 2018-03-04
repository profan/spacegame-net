extends KinematicBody2D

onready var coll = get_node("collision")

var owner_id
var size

func create_building(oid, s):
	owner_id = oid
	size = s

func _ready():
	set_physics_process(true)
	coll.position.x = size.x / 2
	coll.position.y = size.y / 2
	coll.shape.extents.x = size.x / 2
	coll.shape.extents.y = size.y / 2

func _physics_process(delta):
	pass

func _draw():
	var w = coll.shape.extents.x
	var h = coll.shape.extents.y
	if owner_id == Net.get_id():
		draw_rect(Rect2(0, 0, w, h), ColorN("green"), false)
	else:
		draw_rect(Rect2(0, 0, w, h), ColorN("fuchsia"), false)