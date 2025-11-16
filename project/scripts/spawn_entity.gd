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

var enemy_child_array: Array[Node] = []
var num_entities_on_start = 7

var player_positions = [Vector2(128,272),Vector2(104,216), Vector2(152,216),Vector2(80,256),Vector2(184,264),Vector2(120,248),Vector2(152,248)]

var foe_positions = [Vector2(128,96),Vector2(104,40), Vector2(152,40),Vector2(80,80),Vector2(184,88),Vector2(120,72),Vector2(152,72)]

func _ready() -> void:
	for i in range(num_entities_on_start):
		var teromino_scene = tetrominos[i]

		# PLAYER UNIT
		var tetro_instance = teromino_scene.instantiate()
		tetro_instance.set_team(true)
		tetro_instance.position = player_positions[i]
		add_child(tetro_instance)
		tetro_instance.add_to_group("player_units")  # NEW

		# ENEMY UNIT
		var foe_tetro_scene = tetrominos[i]
		var foe_instance = foe_tetro_scene.instantiate()
		foe_instance.set_team(false)
		foe_instance.position = foe_positions[i]
		add_child(foe_instance)
		foe_instance.add_to_group("enemy_units")     # NEW

		enemy_child_array.append(foe_instance)

func _process(_delta: float) -> void:
	pass
