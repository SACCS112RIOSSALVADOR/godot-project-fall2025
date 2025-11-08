extends CharacterBody2D

# Constants
const TILE_SIZE := 16  # Size of each grid tile in pixels

# Movement and animation variables
var sprite_node_pos_tween: Tween  # Tween for smooth sprite movement animation
var current_rotation := 0.0  # Current rotation angle of the shape in degrees
var is_selected := false  # Whether this shape is currently selected by the player
var raycasts: Array[RayCast2D] = []  # Array of raycasts used for collision detection

# Node references
@onready var shape_sprite: Sprite2D = get_child(1)  # Reference to the visual sprite
@onready var area_collission: Area2D = get_child(2)
# Sound effect players
@onready var click_sound: AudioStreamPlayer = $ClickSound  # Sound for selecting/deselecting
@onready var move_sound: AudioStreamPlayer = $MoveSound  # Sound for moving the shape
@onready var rotate_sound: AudioStreamPlayer = $RotateSound  # Sound for rotating the shape

# Unit data
var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")  # Unit stats and properties
var team: bool  # Which team this shape belongs to

# Set which team this shape belongs to
func set_team(flag):
	team = flag
	if team == true:
		loaded_data.team = true
	else:
		loaded_data.team = false
	print(team)

# Initialize the shape and collect all raycasts for collision detection
func _ready():
	# Load and verify unit data
	if loaded_data:
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
	
	if team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)
	
	# Collect all RayCast2D nodes from children (both direct and nested)
	for child in get_children():
		if child is RayCast2D:
			raycasts.append(child)
		elif child is Node:
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
	print("Loaded RayCasts for", name, ":", raycasts.size())

# Handle mouse clicks on the shape for selection/deselection
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Check if left mouse button was clicked
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# If this shape is not currently selected
		if SelectionManager.selected_shape != self:
			# Deselect the previously selected shape if any
			if SelectionManager.selected_shape:
				SelectionManager.selected_shape.is_selected = false
			# Select this shape
			SelectionManager.selected_shape = self
			is_selected = true
			print("Selected", name)
			# Play click sound when selecting
			if click_sound:
				click_sound.play()
		# If this shape is already selected, deselect it
		else:
			is_selected = false
			SelectionManager.selected_shape = null
			print("Deselected", name)
			# Play click sound when deselecting
			if click_sound:
				click_sound.play()

# Check if there's a collision in a specific direction
func check_collision(direction: String) -> bool:
	# Loop through all raycasts attached to this shape
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue 

		# Get the raycast direction in global coordinates (accounting for rotation)
		var global_ray_dir := ray.target_position.rotated(global_rotation)
		
		# Check if the raycast is pointing in the specified direction and colliding
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

# Check if there are collisions in any direction
func check_all_collisions() -> bool:
	return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")

# Rotate the shape 90 degrees clockwise
func perform_rotation():
	# Calculate new rotation angle (add 90 degrees and wrap at 360)
	var new_angle := fmod(global_rotation_degrees + 90, 360)
	global_rotation_degrees = new_angle
	# Check if the new rotation causes any collisions
	if !check_all_collisions():
		# Rotation is valid, save it
		current_rotation = new_angle
		print(name, "rotated to", current_rotation)
		# Play rotate sound on successful rotation
		if rotate_sound:
			rotate_sound.play()
	else:
		# Rotation causes collision, revert to previous rotation
		global_rotation_degrees = current_rotation

# Handle player input for movement and rotation (called every physics frame)
func _physics_process(_delta: float) -> void:
	# Only process input if this shape is selected
	if !is_selected:
		return

	# Don't accept new input while a movement animation is playing
	if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
		return

	# Check for directional input and collision
	var move_vec := Vector2.ZERO

	if Input.is_action_just_pressed("ui_right") and !check_collision("right"):
		move_vec = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and !check_collision("left"):
		move_vec = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") and !check_collision("up"):
		move_vec = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and !check_collision("down"):
		move_vec = Vector2.DOWN

	# Execute movement if a valid direction was pressed
	if move_vec != Vector2.ZERO:
		_move(move_vec)

	# Handle rotation input (spacebar)
	if Input.is_action_just_pressed("space"):
		perform_rotation()

# Move the shape in the specified direction with smooth animation
func _move(direction: Vector2):
	# Calculate new position (move by one tile in the direction)
	var new_pos := global_position + direction * TILE_SIZE
	global_position = new_pos

	# Play move sound
	if move_sound:
		move_sound.play()

	# Stop any existing movement animation
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	# Create smooth animation for the sprite to move to the new position
	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.185).set_trans(Tween.TRANS_SINE)
