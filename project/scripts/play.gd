extends Node2D

var score : int
const REWARD : int = 100
var game_running : bool 
var team : bool 
var pieces_remaining : int = 7
var is_paused : bool = false

# --- TURN SYSTEM ---
enum Turn { PLAYER, ENEMY }
var current_turn : int = Turn.PLAYER
var player_action_taken : bool = false
var enemy_action_taken : bool = false
# --------------------

# Reference to your pause menu panel (adjust the path to match your scene tree)
@onready var pause_panel = $PausePanel  # Change this to match your actual node path
@onready var game_over_label = $GameOverLabel   # adjust path if needed

func _ready() -> void:
	if pause_panel:
		pause_panel.visible = false
	if game_over_label:
		game_over_label.visible = false     # hide when game starts

	score = 0
	if score_label:
		score_label.text = "Score: 0"

	get_tree().paused = false
	game_running = true
	is_paused = false

	_start_player_turn()  # NEW

func _start_player_turn() -> void:
	current_turn = Turn.PLAYER
	player_action_taken = false
	enemy_action_taken = false
	print("=== PLAYER TURN ===")

func _start_enemy_turn() -> void:
	current_turn = Turn.ENEMY
	enemy_action_taken = false
	print("=== ENEMY TURN ===")
	_run_enemy_turn()   # this is fine

func is_player_turn() -> bool:
	return current_turn == Turn.PLAYER

func can_player_act() -> bool:
	return game_running and not is_paused and is_player_turn() and not player_action_taken
	
# Called from ShapeBase when the player attempts to move a unit
func on_player_move_request(unit: Node, dir: Vector2) -> void:
	if not can_player_act():
		return
	player_action_taken = true
	await unit._move(dir)
	_start_enemy_turn()

# Called from ShapeBase when the player successfully attacks
func on_player_attack_performed() -> void:
	if not can_player_act():
		return
	player_action_taken = true
	_start_enemy_turn()

func _get_units(group_name: String) -> Array[Node2D]:
	var units: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node2D:
			units.append(n)
	return units

func _get_closest_player_to(enemy: Node2D) -> Node2D:
	var players: Array[Node2D] = _get_units("player_units")
	var closest: Node2D = null
	var best_dist: float = INF

	for p in players:
		if not is_instance_valid(p):
			continue

		var d: float = p.global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			closest = p

	return closest

func _candidate_directions(from: Node2D, to: Node2D) -> Array[Dictionary]:
	var delta: Vector2 = to.global_position - from.global_position
	var candidates: Array[Dictionary] = []

	var horizontal_first: bool = abs(delta.x) >= abs(delta.y)

	if horizontal_first:
		if delta.x > 0.0:
			candidates.append({"vec": Vector2.RIGHT, "name": "right"})
		elif delta.x < 0.0:
			candidates.append({"vec": Vector2.LEFT, "name": "left"})

		if delta.y > 0.0:
			candidates.append({"vec": Vector2.DOWN, "name": "down"})
		elif delta.y < 0.0:
			candidates.append({"vec": Vector2.UP, "name": "up"})
	else:
		if delta.y > 0.0:
			candidates.append({"vec": Vector2.DOWN, "name": "down"})
		elif delta.y < 0.0:
			candidates.append({"vec": Vector2.UP, "name": "up"})

		if delta.x > 0.0:
			candidates.append({"vec": Vector2.RIGHT, "name": "right"})
		elif delta.x < 0.0:
			candidates.append({"vec": Vector2.LEFT, "name": "left"})

	return candidates

func _run_enemy_turn() -> void:
	# DO NOT call _start_enemy_turn() here

	await get_tree().create_timer(0.25).timeout

	var enemies: Array[Node2D] = _get_units("enemy_units")
	enemies = enemies.filter(func(e: Node2D) -> bool: return is_instance_valid(e))
	if enemies.is_empty():
		_start_player_turn()
		return

	var enemy: Node2D = enemies[0]
	if enemy == null or not is_instance_valid(enemy):
		_start_player_turn()
		return

	# 1) Try to attack if someone is adjacent
	if enemy.has_method("check_adjacent_enemies"):
		var adj: Array = enemy.check_adjacent_enemies()
		if adj.size() > 0:
			var target: Node2D = adj[0]
			if enemy.has_method("initiate_combat"):
				enemy.initiate_combat(target)
			await get_tree().create_timer(0.25).timeout
			enemy_action_taken = true
			_start_player_turn()
			return

	# 2) Otherwise, move 1 tile toward the closest player
	var target_player: Node2D = _get_closest_player_to(enemy)
	if target_player:
		var candidates: Array[Dictionary] = _candidate_directions(enemy, target_player)
		for c in candidates:
			var dir_vec: Vector2 = c["vec"]
			var dir_name: String = c["name"]

			if dir_vec == Vector2.ZERO:
				continue

			if enemy.has_method("check_collision") and enemy.check_collision(dir_name):
				continue

			if enemy.has_method("_move"):
				await enemy._move(dir_vec)
				break

	enemy_action_taken = true
	_start_player_turn()

func _process(_delta: float) -> void:
	# Check for pause input
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key
		toggle_pause()
	
	if game_running and !is_paused:
		pass

func toggle_pause():
	if not game_running:
		return   # can't pause/unpause when game is over

	is_paused = !is_paused

	if is_paused:
		get_tree().paused = true
		if pause_panel:
			pause_panel.visible = true
	else:
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
	if game_over_label:
		game_over_label.visible = false

func clear_board():
	pass
	
func check_game_over():
	# No more player units or no more enemy units => game over
	var players := _get_alive_units("player_units")
	var enemies := _get_alive_units("enemy_units")

	if players.is_empty() or enemies.is_empty():
		_on_game_over()
		
@onready var score_label = $ScoreLabel  # adjust the path if needed

func add_score(amount: int):
	score += amount
	if score_label:
		score_label.text = "Score: %d" % score

func _get_alive_units(group_name: String) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node2D and is_instance_valid(n) and not n.is_queued_for_deletion():
			result.append(n)
	return result

func _on_game_over():
	if not game_running:
		return  # already handled

	game_running = false
	is_paused = true

	get_tree().paused = true

	if pause_panel:
		pause_panel.visible = true
	if game_over_label:
		game_over_label.visible = true
