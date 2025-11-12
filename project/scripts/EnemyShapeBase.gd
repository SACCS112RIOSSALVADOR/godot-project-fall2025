extends CharacterBody2D

const TILE_SIZE := 16 

var sprite_node_pos_tween: Tween 
var current_rotation := 0.0  
var is_selected := false  
var raycasts: Array[RayCast2D] = []  
var adjacent_enemies: Array = [] 

@onready var shape_sprite: Sprite2D = get_child(1)  
@onready var area_collission: Area2D = get_child(2)
@onready var click_sound: AudioStreamPlayer = $ClickSound  
@onready var move_sound: AudioStreamPlayer = $MoveSound  
@onready var rotate_sound: AudioStreamPlayer = $RotateSound  

var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")  
var team: bool  

func set_team(flag):
	team = flag
	if team == true:
		loaded_data.team = true
		set_collision_layer_value(1, true)   
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, true)   
		set_collision_mask_value(2, true)  
		set_collision_mask_value(3, true)   
	else:
		loaded_data.team = false
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)  
		set_collision_mask_value(1, true)   
		set_collision_mask_value(2, true)    
		set_collision_mask_value(3, true) 
	print(team)

func _ready():
	if loaded_data:
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
	
	if team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)
	
	for child in get_children():
		if child is RayCast2D:
			raycasts.append(child)
			_setup_raycast(child)
		elif child is Node:
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
					_setup_raycast(sub)
	print("Loaded RayCasts for", name, ":", raycasts.size())
	
	await get_tree().physics_frame
	
	check_adjacent_enemies()

func _setup_raycast(ray: RayCast2D):
	ray.set_collision_mask_value(1, true)   
	ray.set_collision_mask_value(2, true)   
	ray.set_collision_mask_value(3, true)  
	
	ray.enabled = true
	ray.hit_from_inside = false

func check_adjacent_enemies() -> Array:
	adjacent_enemies.clear()
	
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue
		
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider and collider.has_method("get_team"):
				# Check if it's an enemy
				if collider.get_team() != team:
					if not adjacent_enemies.has(collider):
						adjacent_enemies.append(collider)
						_on_enemy_detected(collider, ray)
	
	return adjacent_enemies

func _on_enemy_detected(enemy, ray: RayCast2D):
	print(name, "detected enemy:", enemy.name, "via raycast at", ray.target_position)
	
	if loaded_data:
		loaded_data.in_combat = true
	
func get_team() -> bool:
	return team

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if SelectionManager.selected_shape != self:
			if SelectionManager.selected_shape:
				SelectionManager.selected_shape.is_selected = false
			SelectionManager.selected_shape = self
			is_selected = true
			print("Selected", name)
			
			# Check for enemies when selected
			check_adjacent_enemies()
			
			if click_sound:
				click_sound.play()
		else:
			is_selected = false
			SelectionManager.selected_shape = null
			print("Deselected", name)
			if click_sound:
				click_sound.play()

func check_collision(direction: String) -> bool:
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue 

		var global_ray_dir := ray.target_position.rotated(global_rotation)
		
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

func perform_rotation():
	var new_angle := fmod(global_rotation_degrees + 90, 360)
	global_rotation_degrees = new_angle
	if !check_all_collisions():
		current_rotation = new_angle
		print(name, "rotated to", current_rotation)
		if rotate_sound:
			rotate_sound.play()
		
		# Check for enemies after rotation
		check_adjacent_enemies()
	else:
		global_rotation_degrees = current_rotation

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

	if move_sound:
		move_sound.play()

	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.185).set_trans(Tween.TRANS_SINE)
	
	await sprite_node_pos_tween.finished
	check_adjacent_enemies()

func _process(_delta: float) -> void:
	if adjacent_enemies.size() > 0:
		shape_sprite.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.005) * 0.2
	elif team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)
	else:
		shape_sprite.modulate = Color(1, 1, 1, 1)
