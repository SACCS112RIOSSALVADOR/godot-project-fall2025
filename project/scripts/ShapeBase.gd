extends CharacterBody2D

# =================== Signals / adjacency cache ===================
signal adjacent_unit_entered(unit: Node, direction: String, is_enemy: bool)
signal adjacent_unit_exited(unit: Node, direction: String, is_enemy: bool)

var _adj_prev_hit: Dictionary = {}   # RayCast2D -> Node


# =================== Constants ===================
const TILE_SIZE := 16  # Size of each grid tile in pixels


# =================== Movement & state ===================
var sprite_node_pos_tween: Tween            # Tween for smooth sprite movement animation
var current_rotation := 0.0                 # Current rotation angle in degrees
var is_selected := false                    # Whether this shape is currently selected
var raycasts: Array[RayCast2D] = []         # Raycasts used for collision detection


# =================== Node references ===================
@onready var shape_sprite: Sprite2D = get_child(1)  # Visual sprite
@onready var area_collission: Area2D = get_child(2) # Clickable Area2D

# Sound effects
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var rotate_sound: AudioStreamPlayer = $RotateSound


# =================== Unit data ===================
var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")
var team: bool   # Which team this shape belongs to


# =================== Team setter ===================
func set_team(flag: bool) -> void:
	team = flag
	if team == true:
		loaded_data.team = true
	else:
		loaded_data.team = false
	print(team)


# =================== Ready ===================
func _ready() -> void:
	# Load and verify unit data
	if loaded_data:
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")

	# Tint foes
	if team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)

	# Collect all RayCast2D nodes from children (direct and nested)
	for child in get_children():
		if child is RayCast2D:
			raycasts.append(child)
		elif child is Node:
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
	print("Loaded RayCasts for ", name, " : ", str(raycasts.size()))

	# Prime adjacency state (no signals on first frame)
	_adj_update(true)


# =================== Click handling (with right-click) ===================
func _on_area_2d_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# --- RIGHT CLICK ---
		if event.button_index == MOUSE_BUTTON_RIGHT:
			viewport.set_input_as_handled()
			print("RMB on:", name, " at ", get_global_mouse_position())
			# Example action on right-click (optional):
			# perform_rotation()
			return

		# --- LEFT CLICK (select / deselect) ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if SelectionManager.selected_shape != self:
				if SelectionManager.selected_shape:
					SelectionManager.selected_shape.is_selected = false
				SelectionManager.selected_shape = self
				is_selected = true
				print("Selected", name)
				if click_sound:
					click_sound.play()
			else:
				is_selected = false
				SelectionManager.selected_shape = null
				print("Deselected", name)
				if click_sound:
					click_sound.play()


# =================== Collision queries ===================
func check_collision(direction: String) -> bool:
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue

		# Ray direction in global coordinates (accounting for rotation)
		var global_ray_dir: Vector2 = ray.target_position.rotated(global_rotation)

		match direction:
			"right":
				if global_ray_dir.x > 0.0 and ray.is_colliding():
					return true
			"left":
				if global_ray_dir.x < 0.0 and ray.is_colliding():
					return true
			"up":
				if global_ray_dir.y < 0.0 and ray.is_colliding():
					return true
			"down":
				if global_ray_dir.y > 0.0 and ray.is_colliding():
					return true
	return false


func check_all_collisions() -> bool:
	return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")


# =================== Rotation ===================
func perform_rotation() -> void:
	var new_angle := fmod(global_rotation_degrees + 90.0, 360.0)
	global_rotation_degrees = new_angle
	if !check_all_collisions():
		current_rotation = new_angle
		print(name, " rotated to ", str(current_rotation))
		if rotate_sound:
			rotate_sound.play()
	else:
		global_rotation_degrees = current_rotation


# =================== Per-physics input ===================
func _physics_process(_delta: float) -> void:
	if !is_selected:
		return

	# Block input while tween animates
	if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
		return

	var move_vec := Vector2.ZERO

	if Input.is_action_just_pressed("ui_right") and !check_collision("right"):
		move_vec = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and !check_collision("left"):
		move_vec = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") and !check_collision("up"):
		move_vec = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and !check_collision("down"):
		move_vec = Vector2.DOWN

	if move_vec != Vector2.ZERO:
		_move(move_vec)

	# Space = rotate
	if Input.is_action_just_pressed("space"):
		perform_rotation()

	# After movement/rotation, update adjacency & fire signals
	_adj_update()


# =================== Movement (tweened) ===================
func _move(direction: Vector2) -> void:
	var new_pos: Vector2 = global_position + direction * float(TILE_SIZE)
	global_position = new_pos

	if move_sound:
		move_sound.play()

	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.185).set_trans(Tween.TRANS_SINE)



# =================== Adjacency (script-only) helpers ===================
# Recomputes adjacency from your existing raycasts array.
# If 'prime == true', it only caches the state (no signals).
func _adj_update(prime: bool=false) -> void:
	var now: Dictionary = {}  # RayCast2D -> Node

	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue

		ray.force_raycast_update()
		if !ray.is_colliding():
			continue

		# One-tile distance gate so long rays don't trigger far away
		var origin: Vector2 = ray.to_global(Vector2.ZERO)
		var hit_p: Vector2 = ray.get_collision_point()
		if origin.distance_to(hit_p) > float(TILE_SIZE) * 1.1:
			continue

		var col: Object = ray.get_collider()
		var unit: Node = _adj_find_unit_root(col)
		if unit != null and unit != self:
			now[ray] = unit
			if !_adj_prev_hit.has(ray) and !prime:
				var dir: String = _adj_direction_of(ray)
				emit_signal("adjacent_unit_entered", unit, dir, _adj_is_enemy(unit))

	# Anything present last frame but missing now → exit
	if !prime:
		for r in _adj_prev_hit.keys():
			if !now.has(r):
				var u: Node = (_adj_prev_hit[r] as Node)
				if u != null:
					var d: String = _adj_direction_of(r)
					emit_signal("adjacent_unit_exited", u, d, _adj_is_enemy(u))

	_adj_prev_hit = now


# Direction label ("up/down/left/right") for a given ray, relative to *current* rotation
func _adj_direction_of(ray: RayCast2D) -> String:
	var v: Vector2 = ray.target_position.rotated(global_rotation)
	if abs(v.x) >= abs(v.y):
		return "right" if v.x >= 0.0 else "left"
	else:
		return "down" if v.y >= 0.0 else "up"


# Walk up to find a node that "looks like" one of your units (has loaded_data/team)
func _adj_find_unit_root(x: Object) -> Node:
	var n: Node = x as Node
	while n != null:
		var has_prop: bool = false

		var ud: Variant = n.get("loaded_data")
		if ud != null and typeof(ud) != TYPE_NIL:
			has_prop = true

		if !has_prop:
			var t: Variant = n.get("team")
			if t != null and typeof(t) == TYPE_BOOL:
				has_prop = true

		if has_prop:
			return n
		n = n.get_parent()
	return null


# Enemy if team differs. Prefer loaded_data.team; fall back to node.team.
func _adj_is_enemy(unit: Node) -> bool:
	var my_team: Variant = _adj_team_of(self)
	var their_team: Variant = _adj_team_of(unit)
	if typeof(my_team) != TYPE_BOOL or typeof(their_team) != TYPE_BOOL:
		return false
	return bool(my_team) != bool(their_team)


func _adj_team_of(node: Node) -> Variant:
	if node == null:
		return null
	var ud: Variant = node.get("loaded_data")
	if ud != null and typeof(ud) != TYPE_NIL:
		var obj: Object = ud as Object
		var t: Variant = obj.get("team")
		if typeof(t) == TYPE_BOOL:
			return t
	var t2: Variant = node.get("team")
	if typeof(t2) == TYPE_BOOL:
		return t2
	return null


# Convenience query you can call from anywhere:
func has_enemy_adjacent(direction: String) -> bool:
	var dir: String = direction.to_lower()
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue
		var d: String = _adj_direction_of(ray)
		if d != dir:
			continue
		ray.force_raycast_update()
		if ray.is_colliding():
			var origin: Vector2 = ray.to_global(Vector2.ZERO)
			var p: Vector2 = ray.get_collision_point()
			if origin.distance_to(p) <= float(TILE_SIZE) * 1.1:
				var collider: Object = ray.get_collider()
				var u: Node = _adj_find_unit_root(collider)
				if u != null and _adj_is_enemy(u):
					return true
	return false
# =================== end adjacency helpers ===================
