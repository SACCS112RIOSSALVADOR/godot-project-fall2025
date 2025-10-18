extends TileMap

# ============================================
# PIECE ROTATION DEFINITIONS
# ============================================

"""
Define the four rotation states (0°, 90°, 180°, 270°) of the Tetris pieces.
Each list contains four Vector2i coordinates representing the relative positions of the blocks that make up the piece in each rotation. These positions are typically used for rendering or collision detection in a grid-based system.
Group all rotation states into a single list for easy access by rotation index (0 to 3)
"""
# I piece - straight line piece
var i_0 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
var i_90 := [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
var i_180 := [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
var i_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
var i := [i_0, i_90, i_180, i_270]

# T piece - T-shaped piece
var t_0 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var t_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var t := [t_0, t_90, t_180, t_270]

# O piece - square piece (same in all rotations)
var o_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_90 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_180 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o := [o_0, o_90, o_180, o_270]

# Z piece - zigzag piece (left orientation)
var z_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
var z_90 := [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var z_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var z_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
var z := [z_0, z_90, z_180, z_270]

# S piece - zigzag piece (right orientation)
var s_0 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
var s_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var s_180 := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)]
var s_270 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var s := [s_0, s_90, s_180, s_270]

# L piece - L-shaped piece (standard L)
var l_0 := [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var l_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var l_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)]
var l_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
var l := [l_0, l_90, l_180, l_270]

# J piece - J-shaped piece (reverse L)
var j_0 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var j_90 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]
var j_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var j_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
var j := [j_0, j_90, j_180, j_270]

# ============================================
# GAME VARIABLES
# ============================================

# Piece selection variables
var shapes := [i, t, o, z, s, l, j]  # Current pool of available pieces
var shapes_full := shapes.duplicate()  # Full set of all pieces (for refilling the pool)

# Grid dimensions
const COLS : int = 10  # Width of the play area
const ROWS : int = 20  # Height of the play area

# Movement control variables
const directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]  # Possible movement directions
var steps : Array  # Accumulates input for each direction [left, right, down]
const steps_req : int = 50  # Number of steps required before piece moves
const start_pos := Vector2i(5, 1)  # Starting position for new pieces (top center)
var cur_pos : Vector2i  # Current position of the active piece
var speed : float  # Automatic downward movement speed
const ACCEL : float = 0.25 # Increase Speed Variable 

# Current game piece variables
var piece_type  # The type/shape of the currently active piece
var next_piece_type  # The type/shape of the next piece to spawn
var rotation_index : int = 0  # Current rotation state (0-3)
var active_piece : Array  # Array of Vector2i positions for the current piece

# Game variables
var score : int
const REWARD : int = 100
var game_running : bool 

# Tile map rendering variables
var tile_id : int = 0  # ID of the tile to use for rendering
var piece_atlas : Vector2i  # Atlas coordinates for the current piece's texture
var next_piece_atlas : Vector2i  # Atlas coordinates for the next piece's texture

# Layer organization variables
var board_layer : int = 0  # Layer for landed/locked pieces
var active_layer : int = 1  # Layer for the currently moving piece

# ============================================
# CORE GAME FUNCTIONS
# ============================================

# Called when the node enters the scene tree for the first time
func _ready():
	new_game()
	$HUD.get_node("StartButton").pressed.connect(new_game)
	
# Initialize a new game session
func new_game():
	# Reset game state variables
	score = 0 # Set score to zero when game starts
	speed = 1.0  # Set initial fall speed
	game_running = true
	steps = [0, 0, 0]  # Reset movement accumulator [left, right, down]
	# Hide game over message
	$HUD.get_node("GameOverLabel").hide()
	# Clear all
	clear_piece()
	clear_board()
	clear_panel()
	# Select the first piece and prepare the next one
	piece_type = pick_piece()
	piece_atlas = Vector2i(shapes_full.find(piece_type), 0)
	next_piece_type = pick_piece()
	next_piece_atlas = Vector2i(shapes_full.find(next_piece_type), 0)
	# Create the first piece
	create_piece()

# Called every frame. 'delta' is the elapsed time since the previous frame
# Handles input and movement updates
func _process(delta):
	if game_running:
		# Check for player input and accumulate steps
		if Input.is_action_pressed("ui_left"):
			steps[0] += 10  # Accumulate left movement
		elif Input.is_action_pressed("ui_right"):
			steps[1] += 10  # Accumulate right movement
		elif Input.is_action_pressed("ui_down"):
			steps[2] += 10  # Accumulate fast drop
		elif Input.is_action_just_pressed("ui_up"):
			rotate_piece()  # Rotate immediately (no accumulation)
		# Apply automatic downward movement
		steps[2] += speed
		# Execute movement when enough steps have accumulated
		for i in range(steps.size()):
			if steps[i] > steps_req:
				move_piece(directions[i])
				steps[i] = 0  # Reset step counter after movement

# ============================================
# PIECE MANAGEMENT FUNCTIONS
# ============================================

# Randomly select a piece from the available pool
# Uses a bag system to ensure fair distribution
func pick_piece():
	var piece
	if not shapes.is_empty():
		# Pick from current bag
		shapes.shuffle()
		piece = shapes.pop_front()
	else:
		# Refill bag when empty
		shapes = shapes_full.duplicate()
		shapes.shuffle()
		piece = shapes.pop_front()
	return piece

# Create a new piece at the starting position
func create_piece():
	# Reset movement variables
	steps = [0, 0, 0]
	cur_pos = start_pos
	
	# Get the piece's blocks for the current rotation
	active_piece = piece_type[rotation_index]
	
	# Draw the piece on the active layer
	draw_piece(active_piece, cur_pos, piece_atlas)
	
	# Display the next piece in the preview area
	draw_piece(next_piece_type[0], Vector2i(15, 6), next_piece_atlas)

# Remove the current piece from the active layer
func clear_piece():
	for i in active_piece:
		erase_cell(active_layer, cur_pos + i)

# Draw a piece on the tilemap at the specified position
# piece: Array of Vector2i positions
# pos: Base position for the piece
# atlas: Texture atlas coordinates for rendering
func draw_piece(piece, pos, atlas):
	for i in piece:
		set_cell(active_layer, pos + i, tile_id, atlas)

# ============================================
# MOVEMENT AND ROTATION FUNCTIONS
# ============================================

# Rotate the piece clockwise by 90 degrees
func rotate_piece():
	if can_rotate():
		clear_piece()  # Remove current orientation
		rotation_index = (rotation_index + 1) % 4  # Advance to next rotation
		active_piece = piece_type[rotation_index]  # Get new block positions
		draw_piece(active_piece, cur_pos, piece_atlas)  # Redraw

# Move the piece in the specified direction
# dir: Direction vector (LEFT, RIGHT, or DOWN)
func move_piece(dir):
	if can_move(dir):
		# Movement is valid - update position
		clear_piece()
		cur_pos += dir
		draw_piece(active_piece, cur_pos, piece_atlas)
	else:
		# Movement blocked
		if dir == Vector2i.DOWN:
			# Piece has landed - lock it in place and spawn next piece
			land_piece()
			check_rows()  # Check for completed rows
			# Prepare next piece
			piece_type = next_piece_type
			piece_atlas = next_piece_atlas
			next_piece_type = pick_piece()
			next_piece_atlas = Vector2i(shapes_full.find(next_piece_type), 0)
			# Clear preview panel and spawn new piece
			clear_panel()
			create_piece()
			check_game_over()

# Check if the piece can move in the specified direction
# Returns true if all blocks would be in valid, empty positions
func can_move(dir):
	var cm = true
	for i in active_piece:
		if not is_free(i + cur_pos + dir):
			cm = false  # At least one block would collide
	return cm

# Check if the piece can rotate to its next orientation
# Returns true if all blocks in the next rotation would be valid
func can_rotate():
	var cr = true
	var temp_rotation_index = (rotation_index + 1) % 4
	for i in piece_type[temp_rotation_index]:
		if not is_free(i + cur_pos):
			cr = false  # At least one block would collide
	return cr

# Check if a grid position is empty (not occupied by a landed piece)
# Returns true if the cell is free, false if occupied or out of bounds
func is_free(pos):
	return get_cell_source_id(board_layer, pos) == -1

# ============================================
# BOARD MANAGEMENT FUNCTIONS
# ============================================

# Lock the current piece onto the board layer
# Transfers blocks from active layer to board layer
func land_piece():
	for i in active_piece:
		erase_cell(active_layer, cur_pos + i)  # Remove from active layer
		set_cell(board_layer, cur_pos + i, tile_id, piece_atlas)  # Add to board layer

# Clear the next piece preview panel
func clear_panel():
	for i in range(14, 19):
		for j in range(5, 9):
			erase_cell(active_layer, Vector2i(i, j))

# Check all rows for completion and remove completed ones
func check_rows():
	var row : int = ROWS
	while row > 0:
		var count = 0
		# Count occupied cells in this row
		for i in range(COLS):
			if not is_free(Vector2i(i + 1, row)):
				count += 1
		# If row is completely filled, remove it
		if count == COLS:
			shift_rows(row)  # Shift down all rows above
			score += REWARD
			$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score)
			speed += ACCEL
			# Don't decrement row - check same position again after shift
		else:
			row -= 1  # Move to next row up

# Shift all rows above the specified row down by one
# Called when a row is completed
func shift_rows(row):
	var atlas
	# Start from the cleared row and move upward
	for i in range(row, 1, -1):
		for j in range(COLS):
			# Get the tile from the row above
			atlas = get_cell_atlas_coords(board_layer, Vector2i(j + 1, i - 1))
			if atlas == Vector2i(-1, -1):
				# Cell above is empty - clear current cell
				erase_cell(board_layer, Vector2i(j + 1, i))
			else:
				# Cell above has a tile - copy it down
				set_cell(board_layer, Vector2i(j + 1, i), tile_id, atlas)

func clear_board():
	for i in range(ROWS):
		for j in range(COLS):
			erase_cell(board_layer, Vector2i(j + 1, i + 1))

# Check for game over function
func check_game_over():
	for i in active_piece:
		if not is_free(i + cur_pos):
			land_piece()	
			$HUD.get_node("GameOverLabel").show()
			game_running = false
