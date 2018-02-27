extends PanelContainer

onready var chat_box = get_node("things/chat_panel/chat_box")
onready var chat_input = get_node("things/chat_input")

func _ready():
	yield(Game, "session_started")
	var session = Game.get_session()
	session.connect("on_player_sent_message", self, "_on_player_sent_message")
	chat_input.connect("on_submit", self, "_on_player_send_message")

func _on_player_sent_message(s, id, msg):
	if Net.is_server() and id == Net.get_id():
		var player = s.my_info
		chat_box.text += "%s: %s\n" % [player.nick, msg]
	else:
		var peers = s.get_players()
		var player = peers[id]
		chat_box.text += "%s: %s\n" % [player.nick, msg]

func _on_player_send_message(msg):
	var session = Game.get_session()
	session.rpc("send_message", Net.get_id(), msg)
	_on_player_sent_message(session, Net.get_id(), msg)