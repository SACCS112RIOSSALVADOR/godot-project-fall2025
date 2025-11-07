# ShapeBase.gd
# This is the shared logic for all tetromino-like shapes.
# Every shape script (I, J, L, O, S, T, Z) simply says:
#     extends "res://scripts/ShapeBase.gd"
# and inherits all this functionality.

extends CharacterBody2D

# --- Constants & Variables ---
const TILE_SIZE := 16                       # size of one grid step (pixels)
var sprite_node_pos_tween: Tween            # smooth animation for sprite movement
var current_rotation := 0.0                 # remembers last valid rotation
var is_selected := false                    # only the selected shape responds to input
var raycasts: Array[RayCast2D] = []         # automatically filled with this shape’s RayCast2Ds

# first child is usually the visible part of the shape (Node2D/Sprite2D/etc.)
@onready var shape_sprite: Node2D = get_child(0)

var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")
var team: bool

func set_team(flag):
	team = flag
	if team == true:
		loaded_data.team = true
	else:
		loaded_data.team = false
	print(team)
	pass

# --- Initialization ---
func _ready():
	
	#var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")
	if loaded_data:
		#print("Loaded character: " + loaded_data.character_name)
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
	
	# Collect all RayCast2D nodes under this shape so we don’t have to hard-code names.
	for child in get_children():
		if child is RayCast2D:
			raycasts.append(child)
		elif child is Node:
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
	print("Loaded RayCasts for", name, ":", raycasts.size())

# --- Mouse click selection ---
# Connected to the Area2D’s input_event signal.
# Ensures only one shape is active at a time (via the SelectionManager singleton).
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if SelectionManager.selected_shape != self:
			# Deselect any previously selected shape.
			if SelectionManager.selected_shape:
				SelectionManager.selected_shape.is_selected = false
			# Select this one.
			SelectionManager.selected_shape = self
			is_selected = true
			print("Selected", name)
		else:
			# Clicking again deselects it.
			is_selected = false
			SelectionManager.selected_shape = null
			print("Deselected", name)

# --- Collision detection ---
# Checks if any RayCast2D pointing in the given direction is colliding.
func check_collision(direction: String) -> bool:
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue  # skip missing or disabled rays

		# Transform the ray's local target position to global space to account for rotation
		var global_ray_dir := ray.target_position.rotated(global_rotation)
		
		# Compare each ray's GLOBAL direction to the desired movement direction.
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

# Shortcut: returns true if *any* direction is blocked.
func check_all_collisions() -> bool:
	return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")

# --- Rotation ---
# Rotates by 90°; cancels if rotation would collide.
func perform_rotation():
	var new_angle := fmod(global_rotation_degrees + 90, 360)
	global_rotation_degrees = new_angle
	if !check_all_collisions():
		current_rotation = new_angle
		print(name, "rotated to", current_rotation)
	else:
		# revert rotation if blocked
		global_rotation_degrees = current_rotation

# --- Input & Movement ---
func _physics_process(_delta: float) -> void:
	# Only move if this shape is selected.
	if !is_selected:
		return

	# Skip input while a tween animation is running.
	if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
		return

	var move_vec := Vector2.ZERO

	# Handle one keypress per movement step.
	if Input.is_action_just_pressed("ui_right") and !check_collision("right"):
		move_vec = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and !check_collision("left"):
		move_vec = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") and !check_collision("up"):
		move_vec = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and !check_collision("down"):
		move_vec = Vector2.DOWN

	# Execute move if any direction chosen.
	if move_vec != Vector2.ZERO:
		_move(move_vec)

	# Spacebar rotates.
	if Input.is_action_just_pressed("space"):
		perform_rotation()

# Moves the shape one grid unit and animates its sprite.
func _move(direction: Vector2):
	var new_pos := global_position + direction * TILE_SIZE
	global_position = new_pos  # update body immediately for physics consistency

	# Stop any previous tween before creating a new one.
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	# Create a new tween for smooth visual motion of the sprite only.
	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(
		shape_sprite, 
		"global_position", 
		new_pos, 
		0.185
	).set_trans(Tween.TRANS_SINE)
