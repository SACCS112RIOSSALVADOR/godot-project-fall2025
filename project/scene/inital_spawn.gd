extends Node2D

#@onready var I_tetromino = get_node("res://project/scene/i_tetro.tscn")
#@onready var L_tetromino = get_node("res://project/scene/l_tetro.tscn")
#@onready var J_tetromino = get_node("res://project/scene/j_tetro.tscn")
#@onready var O_tetromino = get_node("res://project/scene/o_tetro.tscn")
#@onready var S_tetromino = get_node("res://project/scene/s_tetro.tscn")
#@onready var T_tetromino = get_node("res://project/scene/t_tetro.tscn")
#@onready var Z_tetromino = get_node("res://project/scene/z_tetro.tscn")

var tetrominos = [
	preload("res://project/scene/i_tetro.tscn"),
	preload("res://project/scene/l_tetro.tscn"),
	preload("res://project/scene/j_tetro.tscn"),
	preload("res://project/scene/o_tetro.tscn"),
	preload("res://project/scene/s_tetro.tscn"),
	preload("res://project/scene/t_tetro.tscn"),
	preload("res://project/scene/z_tetro.tscn"),
]

var num_entities_on_start = 7

var player_positions = [Vector2(120,272),Vector2(96,232), Vector2(144,232),Vector2(72,256),Vector2(176,264),Vector2(112,248),Vector2(144,248)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(num_entities_on_start):
		var teromino_scene = tetrominos[i]
		var tetro_instance = teromino_scene.instantiate()
		tetro_instance.position = player_positions[i]
		add_child(tetro_instance)
		#spawn_entity()

func spawn_entity():
	#var entity = [I_tetromino, L_tetromino, J_tetromino, O_tetromino, S_tetromino,T_tetromino, Z_tetromino]
	
	for i in player_positions:
		var pos_vector = player_positions[i]
		tetrominos[i].position = pos_vector
		add_child(tetrominos[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
