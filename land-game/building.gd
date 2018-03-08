extends KinematicBody2D

onready var coll = get_node("collision")
onready var label = get_node("label")

var owner_id
var size

func create_building(oid, s, p):
	owner_id = oid
	size = s
	position = p

func _ready():
	label.text = str(owner_id)
	set_physics_process(true)
	coll.position.x = size.x / 2
	coll.position.y = size.y / 2
	coll.shape.extents.x = size.x / 2
	coll.shape.extents.y = size.y / 2

func _physics_process(delta):
	pass

func _draw():

	var session = Game.get_session()

	var w = coll.shape.extents.x
	var h = coll.shape.extents.y

	if owner_id == Net.get_id():
		draw_rect(Rect2(0, 0, w, h), session.my_info.colour, false)
	else:
		draw_rect(Rect2(0, 0, w, h), session.get_players()[owner_id].colour, false)