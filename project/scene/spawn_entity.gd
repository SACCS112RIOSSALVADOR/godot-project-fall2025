extends Node2D

var tetrominos = [
	preload("res://project/scene/tetrominos/i_tetro.tscn"),
	preload("res://project/scene/tetrominos/j_tetro.tscn"),
	preload("res://project/scene/tetrominos/l_tetro.tscn"),
	preload("res://project/scene/tetrominos/o_tetro.tscn"),
	preload("res://project/scene/tetrominos/s_tetro.tscn"),
	preload("res://project/scene/tetrominos/t_tetro.tscn"),
	preload("res://project/scene/tetrominos/z_tetro.tscn"),
]

var num_entities_on_start = 7

var player_positions = [Vector2(120,272),Vector2(96,216), Vector2(144,216),Vector2(72,256),Vector2(176,264),Vector2(112,248),Vector2(144,248)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(num_entities_on_start):
		var teromino_scene = tetrominos[i]
		var tetro_instance = teromino_scene.instantiate()
		tetro_instance.position = player_positions[i]
		add_child(tetro_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
