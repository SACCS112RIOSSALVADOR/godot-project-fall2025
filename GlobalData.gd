extends Node

#small file to keep track and load the score/level when scene resets
var player_score = 0  
var current_level = 1
var turn_limit = 25


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset():
	player_score = 0
	current_level = 1
	turn_limit =  25

func update_score(new):
	player_score = new

func nextlevel():
	current_level = current_level + 1
	turn_limit = turn_limit - 5
	if current_level > 3:
		current_level = 1
	if turn_limit <= 10:
		turn_limit = 10
	
