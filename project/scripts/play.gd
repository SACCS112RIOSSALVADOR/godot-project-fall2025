extends Node2D

var score : int
const REWARD : int = 100
var game_running : bool 
var team : bool 
var pieces_remaining : int = 7
var foes_remaining: int = 7
var turn : bool #true = player turn, #false = foe's turn
var is_paused : bool = false
var turns_left = 25

# Reference to your pause menu panel (adjust the path to match your scene tree)
@onready var pause_panel = $PausePanel  # Change this to match your actual node path
@export var actions_per_turn_player: int = 4
@export var actions_per_turn_foe: int = 4

# reference game Varialbes $GameOverLabel & $PausePanel/VBoxContainer/ResumeButton
@onready var game_over_label: Label = $GameOverLabel
@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton

@onready var turn_label = $TurnLabel

var player_actions_left: int = 0
var foe_actions_left: int = 0
var player_turn: bool = true  # true = player turn, false = foe turn


"""
---------------------------------------------------------
Requirement 6 – AI controls opposing shapes on their turn
---------------------------------------------------------
"""

func _start_player_turn() -> void:
	player_turn = true
	player_actions_left = actions_per_turn_player

	# Set the global phase flag on all units (they all share the same current_turn)
	for u in get_tree().get_nodes_in_group("units"):
		if u and is_instance_valid(u):
			u.current_turn = true
	
	print("=== Turns Left ===")
	print("Turns left: ", turns_left)

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
		turns_left = turns_left - 1

"""
------------------------------------------
Requirement 1 – Start game & display board
------------------------------------------
"""

func _ready() -> void:
	# your existing setup...
	turns_left = GlobalData.turn_limit
	_start_player_turn()
	# Make sure pause panel is hidden at start
	if pause_panel:
		pause_panel.visible = false
	
	# Hide GameOverLabel at start
	if game_over_label:
		game_over_label.visible = false

	# ResumeButton should be visible during normal play
	if resume_button:
		resume_button.visible = true
	
	turn = true
	
	# Initialize score and update the label
	score = GlobalData.player_score
	var score_label = $ScoreLabel  # adjust this path if your label is nested differently
	if score_label:
		score_label.text = "Score: "

	# Optionally, unpause the game on load
	get_tree().paused = false
	game_running = true
	is_paused = false

"""
-----------------------------------
Requirement 7/8 – Pause / resume game
-----------------------------------
"""

func _process(_delta: float) -> void:
	# Pause via ESC
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

	if game_running and !is_paused:
		# Check if there are no more enemies
		var foes = get_tree().get_nodes_in_group("foe_units")
		if foes.is_empty():
			GlobalData.update_score(score)
			GlobalData.nextlevel()
			show_game_over()
		if turns_left <= 0:
			GlobalData.reset()
			show_game_over()
	turn_label.text = "Turns Left: " + str(turns_left)

func toggle_pause():
# Do not allow pausing/unpausing after game over
	if !game_running:
		return

	is_paused = !is_paused

	get_tree().paused = is_paused

	if pause_panel:
		pause_panel.visible = is_paused

	# In normal pause, Resume is visible, Game Over label is hidden
	if resume_button:
		resume_button.visible = true

	if game_over_label:
		game_over_label.visible = false

func resume_game():
	# Can't resume if the game is over
	if !game_running:
		return

	is_paused = false
	get_tree().paused = false

	if pause_panel:
		pause_panel.visible = false

	# GameOverLabel should already be hidden in normal flow,
	# but you can force it off to be safe:
	if game_over_label:
		game_over_label.visible = false

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

"""
--------------------------------------------------------
Requirement 8 – Game over when enemy shapes are all dead
--------------------------------------------------------
"""

# show game over function
func show_game_over() -> void:
	# Stop the game logic
	game_running = false
	is_paused = true

	# Pause the scene tree
	get_tree().paused = true

	# Show the pause panel and the Game Over label
	if pause_panel:
		pause_panel.visible = true

	if game_over_label:
		game_over_label.visible = true

	# Hide the Resume button during Game Over
	if resume_button:
		resume_button.visible = false
		

func show_victory() -> void:
	# Stop the game logic
	game_running = false
	is_paused = true
	
	#get victory scene similar to paused
	
