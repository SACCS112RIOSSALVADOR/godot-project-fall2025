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

signal change_turn

var turn : bool #true = player turn, #false = foe's turn

var playerChildArray: Array[Node] = []
var enemyChildArray: Array[Node] = []
var probabilityArray: Array[float] = [0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14]
var myDictionary = {}

var randomIncrease = 0.3 + randf()
var smallRandomIncrease = randf()

var numEntitiesOnStart = 7
var steps_left = 5

var playerPositions: Array[Vector2] = [
Vector2(128, 272), Vector2(104, 216), Vector2(152, 216), 
Vector2(80, 256), Vector2(184, 264), Vector2(120, 248), 
Vector2(152, 248)
]
var foePositions: Array[Vector2] = [
Vector2(128, 96), Vector2(104, 40), Vector2(152, 40), 
Vector2(80, 80), Vector2(184, 88), Vector2(120, 72), 
Vector2(152, 72)
]

var randomValue = randi() % 2 #randomly get 1 or 0
var randomBoolFromRandi = bool(randi() % 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	turn = true
	randomize()
	for i in range(numEntitiesOnStart):
		var tetrominoScene = tetrominos[i]
		var tetroInstance = tetrominoScene.instantiate()
		tetroInstance.set_team(true)
		tetroInstance.position = playerPositions[i]
		add_child(tetroInstance)
		playerChildArray.append(tetroInstance)

		var foeTetroScene = tetrominos[i]
		var foeInstance = foeTetroScene.instantiate()
		foeInstance.set_team(false)
		foeInstance.position = foePositions[i]
		add_child(foeInstance)
		enemyChildArray.append(foeInstance)

		if enemyChildArray[i].has_method("print_hi"):
			print("greetings")
			enemyChildArray[i].print_hi()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if turn == true:
		get_steps_from_array(playerChildArray)
		change_turn_order(playerChildArray)
	if turn == false:
		pass #remove later
		enemy_ai(true, 1)
	pass

# On enemy turn, do actions. Limited by steps
func enemy_ai(switch: bool, steps: int):
	var kill_switch = 4 # if their are X failures in a row. AI forfeits turn
	if switch == true:
		while steps > 0:
			var tempIndex = find_smallest_element_index(probabilityArray)
			check_if_killed(tempIndex)
			
			var vetrical_switch: bool = true #true = down, flase = down
			var action = ""
			
			if vetrical_switch == true:
				action = "down"
			else:
				action = "up"
			if enemyChildArray[tempIndex].get_current_position() > 240:
							action = "up"
			elif enemyChildArray[tempIndex].get_current_position() < 40:
							action = "down"
			else:
				if randi() % 2 == 0:
					action = "left"
				else:
					action = "right"
			if enemyChildArray[tempIndex].perform_action(action, randomBoolFromRandi):
				steps -= 1
			else:
				if action == "down" and vetrical_switch == true:
					vetrical_switch = false
					kill_switch -= 1
				elif action == "up" and vetrical_switch == false:
					vetrical_switch = true
					kill_switch -= 1
			update_probability_array(tempIndex)
			if kill_switch <= 0:
				switch = false
		switch = false

func update_probability_array(index: int):
	probabilityArray[index] += randomIncrease
	probabilityArray[(index + 1) % enemyChildArray.size()] += smallRandomIncrease
	probabilityArray[(index - 1) % enemyChildArray.size()] += smallRandomIncrease

func check_if_killed(index: int):
	if not is_instance_valid(enemyChildArray[index]):
		enemyChildArray.remove_at(index)
		probabilityArray.remove_at(index)

# Bias selection of an index
func find_smallest_element_index(arr: Array[float]) -> int:
	if arr.is_empty():
		return -1
		
	var smallestValue = arr[0]
	var smallestIndex = 0
	
	for i in range(len(arr)):
		if arr[i] < smallestValue:
			smallestValue = arr[i]
			smallestIndex = i
			
	return smallestIndex

func get_steps_from_array(arr: Array[Node]):
	if arr.is_empty():
		return -1
	for i in range(len(arr)):
		steps_left = steps_left - arr[i].get_steps()
	return steps_left

func change_turn_order(arr: Array[Node]):
	if steps_left <= 0:
		if arr.is_empty():
			return -1
		for i in range(len(arr)):
			arr[i].change_turn_var()
			change_turn.emit()
		steps_left = 5
		turn = not turn
	return 

func get_turn(switch: bool):
	turn = switch

func delayed_action(): #Used to give the AI more natural movemoent
	print("Action started!")
	await get_tree().create_timer(0.3).timeout # Pauses for 0.3 seconds
	print("Action resumed after 1 seconds!")
