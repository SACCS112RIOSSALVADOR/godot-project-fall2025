extends TileMap

# ============================================
# PIECE ROTATION DEFINITIONS
# ============================================
# Each piece has rotation states defined by Vector2i coordinates

# I piece - straight line
var i_0 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]  # Horizontal
var i_90 := [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]  # Vertical
var i := [i_0, i_90, i_0, i_90]  # Simplified to 2 rotations

# O piece - square (no rotation needed)
var o_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o := [o_0, o_0, o_0, o_0]  # Same in all rotations

# T piece - T-shaped
var t_0 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]  # T pointing up
var t_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]  # T pointing right
var t := [t_0, t_90, t_0, t_90]  # Simplified to 2 rotations

# ============================================
# GAME VARIABLES
# ============================================

# Piece selection variables
var shapes := [i, o, t]  # Reduced piece set
var shapes_full := shapes.duplicate()  # Full set for refilling

# Grid dimensions
const COLS : int = 10  # Width of play area
const ROWS : int = 20  # Height of play area
const start_pos := Vector2i(5, 1)  # Starting position (top center)

# Current piece variables
var cur_pos : Vector2i  # Current position of active piece
var piece_type  # Current piece shape
var rotation_index : int = 0  # Current rotation state (0-3)
var active_piece : Array  # Array of Vector2i positions for current piece
var piece_atlas : Vector2i  # Atlas coordinates for piece texture

# Tilemap variables
var tile_id : int = 0  # ID of tile to use
var board_layer : int = 0  # Layer for landed pieces
var active_layer : int = 1  # Layer for moving piece

# ============================================
# CORE FUNCTIONS
# ============================================

# Initialize game when node enters scene
func _ready():
	new_game()

# Start a new game
func new_game():
	piece_type = pick_piece()  # Select first piece
	piece_atlas = Vector2i(shapes_full.find(piece_type), 0)  # Get texture coordinates
	create_piece()  # Spawn the piece

# Handle input every frame
func _process(delta):
	# Simple controls - one key at a time
	if Input.is_action_just_pressed("ui_left"):
		move_piece(Vector2i.LEFT)  # Move left
	elif Input.is_action_just_pressed("ui_right"):
		move_piece(Vector2i.RIGHT)  # Move right
	elif Input.is_action_just_pressed("ui_down"):
		move_piece(Vector2i.DOWN)  # Move down
	elif Input.is_action_just_pressed("ui_up"):
		rotate_piece()  # Rotate clockwise

# ============================================
# PIECE MANAGEMENT
# ============================================

# Randomly select a piece using bag system
# Ensures fair distribution of pieces
func pick_piece():
	if shapes.is_empty():
		shapes = shapes_full.duplicate()  # Refill bag when empty
	shapes.shuffle()  # Randomize order
	return shapes.pop_front()  # Take first piece

# Create a new piece at starting position
func create_piece():
	cur_pos = start_pos  # Reset to top center
	rotation_index = 0  # Start at default rotation
	active_piece = piece_type[rotation_index]  # Get block positions
	draw_piece(active_piece, cur_pos, piece_atlas)  # Render piece

# Remove current piece from active layer
func clear_piece():
	for i in active_piece:
		erase_cell(active_layer, cur_pos + i)

# Draw piece on tilemap at specified position
# piece: Array of Vector2i positions
# pos: Base position for the piece
# atlas: Texture atlas coordinates
func draw_piece(piece, pos, atlas):
	for i in piece:
		set_cell(active_layer, pos + i, tile_id, atlas)

# ============================================
# MOVEMENT & ROTATION
# ============================================

# Rotate piece clockwise by 90 degrees
func rotate_piece():
	if can_rotate():  # Check if rotation is valid
		clear_piece()  # Remove current orientation
		rotation_index = (rotation_index + 1) % 4  # Advance rotation
		active_piece = piece_type[rotation_index]  # Get new positions
		draw_piece(active_piece, cur_pos, piece_atlas)  # Redraw

# Move piece in specified direction
# dir: Direction vector (LEFT, RIGHT, or DOWN)
func move_piece(dir):
	if can_move(dir):  # Check if move is valid
		clear_piece()  # Remove from old position
		cur_pos += dir  # Update position
		draw_piece(active_piece, cur_pos, piece_atlas)  # Draw at new position
	elif dir == Vector2i.DOWN:  # Piece can't move down (landed)
		land_piece()  # Lock piece to board
		piece_type = pick_piece()  # Get next piece
		piece_atlas = Vector2i(shapes_full.find(piece_type), 0)  # Get texture
		create_piece()  # Spawn new piece

# Check if piece can move in direction
# Returns true if all blocks would be in valid positions
func can_move(dir):
	for i in active_piece:
		if not is_free(i + cur_pos + dir):  # Check each block
			return false  # Collision detected
	return true  # All blocks can move

# Check if piece can rotate
# Returns true if all blocks in next rotation are valid
func can_rotate():
	var temp_rotation_index = (rotation_index + 1) % 4  # Calculate next rotation
	for i in piece_type[temp_rotation_index]:
		if not is_free(i + cur_pos):  # Check each block position
			return false  # Collision detected
	return true  # Can rotate

# Check if grid position is empty
# Returns true if cell is free, false if occupied or out of bounds
func is_free(pos):
	return get_cell_source_id(board_layer, pos) == -1

# Lock current piece onto board layer
# Transfers blocks from active layer to board layer
func land_piece():
	for i in active_piece:
		erase_cell(active_layer, cur_pos + i)  # Remove from active
		set_cell(board_layer, cur_pos + i, tile_id, piece_atlas)  # Add to board
