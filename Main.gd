extends Node

const WRONG=0
const NOT_YET=-1
const CORRECT=2

var score # elapsed time
var qno   # question number

var cards = { # number written on cards
	"C1": "1",
	"C2": "2",
	"C3": "3",
	"C4": "4",
	"C5": "5",
	"C6": "6",
	"C7": "7",
	"C8": "8",
	"C9": "9",
	"C0": "0",
}

var readers = { # position of each reader in the row
	"R0": 0,
	"R1": 1,
	"R2": 2,
	"R3": 3,
	"R4": 4,
	"R5": 5,
	"R6": 6,
	"R7": 7,
}

var states = ["", "", ""] # suppose that the 3 slots are empty

var questions = [
	"Đặt số 9 vào ô thứ nhất",
	"Đặt số 8 vào ô thứ hai",
	"Đặt số 7 vào ô thứ ba",
	"Đổi chỗ nếu số thứ nhất lớn hơn số thứ hai",
]

var answers = [ # numbers in the row, "" for empty
	["9", "", ""],
	["9", "8", ""],
	["9", "8", "7"],
	["8", "9", "7"],
]

func add_card(cardID, readerID):
	var reader_pos = readers[readerID]
	var number = cards[cardID]
	states[reader_pos] = number
	
func remove_card(readerID):
	var reader_pos = readers[readerID]
	states[reader_pos] = ""

func update_states(s):
	"""
	This is the key function linking the game logic and the websocket communication.
	
	s is the message coming from websocket, of format <action>:[<cardID>:]<readerID>
	with <action> is either 'ADD' or 'REMOVE'
	"""
	if ':' in s:
		var action = s.split(':')[0]
		if action == 'ADD':
			var cardID = s.split(':')[1]
			var readerID = s.split(':')[2]
			add_card(cardID, readerID)
			check_states() # don't check when removing cards (to swap cards for example)
		elif action == 'REMOVE':
			var readerID = s.split(':')[1]
			remove_card(readerID)
		else:
			pass # do nothing for now
	
	$HBoxContainer/MarginContainer/ColorRect/Label.text = str(states[0])
	$HBoxContainer/MarginContainer2/ColorRect/Label.text = str(states[1])
	$HBoxContainer/MarginContainer3/ColorRect/Label.text = str(states[2])
	
func check_states():
	"""
	Compare with the answer. Using global variable `qno`.
	Return either CORRECT, WRONG, or NOT_YET as a whole (not vs. last reader)
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
			qno += 1
			if qno < len(questions):
				show_question()
			else:
				victory()
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
	qno = 0
	states = ["", "", ""]
	update_states("")
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Sẵn sàng")
	$Music.play()
	show_question()
	
func show_question():
	$QuestionLabel.text = questions[qno]

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
	update_states(s)
	# _server.get_peer(id).put_packet(pkt) # send back data

func _process(delta):
	# Call this in _process or _physics_process.
	# Data transfer, and signals emission will only happen when calling this function.
	_server.poll()
