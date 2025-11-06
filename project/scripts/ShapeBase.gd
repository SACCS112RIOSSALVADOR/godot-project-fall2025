# ShapeBase.gd
extends CharacterBody2D

# --- Constants & Variables ---
const TILE_SIZE := 16
var sprite_node_pos_tween: Tween
var current_rotation := 0.0
var is_selected := false
var raycasts: Array[RayCast2D] = []

@onready var shape_sprite: Node2D = get_child(0)

# --- Initialization ---
func _ready():
<<<<<<< Updated upstream
	
	var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")
	if loaded_data:
		#print("Loaded character: " + loaded_data.character_name)
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
	
	# Collect all RayCast2D nodes under this shape so we don’t have to hard-code names.
=======
	# Collect all RayCast2D nodes
>>>>>>> Stashed changes
	for child in get_children():
		if child is RayCast2D:
			raycasts.append(child)
		elif child is Node:
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
	print("Loaded RayCasts for", name, ":", raycasts.size())

# --- Mouse click selection ---
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if SelectionManager.selected_shape != self:
			if SelectionManager.selected_shape:
				SelectionManager.selected_shape.is_selected = false
			SelectionManager.selected_shape = self
			is_selected = true
			print("Selected", name)
		else:
			is_selected = false
			SelectionManager.selected_shape = null
			print("Deselected", name)

# --- Collision detection ---
func check_collision(direction: String) -> bool:
	# Force all raycasts to update before checking
	for ray in raycasts:
		if ray:
			ray.force_raycast_update()
	
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue

		# Transform ray direction to global space (accounts for rotation)
		var global_ray_dir := ray.target_position.rotated(global_rotation)
		
		# Check if ray is pointing in the desired direction AND colliding
		match direction:
			"right":
				if global_ray_dir.x > 0 and ray.is_colliding():
					return true
			"left":
				if global_ray_dir.x < 0 and ray.is_colliding():
					return true
			"up":
				if global_ray_dir.y < 0 and ray.is_colliding():
					return true
			"down":
				if global_ray_dir.y > 0 and ray.is_colliding():
					return true
	return false

func check_all_collisions() -> bool:
	return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")

# --- Rotation ---
func perform_rotation():
	var new_angle := fmod(global_rotation_degrees + 90, 360)
	global_rotation_degrees = new_angle
	
	# Force RayCasts to update immediately after rotation
	for ray in raycasts:
		if ray:
			ray.force_raycast_update()
	
	if !check_all_collisions():
		current_rotation = new_angle
		print(name, "rotated to", current_rotation)
	else:
		# Revert rotation if blocked
		global_rotation_degrees = current_rotation

# --- Input & Movement ---
func _physics_process(_delta: float) -> void:
	if !is_selected:
		return

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

	if Input.is_action_just_pressed("space"):
		perform_rotation()

func _move(direction: Vector2):
	var new_pos := global_position + direction * TILE_SIZE
	global_position = new_pos

	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
<<<<<<< Updated upstream
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(
		shape_sprite, 
		"global_position", 
		new_pos, 
		0.185
	).set_trans(Tween.TRANS_SINE)
=======
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.18).set_trans(Tween.TRANS_SINE)
>>>>>>> Stashed changes
