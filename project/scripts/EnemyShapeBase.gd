
func _ready():
	pass




# --- Collision helpers unchanged except minor clean checks ---
#func check_collision(direction: String) -> bool:
	#for ray in raycasts:
		#if ray == null or !ray.enabled:
			#continue
		#var global_ray_dir = ray.target_position.rotated(global_rotation)
		#match direction:
			#"right":
				#if global_ray_dir.x > 0 and ray.is_colliding(): return true
			#"left":
				#if global_ray_dir.x < 0 and ray.is_colliding(): return true
			#"up":
				#if global_ray_dir.y < 0 and ray.is_colliding(): return true
			#"down":
				#if global_ray_dir.y > 0 and ray.is_colliding(): return true
	#return false

#func check_all_collisions() -> bool:
	#return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")

#func perform_rotation():
	#var new_angle := fmod(global_rotation_degrees + 90, 360)
	#global_rotation_degrees = new_angle
	#if !check_all_collisions():
		#current_rotation = new_angle
		#print(name, "rotated to", current_rotation)
		#if rotate_sound:
			#rotate_sound.play()
		#check_adjacent_enemies()
	#else:
		#global_rotation_degrees = current_rotation

func _physics_process(_delta: float) -> void:
	pass
	#if !is_selected:
		#return
	#if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
		#return
#
	#var move_vec := Vector2.ZERO
#
	#if Input.is_action_just_pressed("ui_right") and !check_collision("right"):
		#move_vec = Vector2.RIGHT
	#elif Input.is_action_just_pressed("ui_left") and !check_collision("left"):
		#move_vec = Vector2.LEFT
	#elif Input.is_action_just_pressed("ui_up") and !check_collision("up"):
		#move_vec = Vector2.UP
	#elif Input.is_action_just_pressed("ui_down") and !check_collision("down"):
		#move_vec = Vector2.DOWN
#
	#if move_vec != Vector2.ZERO:
		#_move(move_vec)
#
	#if Input.is_action_just_pressed("space"):
		#perform_rotation()
