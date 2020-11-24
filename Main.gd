extends Node

const WRONG=0
const NOT_YET=-1
const CORRECT=2

var score=0 # = elapsed time
var qno=-1   # question number

var cards = { # number written on cards
	"C0 D6 16 32": "7",
	"37 5F D1 3C": "8",
	"62 C9 B1 A9": "9",
}

var readers = { # position of each reader in the row
	"R1": 0,
	"R2": 1,
	"R3": 2,
}

var states = ["", "", ""] # suppose that the 3 slots are initially empty

var questions = [
	"Đặt số 9 vào ô thứ nhất",
	"Đặt tiếp số 8 vào ô thứ hai",
	"Đặt tiếp số 7 vào ô thứ ba",
	"Đổi chỗ nếu số ở ô thứ nhất lớn hơn số ở ô thứ hai",
]

var answers = [ # numbers in the row, "" for empty
	["9", "", ""],
	["9", "8", ""],
	["9", "8", "7"],
	["8", "9", "7"],
]

func update_states(s):
	"""
	This is the key function linking the game logic and the websocket communication.
	
	s is the message coming from websocket, of format 
	<reader1>:<card1>;<reader2>:<card2>;…
	if no card on it, the reader will not be shown
	"""

	var last_states = states.duplicate()

	# parse message to a dict {readerID:cardID}
	var s_parsed = {} # there no dict comprehension in GDScript
	for part in s.split(';'):
		if part != "":
			s_parsed[part.split(':')[0]] = part.split(':')[1]

	# loop through known readers to get new states
	var pos: int
	var cardID: String
	for readerID in readers:
		pos = readers[readerID]
		if readerID in s_parsed:
			cardID = s_parsed[readerID]
			states[pos] = cards[cardID]
		else:
			states[pos] = ""

	$HBoxContainer/MarginContainer/ColorRect/Label.text = str(states[0])
	$HBoxContainer/MarginContainer2/ColorRect/Label.text = str(states[1])
	$HBoxContainer/MarginContainer3/ColorRect/Label.text = str(states[2])
	
	# compare with last states, if user's action is only removing cards,
	# then don't check for validity
	var is_removing = false
	for i in range(len(states)):
		if last_states[i] != "" and states[i] == "":
			is_removing = true
	if not is_removing:	
		check_states()
	
func check_states():
	"""
	Compare with the answer. Using the global variable `qno`.
	Return either CORRECT, WRONG, or NOT_YET
	Don't use this function when the user is removing cards (to swap cards for example)
	"""
	var answer = answers[qno]
	var check = CORRECT
	for i in len(states):
		if states[i] != answer[i]:
			if states[i] != "":
				check = WRONG
				break
			check = NOT_YET 
	
	if check != NOT_YET:
		if check == CORRECT:
			next_question()
		else:
			game_over()

func game_over():
	$ScoreTimer.stop()
	$HUD.show_endgame("Bạn thua rồi", 0)
	$Music.stop()
	$DeathSound.play()
	$QuestionLabel.hide()
	$HBoxContainer.hide()
	
func victory():
	$ScoreTimer.stop()
	$HUD.show_endgame("Xin chúc mừng!", score)
	$Music.stop()
	$QuestionLabel.hide()
	$HBoxContainer.hide()
	
func new_game():
	score = 0
	qno = -1
	states = ["", "", ""]
	$HBoxContainer/MarginContainer/ColorRect/Label.text = ""
	$HBoxContainer/MarginContainer2/ColorRect/Label.text = ""
	$HBoxContainer/MarginContainer3/ColorRect/Label.text = ""
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Sẵn sàng")
	$Music.play()
	next_question()

func next_question():
	qno += 1
	if qno < len(questions):
		$QuestionLabel.text = questions[qno]
	else:
		victory()
	
func _on_StartTimer_timeout():
	$ScoreTimer.start()
	$QuestionLabel.show()
	$HBoxContainer.show()

func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)

#-------------------------WebSocket---------------------------
# much of this is from boiler_plate code

# The port we will listen to
const PORT = 9080
# Our WebSocketServer instance
var _server = WebSocketServer.new()

# Called when the node enters the scene tree for the first time.

func _ready():
	
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	# This signal is emitted when not using the Multiplayer API every time a
	# full packet is received.
	# Alternatively, you could check get_peer(PEER_ID).get_available_packets()
	# in a loop for each connected peer.
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	if err != OK:
		print("Unable to start server")
		set_process(false)

func _connected(id, proto):
	# This is called when a new peer connects, "id" will be the assigned peer id,
	# "proto" will be the selected WebSocket sub-protocol (which is optional)
	print("Client %d connected with protocol: %s" % [id, proto])

func _close_request(id, code, reason):
	# This is called when a client notifies that it wishes to close the connection,
	# providing a reason string and close code.
	print("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
	# This is called when a client disconnects, "id" will be the one of the
	# disconnecting client, "was_clean" will tell you if the disconnection
	# was correctly notified by the remote peer before closing the socket.
	print("Client %d disconnected, clean: %s" % [id, str(was_clean)])

func _on_data(id):
	# Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
	# and not get_packet directly when not using the MultiplayerAPI.
	var pkt = _server.get_peer(id).get_packet()
	var s = pkt.get_string_from_utf8()
	print("Got data from client %d: %s" % [id, s])
	if $ScoreTimer.time_left > 0: # processing incoming message during gameplay only
		update_states(s)
	# _server.get_peer(id).put_packet(pkt) # send back data

func _process(delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()
