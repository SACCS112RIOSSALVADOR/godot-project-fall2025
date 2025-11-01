extends Node2D

# Game variables
var score : int
const REWARD : int = 100
var game_running : bool = true
var team : bool 
var pieces_remaining : int = 7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false # Check for paused game
	newgame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"): # Press Esc to pause the game
		pause_game() 
		$VBoxContainer.show()

# Start New game function 
func newgame():
	clear_board()
	game_running = true
	get_tree().paused = false
	$VBoxContainer.hide()
	
# Pause game function
func pause_game() -> void:
	if not get_tree().paused:
		game_running = false
		get_tree().paused = true

# Resume game function
func resume_game() -> void:
	if get_tree().paused:
		game_running = true
		get_tree().paused = false
		$VBoxContainer.hide()

func clear_board():
	pass

# Check for game over
func check_game_over():
	if pieces_remaining == 0:
		game_running = false
