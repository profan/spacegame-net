extends LineEdit

signal on_submit(msg)

func _ready():
	pass

func _input(event):
	if event is InputEventKey:
		if event.is_action("chat_submit") and not text.empty():
			emit_signal("on_submit", text)
			clear()