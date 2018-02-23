extends Control

onready var lobby_btn = get_node("split/buttons/lobby_btn")
onready var connect_btn = get_node("split/buttons/connect_btn")
onready var options_btn = get_node("split/buttons/options_btn")
onready var quit_btn = get_node("split/buttons/quit_btn")

func _ready():
	lobby_btn.connect("pressed", self, "_on_lobby_btn")
	connect_btn.connect("pressed", self, "_on_connect_btn")
	options_btn.connect("pressed", self, "_on_options_btn")
	quit_btn.connect("pressed", self, "_on_quit_btn")

func _on_lobby_btn():
	SceneSwitcher.goto_scene(Game.Scenes.CREATING)

func _on_connect_btn():
	SceneSwitcher.goto_scene(Game.Scenes.CONNECTING)

func _on_options_btn():
	SceneSwitcher.goto_scene(Game.Scenes.OPTIONS)

func _on_quit_btn():
	get_tree().quit()