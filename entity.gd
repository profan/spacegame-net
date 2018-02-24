extends Node2D

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	rotation_degrees += 1
