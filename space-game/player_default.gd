extends HBoxContainer

onready var color_rect = get_node("color_rect")
onready var name_label = get_node("name_label")
onready var ping_label = get_node("ping_label")

func _ready():
	pass

func set_colour(c):
	color_rect.color = c

func set_name(n):
	name_label.text = n

func set_ping(p):
	ping_label.text = ": %d ms" % p