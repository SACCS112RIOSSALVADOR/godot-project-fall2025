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
var probablity_array: Array[float] = [0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14]
var my_dictionary = {}

var random_increase = 0.3 + randf()

var num_entities_on_start = 7

var player_positions = [Vector2(128,272),Vector2(104,216), Vector2(152,216),Vector2(80,256),Vector2(184,264),Vector2(120,248),Vector2(152,248)]

var foe_positions = [Vector2(128,96),Vector2(104,40), Vector2(152,40),Vector2(80,80),Vector2(184,88),Vector2(120,72),Vector2(152,72)]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(num_entities_on_start):
		var teromino_scene = tetrominos[i]
		var tetro_instance = teromino_scene.instantiate()
		#tetro_instance.set_rotation_degrees(90)
		tetro_instance.set_team(true)
		tetro_instance.position = player_positions[i]
		add_child(tetro_instance)
		
		var foe_tetro_scene = tetrominos[i]
		var foe_instance = foe_tetro_scene.instantiate()
		foe_instance.set_team(false)
		foe_instance.position = foe_positions[i]
		add_child(foe_instance)
		
		#later pick an instance at random and (bias downward) movemoent. Only attack if in range
		enemy_child_array.append(foe_instance)
		#enemy_child_array[i].print_hi()
		if enemy_child_array[i].has_method("print_hi"):
			print("greetings")
			enemy_child_array[i].print_hi()

#on enemy turn, do actions. Limited by steps
func enemy_ai(switch,steps):
	var coll: bool = false
	if switch == true:
		while steps > 0:
			var temp_index = find_smallest_element_index(probablity_array)
			if coll == true:
				pass
			enemy_child_array[temp_index].move_down()
			for i in range(enemy_child_array.size()):
				pass
			pass
		switch = false
	else:
		return
	pass

#bias selection of an index
func find_smallest_element_index(arr):
	if not arr:
		return -1
	
	var temp_array = []
	var smallest_value = arr[0]
	var smallest_index = 0
	
	for i in range(7):
		if arr[i] < smallest_value:
			smallest_value = arr[i]
			smallest_index = i
			
		elif arr[i] == smallest_value:
			temp_array[i] = i
	if temp_array.size() > 1:
		smallest_index = temp_array.pick_random
	return smallest_index


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
