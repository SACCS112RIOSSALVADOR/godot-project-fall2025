extends Node2D


# Game variables
var score : int
const REWARD : int = 100
var game_running : bool 
var team : bool 
var active_piece : Array  # Array of Vector2i positions for the current piece
var pieces_remaining : int = 7


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if game_running:
		pass

func newgame():
	clear_board()
	game_running = true
	pass

func clear_board():
	pass
	
#func check_game_over():
	#for i in active_piece:
		#if not is_free(i + cur_pos):
			#land_piece()	
			#$HUD.get_node("GameOverLabel").show()
			#game_running = false
