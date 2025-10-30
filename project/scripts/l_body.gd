extends CharacterBody2D

const tile_size = 16
var sprite_node_pos_tween: Tween

# needed for later
var currentRota = 0.0
var is_selected = false
var input_dir

#swap vaules from their keys when rotation happens
@onready var raycast_compass = {"down":[$RayCastA, $RayCastB, $RayCastC, $RayCastD],"right":[$RayCastE],"left":[$RayCastF],"up":[ $RayCastG, $RayCastH, $RayCastI, $RayCastJ]}
var default_compass = raycast_compass 

#note rotation should happen global_rotation
func change_compass(new_rota):
	if new_rota == 0:
		raycast_compass = default_compass

#Switch function for when the Shape is selected
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Check if the event is a left mouse button click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# When the mouse button is pressed down
		if event.is_pressed():
			# Toggle the state. This switches between true and false.
			is_selected = not is_selected
			
			if is_selected:
				print("L Object clicked on! State is now TRUE.")
			else:
				print("L Object clicked off! State is now FALSE.")
				
				
#detects if their is a collission with raycasts
func check_collission(input)-> bool:
	for rays in raycast_compass[input]:
		if rays.is_colliding():
			print("true")
			return true
	print("false")
	return false

#main function for movement
func _physics_process(delta: float) -> void:
	input_dir = Vector2.ZERO
	if is_selected:
		if !sprite_node_pos_tween or !sprite_node_pos_tween.is_running():
			if Input.is_action_pressed("ui_right") and check_collission("right") == false:
				_move(Vector2(1,0))
			#finish the bottom funciton if possibible
			elif Input.is_action_just_pressed("ui_left") and check_collission("left") == false:
				_move(Vector2(-1,0))
			elif Input.is_action_just_pressed("ui_up") and check_collission("up") == false:
				_move(Vector2(0,-1))
			elif Input.is_action_just_pressed("ui_down") and check_collission("down") == false:
				_move(Vector2(0,1))

#tweening function for movement
func _move(dir:Vector2):
	global_position += dir * tile_size
	$L_shape.global_position -=dir * tile_size
	
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()
	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property($L_shape,"global_position", global_position, 0.185).set_trans(Tween.TRANS_SINE)
