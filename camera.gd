extends Camera2D

onready var tween = get_node("tween")

var mouse_position = Vector2()
var drag_start = Vector2()
var drag_delta = Vector2()
var dragging = false

const DRAG_SPEED = 128 # pixels per second
const MIN_ZOOM = 0.5
const MAX_ZOOM = 3

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("map_drag"):
			dragging = true
			drag_start.x = event.position.x
			drag_start.y = event.position.y
		elif event.is_action_released("map_drag"):
			drag_start.x = 0
			drag_start.y = 0
			dragging = false
		elif event.is_action_pressed("map_zoom_in"):
			zoom.x = min(zoom.x + 0.1, MAX_ZOOM)
			zoom.y = min(zoom.y + 0.1, MAX_ZOOM)
		elif event.is_action_pressed("map_zoom_out"):
			zoom.x = max(zoom.x - 0.1, MIN_ZOOM)
			zoom.y = max(zoom.y - 0.1, MIN_ZOOM)
	elif event is InputEventKey:
		if event.is_action("map_zoom_in_btn"):
			zoom.x = max(zoom.x - 0.1, MIN_ZOOM)
			zoom.y = max(zoom.y - 0.1, MIN_ZOOM)
		elif event.is_action("map_zoom_out_btn"):
			zoom.x = min(zoom.x + 0.1, MAX_ZOOM)
			zoom.y = min(zoom.y + 0.1, MAX_ZOOM)
	elif event is InputEventMouseMotion:
		mouse_position.x = event.position.x
		mouse_position.y = event.position.y

func _process(delta):
	
	if Input.is_action_pressed("map_scroll_up"):
		position.y -= DRAG_SPEED * delta;
	elif Input.is_action_pressed("map_scroll_down"):
		position.y += DRAG_SPEED * delta;
	if Input.is_action_pressed("map_scroll_left"):
		position.x -= DRAG_SPEED * delta;
	elif Input.is_action_pressed("map_scroll_right"):
		position.x += DRAG_SPEED * delta;
	
	if dragging:
		
		var mp = mouse_position
		drag_delta.x = (mp.x - drag_start.x)
		drag_delta.y = (mp.y - drag_start.y)
		
		position.x -= (drag_delta.x) * (zoom.x)
		position.y -= (drag_delta.y) * (zoom.y)
		
		drag_start.x = mp.x
		drag_start.y = mp.y