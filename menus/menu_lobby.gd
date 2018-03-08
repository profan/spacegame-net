extends Control

const Colours = [
	"aliceblue",
	"antiquewhite",
	"aqua",
	"aquamarine",
	"azure",
	"beige",
	"bisque",
	"black",
	"blanchedalmond",
	"blue",
	"blueviolet",
	"brown",
	"burlywood",
	"cadetblue",
	"chartreuse",
	"chocolate",
	"coral",
	"cornflower",
	"cornsilk",
	"crimson",
	"cyan",
	"darkblue",
	"darkcyan",
	"darkgoldenrod",
	"darkgray",
	"darkgreen",
	"darkkhaki",
	"darkmagenta",
	"darkolivegreen",
	"darkorange",
	"darkorchid",
	"darkred",
	"darksalmon",
	"darkseagreen",
	"darkslateblue",
	"darkslategray",
	"darkturquoise",
	"darkviolet",
	"deeppink",
	"deepskyblue",
	"dimgray",
	"dodgerblue",
	"firebrick",
	"floralwhite",
	"forestgreen",
	"fuchsia",
	"gainsboro",
	"ghostwhite",
	"gold",
	"goldenrod",
	"gray",
	"webgray",
	"green",
	"webgreen",
	"greenyellow",
	"honeydew",
	"hotpink",
	"indianred",
	"indigo",
	"ivory",
	"khaki",
	"lavender",
	"lavenderblush",
	"lawngreen",
	"lemonchiffon",
	"lightblue",
	"lightcoral",
	"lightcyan",
	"lightgoldenrod",
	"lightgray",
	"lightgreen",
	"lightpink",
	"lightsalmon",
	"lightseagreen",
	"lightskyblue",
	"lightslategray",
	"lightsteelblue",
	"lightyellow",
	"lime",
	"limegreen",
	"linen",
	"magenta",
	"maroon",
	"webmaroon",
	"mediumaquamarine",
	"mediumblue",
	"mediumorchid",
	"mediumpurple",
	"mediumseagreen",
	"mediumslateblue",
	"mediumspringgreen",
	"mediumturquoise",
	"mediumvioletred",
	"midnightblue",
	"mintcream",
	"mistyrose",
	"moccasin",
	"navajowhite",
	"navyblue",
	"oldlace",
	"olive",
	"olivedrab",
	"orange",
	"orangered",
	"orchid",
	"palegoldenrod",
	"palegreen",
	"paleturquoise",
	"palevioletred",
	"papayawhip",
	"peachpuff",
	"peru",
	"pink",
	"plum",
	"powderblue",
	"purple",
	"webpurple",
	"rebeccapurple",
	"red",
	"rosybrown",
	"royalblue",
	"saddlebrown",
	"salmon",
	"sandybrown",
	"seagreen",
	"seashell",
	"sienna",
	"silver",
	"skyblue",
	"slateblue",
	"slategray",
	"snow",
	"springgreen",
	"steelblue",
	"tan",
	"teal",
	"thistle",
	"tomato",
	"turquoise",
	"violet",
	"wheat",
	"white",
	"whitesmoke",
	"yellow",
	"yellowgreen"
]

onready var address_label = get_node("center/menu_panel/menu_container/top_container/address")
onready var id_label = get_node("center/menu_panel/menu_container/top_container/id")

# list of players
onready var nicks = get_node("center/menu_panel/menu_container/categories/nick_list/nicks")
onready var pings = get_node("center/menu_panel/menu_container/categories/ping/pings")
onready var types = get_node("center/menu_panel/menu_container/categories/type/types")
onready var actions = get_node("center/menu_panel/menu_container/categories/action/actions")

# start/cancel btns
onready var start_btn = get_node("center/menu_panel/menu_container/buttons/start_btn")
onready var cancel_btn = get_node("center/menu_panel/menu_container/buttons/cancel_btn")

# chat in lobby too
onready var chat_panel = get_node("chat_panel")

var from_scene_name = false

func _on_start_btn():
	remove_child(chat_panel)
	SceneSwitcher.goto_scene(Game.Scenes.PLAYING, [chat_panel])

func _on_cancel_btn():
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()

func _ready():
	
	start_btn.connect("pressed", self, "_on_start_btn")
	cancel_btn.connect("pressed", self, "_on_cancel_btn")
	
	address_label.text = "%s:%s" % [Net.get_host_ip(), Net.get_host_port()]
	id_label.text = "id: %d" % Net.get_id()
	
	var session = Game.start_session()
	
	if Net.is_server():
		session.my_info = {
			nick = "profan",
			colour = ColorN("green")
		}
		_register_player(Net.get_id(), session.my_info)
	
	if not Net.is_server():
		session.my_info = {
			nick = "unknown",
			colour = ColorN(Colours[floor(rand_range(0, Colours.size()))])
		}
		session.connect("on_connection_lost", self, "_on_connection_lost")
		session.register_myself()
		
	session.connect("on_player_connected", self, "_on_player_connect")
	session.connect("on_player_disconnected", self, "_on_player_disconnect")

# ui stuff
func _remove_by_name(node, naem):
	var n = node.get_node(str(naem))
	node.remove_child(n)
	n.queue_free()

func _add_label(node, naem, text):
	var new_label = Label.new()
	new_label.set_name(str(naem))
	new_label.text = text
	node.add_child(new_label)
	return new_label

func _set_label_colour(label, colour):
	label.add_color_override("font_color", colour)

func _add_action_button(node, naem):
	var new_btn = OptionButton.new()
	new_btn.set_name(str(naem))
	node.add_child(new_btn)
	return new_btn

func _type_label(id):
	if id == 1:
		return "S"
	else:
		return "C"

func _set_nick_colour(nick_label, id):
	var session = Game.get_session()
	if id == Net.get_id(): _set_label_colour(nick_label, session.my_info.colour)
	else: _set_label_colour(nick_label, session.get_players()[id].colour)

func _register_player(id, player_info):
	var n = player_info.nick
	var nick = _add_label(nicks, id, n)
	_set_nick_colour(nick, id) # colour yes
	var ping = _add_label(pings, id, "0")
	var type = _add_label(types, id, _type_label(id))
	var action = _add_action_button(actions, id)

func _update_player(id, old_info, new_info):
	pass

func _deregister_player(id, player_info):
	var n = player_info.nick
	_remove_by_name(nicks, id)
	_remove_by_name(pings, id)
	_remove_by_name(types, id)
	_remove_by_name(actions, id)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action("ui_cancel"):
			SceneSwitcher.goto_scene(Game.Scenes.MAIN)
			Game.close_session()

func _on_player_connect(s, id):
	print("player connected: %d" % id)
	_register_player(id, s.peer_info[id])

func _on_player_disconnect(s, id):
	print("player disconnected: %d" % id)
	_deregister_player(id, s.peer_info[id])

# client only
func _on_connection_lost(s, reason):
	print("lost connection to server: %s" % reason)
	SceneSwitcher.goto_scene(Game.Scenes.MAIN)
	Game.close_session()