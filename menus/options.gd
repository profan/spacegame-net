extends Control

var from_scene_name = false

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action("ui_cancel"):
			SceneSwitcher.goto_scene(from_scene_name)