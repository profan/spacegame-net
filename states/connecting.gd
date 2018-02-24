extends Control

onready var title = get_node("center/title")

var from_scene_name = false
var joining_address

func init_with_args(args):
	joining_address = args[0]

func _ready():
	Net.join_server(joining_address, Net.DEFAULT_HOST_PORT)
	Net.connect("on_connection_successful", self, "_on_connection_successful")
	Net.connect("on_connection_failure", self, "_on_connection_failure")
	title.text = "Connecting to: %s..." % Net.get_host_ip()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action("ui_cancel"):
			SceneSwitcher.goto_scene(from_scene_name)
			Game.close_session()

func _on_connection_successful():
	SceneSwitcher.goto_scene(Game.Scenes.LOBBY)

func _on_connection_failure():
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()