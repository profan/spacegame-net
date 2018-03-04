extends Node2D

const km = preload("res://kinematic.gd")

onready var coll = get_node("collision")

var has_order = false
var move_speed = 2 # pixels per.. tick?
var move_dir = Vector2(1, 0)
var owner_id

func move_to(x, y):
	has_order = true
	s_seek.set_target(Vector2(x, y))
	s_arrive.set_target(Vector2(x, y))

var grunt_max_speed = 256 # pixels per second
var grunt_arrive_radius = 64
var grunt_arrive_speed = 1
var grunt_rot_speed = deg2rad(22.5) # degrees per second

var cur_kinematic
var steering
var s_seek
var s_arrive
var s_avoid

var player_in_cone = false

func _ready():
	
	set_physics_process(true)
	
	cur_kinematic = km.Kinematic.new(self, grunt_max_speed)
	steering = km.Steering.new()
	
	s_seek = km.Seek.new(self)
	s_arrive = km.Arrive.new(self, grunt_arrive_radius, grunt_arrive_speed)
	# s_avoid = km.Avoid.new(self, avoid_area)

func get_kinematic_position():
	return get_global_pos() + cur_kinematic.velocity
	
func _physics_process(delta):
	
	s_seek.get_steering(steering)
	s_arrive.get_steering(steering)
	# s_avoid.get_steering(steering)
	cur_kinematic.update(steering, delta)

func is_selectable_by(id):
	return id == owner_id