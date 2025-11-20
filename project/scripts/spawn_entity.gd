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

var player_child_array: Array[Node] = []
var enemy_child_array: Array[Node] = []
var probablity_array: Array[float] = [0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14]
var my_dictionary = {}

var random_increase = 0.3 + randf()
var small_random_increase = randf()

var num_entities_on_start = 7

var player_positions = [Vector2(128,272),Vector2(104,216), Vector2(152,216),Vector2(80,256),Vector2(184,264),Vector2(120,248),Vector2(152,248)]
var foe_positions = [Vector2(128,96),Vector2(104,40), Vector2(152,40),Vector2(80,80),Vector2(184,88),Vector2(120,72),Vector2(152,72)]

var random_value = randi() % 2 #randomly get 1 or 0
var random_bool_from_randi = bool(randi() % 2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize() 
	
	for i in range(num_entities_on_start):
		var teromino_scene = tetrominos[i]
		var tetro_instance = teromino_scene.instantiate()
		#tetro_instance.set_rotation_degrees(90)
		tetro_instance.set_team(true)
		tetro_instance.position = player_positions[i]
		add_child(tetro_instance)
		player_child_array.append(tetro_instance)
		
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

#func returnplayerchild() -> void:
	#return player_child_array

#on enemy turn, do actions. Limited by steps
func enemy_ai(switch,steps):
	var temp_index = find_smallest_element_index(probablity_array)
	if switch == true:
		while steps > 0:
			
			check_if_killed(temp_index)
			
			var temp_x = "down"
			
			if  enemy_child_array[temp_index].get_current_position() > 240:
				temp_x = "up"
			elif enemy_child_array[temp_index].get_current_position() < 40:
				temp_x = "down"
			#
			if enemy_child_array[temp_index].perform_action(temp_x, random_bool_from_randi) == true:
				steps = steps -1
			elif enemy_child_array[temp_index].perform_action("left", random_bool_from_randi) == true:
				steps = steps -1
			elif enemy_child_array[temp_index].perform_action("right", random_bool_from_randi) == true:
				steps = steps -1
			
			probablity_array[temp_index] = probablity_array[temp_index] + random_increase #lowers odds of same chosen shape
			probablity_array[temp_index] = probablity_array[temp_index + 1 % enemy_child_array.size()] + small_random_increase #lowers odds of other shapes
			probablity_array[temp_index] = probablity_array[temp_index - 1 % enemy_child_array.size()] + small_random_increase #lowers odds of other shapes
			
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

func check_if_killed(index):
	if is_instance_valid(enemy_child_array[index]):
		enemy_child_array.remove_at(index)
		probablity_array.remove_at(index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
