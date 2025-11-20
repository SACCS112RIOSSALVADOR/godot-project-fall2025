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

func _ready() -> void:
	# Make sure pause panel is hidden at start
	if pause_panel:
		pause_panel.visible = false

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
