extends Label

onready var tween = get_node("tween")

var scale_time = 1.5
var scale_from = 1
var scale_to = 1.5
var tweening_in = false

func _ready():
	tween.interpolate_method(self, "_scale", scale_from, scale_to, scale_time, Tween.TRANS_SINE, Tween.EASE_IN)
	tween.connect("tween_completed", self, "_on_tween_done")
	tween.start()

func _on_tween_done(obj, key):
	if tweening_in:
		tween.interpolate_method(self, "_scale", scale_from, scale_to, scale_time, Tween.TRANS_SINE, Tween.EASE_IN)
		tweening_in = false
	else:
		tween.interpolate_method(self, "_scale", scale_to, scale_from, scale_time, Tween.TRANS_SINE, Tween.EASE_OUT)
		tweening_in = true

func _scale(v):
	rect_scale.x = v
	rect_scale.y = v
