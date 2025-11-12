extends CharacterBody2D

# Friend's signal system for adjacency detection
signal adjacent_unit_entered(unit: Node, direction: String, is_enemy: bool)
signal adjacent_unit_exited(unit: Node, direction: String, is_enemy: bool)

var _adj_prev_hit: Dictionary = {}

const TILE_SIZE := 16

var sprite_node_pos_tween: Tween
var current_rotation := 0.0
var is_selected := false
var raycasts: Array[RayCast2D] = []
var adjacent_enemies: Array = []  # Track adjacent enemy pieces

@onready var shape_sprite: Sprite2D = get_child(1)
@onready var area_collission: Area2D = get_child(2)
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var rotate_sound: AudioStreamPlayer = $RotateSound

# NOTE: preload a template resource and duplicate it per-instance in _ready()
var _unit_template := preload("res://project/resources/unitdata_resource.tres")
var loaded_data: UnitData = null
var team: bool

#debugging code delete later
func print_hi():
	print("hi")

func set_team(flag):
	team = flag
	if loaded_data:
		loaded_data.team = flag
	# set collision layers / masks
	if team == true:
		# Player team
		set_collision_layer_value(1, true)
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, true)
	else:
		# Enemy team
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, true)
	print(team)

func _ready():
	# Duplicate the resource so each instance has its own health/strength etc.
	if _unit_template:
		loaded_data = _unit_template.duplicate(true) # deep duplicate
	else:
		print("Failed to preload unit template!")
		return

	# Connect signals AFTER we have a unique loaded_data
	if loaded_data:
		loaded_data.health_changed.connect(_on_health_changed)
		loaded_data.health_depleted.connect(_on_health_depleted)
	else:
		print("Failed to create UnitData instance.")

	# Visual tinting for enemy team
	if team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)

	# Setup raycasts
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

	# Connect adjacency signals
	adjacent_unit_entered.connect(_on_adjacent_unit_entered)
	adjacent_unit_exited.connect(_on_adjacent_unit_exited)

	# Wait one physics frame then prime adjacency
	await get_tree().physics_frame
	check_adjacent_enemies()
	_adj_update(true)

func _on_health_changed(old_value, new_value):
	var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		attack_panel.update_health(new_value)

func _on_health_depleted():
	print(name, "has been destroyed.")
	# Award score if this was an enemy
	if team == false:
		var play_node = get_tree().current_scene
		if play_node and play_node.has_method("add_score"):
			play_node.add_score(100)
	# Hide AttackPanel if showing this unit
	var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		attack_panel.hide()
	queue_free()

func _setup_raycast(ray: RayCast2D):
	# Detect both teams + walls
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

func _on_enemy_detected(enemy, _ray: RayCast2D):
	print(name, "detected enemy:", enemy.name)
	if loaded_data:
		loaded_data.in_combat = true

func initiate_combat(enemy):
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(loaded_data.strength)
		print("Hit: ", enemy.name)
	loaded_data.in_combat = false

# Use the UnitData's method so signals fire correctly
func take_damage(amount):
	if loaded_data:
		loaded_data.take_damage(amount)
	else:
		print("No loaded_data on", name)

func _on_adjacent_unit_entered(unit: Node, direction: String, is_enemy: bool):
	if is_enemy:
		if not adjacent_enemies.has(unit):
			adjacent_enemies.append(unit)
		print(name, "enemy entered adjacency:", unit.name, "direction:", direction)
		if loaded_data:
			loaded_data.in_combat = true

func _on_adjacent_unit_exited(unit: Node, direction: String, is_enemy: bool):
	if is_enemy:
		adjacent_enemies.erase(unit)
		print(name, "enemy exited adjacency:", unit.name, "direction:", direction)
		if loaded_data and adjacent_enemies.size() == 0:
			loaded_data.in_combat = false

func get_team() -> bool:
	return team

# --- Input handling ---
func _on_area_2d_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# RIGHT CLICK: only allow player-team shapes to open the attack panel
		if event.button_index == MOUSE_BUTTON_RIGHT:
			viewport.set_input_as_handled()
			if team != true:
				# Only player shapes (team == true) may open the attack UI
				return
			# Only open if there's at least one adjacent enemy
			if check_adjacent_enemies().size() == 0:
				print("No adjacent enemies — cannot open attack panel.")
				return
			var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")
			if attack_panel:
				attack_panel.show_for_unit(self)
			return

		# LEFT CLICK: selection or applying an attack (if panel & attack selected)
		if event.button_index == MOUSE_BUTTON_LEFT:
			var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")

			# Case: panel has an active attack, and this shape is the clicked target
			if attack_panel and attack_panel.selected_attack != "" and SelectionManager.selected_shape and SelectionManager.selected_shape != self:
				var attacker = attack_panel.attacker
				# Validate attacker
				if attacker == null:
					print("No attacker set on attack panel.")
					return

				# Prevent friendly fire
				if attacker.get_team() == get_team():
					print("Cannot attack ally:", name)
					return

				# Enforce adjacency: attacker must list this as an adjacent enemy
				var adjacent_list = attacker.check_adjacent_enemies()
				if not adjacent_list.has(self):
					print("Target not adjacent — move closer to attack.")
					return

				# Compute damage and apply to the clicked (target) instance
				var dmg := 0
				match attack_panel.selected_attack:
					"light":
						dmg = attacker.loaded_data.strength
					"heavy":
						dmg = attacker.loaded_data.strength * 2

				# Use the instance's take_damage so UnitData signals fire and cleanup happens
				take_damage(dmg)
				print("%s attacked %s for %d damage" % [attacker.name, name, dmg])

				attack_panel.selected_attack = ""
				attack_panel.hide()
				return

			# Normal selection logic
			if SelectionManager.selected_shape != self:
				if SelectionManager.selected_shape:
					SelectionManager.selected_shape.is_selected = false
				SelectionManager.selected_shape = self
				is_selected = true
				check_adjacent_enemies()
				if click_sound: click_sound.play()
			else:
				is_selected = false
				SelectionManager.selected_shape = null
				if click_sound: click_sound.play()

# --- Collision helpers unchanged except minor clean checks ---
func check_collision(direction: String) -> bool:
	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue
		var global_ray_dir = ray.target_position.rotated(global_rotation)
		match direction:
			"right":
				if global_ray_dir.x > 0 and ray.is_colliding(): return true
			"left":
				if global_ray_dir.x < 0 and ray.is_colliding(): return true
			"up":
				if global_ray_dir.y < 0 and ray.is_colliding(): return true
			"down":
				if global_ray_dir.y > 0 and ray.is_colliding(): return true
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

	# Hide the AttackPanel if it’s showing this shape’s info
	var attack_panel = get_tree().current_scene.get_node_or_null("PanelContainer")
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		attack_panel.hide()

	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.185).set_trans(Tween.TRANS_SINE)

	await sprite_node_pos_tween.finished
	check_adjacent_enemies()

# Friend's adjacency detection system — made resilient to freed nodes
func _adj_update(prime: bool = false) -> void:
	var now: Dictionary = {}

	for ray in raycasts:
		if ray == null or !ray.enabled:
			continue

		ray.force_raycast_update()
		if !ray.is_colliding():
			continue

		var origin: Vector2 = ray.to_global(Vector2.ZERO)
		var hit_p: Vector2 = ray.get_collision_point()
		if origin.distance_to(hit_p) > float(TILE_SIZE) * 1.1:
			continue

		var col: Object = ray.get_collider()
		var unit: Node = _adj_find_unit_root(col)
		#Skip null or freed units
		if unit == null or not is_instance_valid(unit):
			continue

		if unit != self:
			now[ray] = unit
			if !_adj_prev_hit.has(ray) and !prime:
				var dir: String = _adj_direction_of(ray)
				emit_signal("adjacent_unit_entered", unit, dir, _adj_is_enemy(unit))

	if !prime:
		# Iterate over previous hits; skip any freed nodes
		for r in _adj_prev_hit.keys():
			var prev_unit: Node = (_adj_prev_hit[r] as Node)
			# If prev_unit is invalid or not in 'now', emit exit
			if prev_unit == null or not is_instance_valid(prev_unit) or !now.has(r):
				if prev_unit == null or not is_instance_valid(prev_unit):
					continue
				if !now.has(r):
					var d: String = _adj_direction_of(r)
					emit_signal("adjacent_unit_exited", prev_unit, d, _adj_is_enemy(prev_unit))

	_adj_prev_hit = now

func _adj_direction_of(ray: RayCast2D) -> String:
	var v: Vector2 = ray.target_position.rotated(global_rotation)
	if abs(v.x) >= abs(v.y):
		return "right" if v.x >= 0.0 else "left"
	else:
		return "down" if v.y >= 0.0 else "up"

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

func _process(_delta: float) -> void:
	if adjacent_enemies.size() > 0:
		shape_sprite.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.005) * 0.2
	elif team == false:
		shape_sprite.modulate = Color(0.528, 0.205, 0.105, 0.945)
	else:
		shape_sprite.modulate = Color(1, 1, 1, 1)
