extends Control

func _ready():
	Net.connect("on_creation_successful", self, "_on_server_create_success")
	Net.connect("on_creation_failure", self, "_on_server_create_failure")
	Net.start_server("127.0.0.1", Net.DEFAULT_HOST_PORT, Net.DEFAULT_MAX_CLIENTS)

func _on_server_create_success():
	SceneSwitcher.goto_scene(Game.Scenes.LOBBY)

func _on_server_create_failure(reason):
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Net.close_connection()
