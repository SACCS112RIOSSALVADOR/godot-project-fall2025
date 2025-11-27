extends Node2D

var score : int
const REWARD : int = 100
var game_running : bool 
var team : bool 
var pieces_remaining : int = 7
var foes_remaining: int = 7
var turn : bool #true = player turn, #false = foe's turn
var is_paused : bool = false

# Reference to your pause menu panel (adjust the path to match your scene tree)
@onready var pause_panel = $PausePanel  # Change this to match your actual node path
@export var actions_per_turn_player: int = 4
@export var actions_per_turn_foe: int = 4

var player_actions_left: int = 0
var foe_actions_left: int = 0
var player_turn: bool = true  # true = player turn, false = foe turn

func _start_player_turn() -> void:
	player_turn = true
	player_actions_left = actions_per_turn_player

	# Set the global phase flag on all units (they all share the same current_turn)
	for u in get_tree().get_nodes_in_group("units"):
		if u and is_instance_valid(u):
			u.current_turn = true

	print("=== Player Turn ===")
	print("Player actions left: ", player_actions_left)


func _start_foe_turn() -> void:
	player_turn = false
	foe_actions_left = actions_per_turn_foe

	for u in get_tree().get_nodes_in_group("units"):
		if u and is_instance_valid(u):
			u.current_turn = false

	print("=== Foe Turn ===")
	print("Foe actions left: ", foe_actions_left)


func _end_turn() -> void:
	if player_turn:
		_start_foe_turn()
	else:
		_start_player_turn()

func _ready() -> void:
	# your existing setup...
	_start_player_turn()
	# Make sure pause panel is hidden at start
	if pause_panel:
		pause_panel.visible = false
	
	turn = true
	
	# Initialize score and update the label
	score = 0
	var score_label = $ScoreLabel  # adjust this path if your label is nested differently
	if score_label:
		score_label.text = "Score: 0"

	# Optionally, unpause the game on load
	get_tree().paused = false
	game_running = true
	is_paused = false


func _process(_delta: float) -> void:
	# Check for pause input
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key
		toggle_pause()
	
	if game_running and !is_paused:
		pass

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		# Pause the game
		get_tree().paused = true
		if pause_panel:
			pause_panel.visible = true
	else:
		# Resume the game
		get_tree().paused = false
		if pause_panel:
			pause_panel.visible = false

func resume_game():
	is_paused = false
	get_tree().paused = false
	if pause_panel:
		pause_panel.visible = false

func newgame():
	_start_player_turn()
	clear_board()
	game_running = true
	is_paused = false
	get_tree().paused = false
	if pause_panel:
		pause_panel.visible = false

func clear_board():
	pass
	
func check_game_over():
	if pieces_remaining == 0:
		game_running = false
		
@onready var score_label = $ScoreLabel  # adjust the path if needed

func add_score(amount: int):
	score += amount
	if score_label:
		score_label.text = "Score: %d" % score
	
func _on_unit_action_performed(shape: Node) -> void:
	# Defensive: shape might already be freed
	if !shape or !is_instance_valid(shape):
		return
	if !shape.has_method("get_team"):
		return

	var is_player_unit: bool = shape.get_team()

	if player_turn:
		# Only count actions from player units during player turn
		if !is_player_unit:
			return
		player_actions_left -= 1
		print("Player actions left: ", player_actions_left)
		if player_actions_left <= 0:
			_end_turn()
	else:
		# Foe turn: only count foe actions
		if is_player_unit:
			return
		foe_actions_left -= 1
		print("Foe actions left: ", foe_actions_left)
		if foe_actions_left <= 0:
			_end_turn()
