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
signal action_performed(shape: Node)

var _unit_template := preload("res://project/resources/unitdata_resource.tres")
var loaded_data: UnitData = null
var team: bool
var currently_adjacent_to_enemy: bool
var current_turn: bool = true # true = player's turn, false = foe's turn
var step: int = 0
var enemy_ai_cooldown: float = 0.0

# function sets whether the unit belongs to the player or the enemy.
func set_team(flag):
	# Store team flag locally
	team = flag
	# Propagate team identity into the unit’s data model
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
		# Called whenever health changes; usually used to update UI or debug print.
		loaded_data.health_changed.connect(_on_health_changed)
		# Called when health hits 0; usually triggers destruction, scoring, etc.
		loaded_data.health_depleted.connect(_on_health_depleted)
	else:
		# Defensive logging if duplication somehow failed.
		print("Failed to create UnitData instance.")

	# Visual tinting for enemy team
	if team == false:
		shape_sprite.modulate = Color(0.6, 0.039, 0.024, 0.945)

	# Setup raycasts; collision checks, adjacency detection, etc.
	for child in get_children():
		if child is RayCast2D:
			# Direct child raycast: store it and set it up.
			raycasts.append(child)
			_setup_raycast(child)
		elif child is Node:
			# If the child is a container node, search its children for RayCast2D nodes too.
			for sub in child.get_children():
				if sub is RayCast2D:
					raycasts.append(sub)
					_setup_raycast(sub)
	print("Loaded RayCasts for", name, ":", raycasts.size())

	# Put this unit into a generic group so play.gd can find all units if needed
	add_to_group("units")
	if team:
		add_to_group("player_units")
	else:
		add_to_group("foe_units")

	# Connect our action_performed signal to play.gd (if we’re in the play scene)
	var play_node := get_tree().current_scene
	if play_node and play_node.has_method("_on_unit_action_performed"):
		# Whenever this unit performs an action, notify play.gd so it can decrement. Action counters and possibly end the turn.
		action_performed.connect(play_node._on_unit_action_performed)

	# These signals let the unit react when other units enter or leave its adjacency range.
	adjacent_unit_entered.connect(_on_adjacent_unit_entered)
	adjacent_unit_exited.connect(_on_adjacent_unit_exited)

	# Wait a single physics frame so that physics bodies and raycasts are fully initialized.
	# After that, perform an initial adjacency scan and update any adjacency-dependent state.
	await get_tree().physics_frame
	check_adjacent_enemies()
	_adj_update(true)

func _on_health_changed(old_value, new_value):
	var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		attack_panel.update_health(new_value)

"""
---------------------------------------------------------
Requirement 5 – Score rewards when opponents are defeated
func _on_health_depleted() 
---------------------------------------------------------
"""
# function once health depleted. 
func _on_health_depleted():
	# This is called when the unit's health reaches zero.
	print(name, "has been destroyed.")
	# If this unit belongs to the enemy team, award points to the player.
	if team == false:
		# Get the active scene (expected to be the main play scene).
		var play_node = get_tree().current_scene
		# Only call add_score if the scene actually implements it.
		if play_node and play_node.has_method("add_score"):
			play_node.add_score(100)
	# Hide AttackPanel if showing this unit
	var attack_panel = get_tree().root.get_node_or_null("main/PanelContainer")
	# If the AttackPanel is visible and currently associated with THIS unit
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		# hide it so the UI doesn't show controls for a unit that no longer exists.
		attack_panel.hide()
	# Finally, remove this unit from the scene, freeing all its nodes and resources.
	queue_free()

# Raycast function
func _setup_raycast(ray: RayCast2D):
	# Configure a single RayCast2D so it can detect:
	# player units (layer 1)
	ray.set_collision_mask_value(1, true)
	# enemy units (layer 2)
	ray.set_collision_mask_value(2, true)
	# map / walls (layer 3)
	ray.set_collision_mask_value(3, true)
	ray.enabled = true
	ray.hit_from_inside = false

# Function check adjacent enemy 
func check_adjacent_enemies() -> Array:
	# Clear any previously stored enemies; we will rebuild the list from scratch.
	adjacent_enemies.clear()
	# Iterate through every RayCast2D that was registered in _ready().
	for ray in raycasts:
		# Skip invalid or disabled raycasts.
		if ray == null or !ray.enabled:
			continue
		# Force the raycast to refresh its collision info for this frame.
		ray.force_raycast_update()
		# If this raycast is hitting something, inspect the collider.
		if ray.is_colliding():
			var collider = ray.get_collider()
			# We only care about colliders that behave like units (must have get_team()).
			if collider and collider.has_method("get_team"):
				# Check if it's an enemy
				if collider.get_team() != team:
					# Avoid duplicates if multiple rays hit the same enemy.
					if not adjacent_enemies.has(collider):
						adjacent_enemies.append(collider)
						# Notify that we have just detected a new enemy via this ray.
						_on_enemy_detected(collider, ray)
	return adjacent_enemies
	
# Function checks whether at least one friendly unit is adjacent
func has_adjacent_ally() -> bool:
	for ray in raycasts:
		# Skip invalid or disabled raycasts.
		if ray == null or !ray.enabled:
			continue
		# Refresh collision info for this raycast.
		ray.force_raycast_update()
		# If this raycast hits something, inspect it.
		if ray.is_colliding():
			var collider = ray.get_collider()
			# Ignore self, and only consider colliders that can report a team.
			if collider and collider != self and collider.has_method("get_team"):
				# Same team = ally
				if collider.get_team() == team:
					return true
	return false

# function when detecting enemy
func _on_enemy_detected(enemy, _ray: RayCast2D):
	print(name, "detected enemy:", enemy.name)
	# If we have UnitData loaded, mark this unit as "in combat".
	if loaded_data:
		loaded_data.in_combat = true

"""
---------------------------------------
Requirement 3 – Combat mode & attacking
func initiate_combat(enemy) & take_damage()
---------------------------------------
"""

# Combat function
func initiate_combat(enemy):
	# The enemy must support "take_damage" for combat to work.
	if enemy and enemy.has_method("take_damage"):
		# Apply this unit’s strength as damage to the enemy.
		enemy.take_damage(loaded_data.strength)
		print("Hit: ", enemy.name)

	# After performing an attack, this unit is no longer considered “in combat”, unless adjacency re-triggers it again.
	loaded_data.in_combat = false

# Use the UnitData's method so signals fire correctly
func take_damage(amount):
	# Damage must be applied through loaded_data
	if loaded_data:
		loaded_data.take_damage(amount)
	else:
		print("No loaded_data on", name)

# function when a nearby unit enters one of the raycast directions.
func _on_adjacent_unit_entered(unit: Node, direction: String, is_enemy: bool):
	# Track the enemy in the adjacency list if it wasn’t already present.
	if is_enemy:
		if not adjacent_enemies.has(unit):
			adjacent_enemies.append(unit)
		print(name, "enemy entered adjacency:", unit.name, "direction:", direction)
		# Mark this unit as “in combat” because an enemy is now directly adjacent.
		if loaded_data:
			loaded_data.in_combat = true
			
# Function when adjacent unit moves away.
func _on_adjacent_unit_exited(unit: Node, direction: String, is_enemy: bool):
	if is_enemy:
		# Remove it from the adjacency list.
		adjacent_enemies.erase(unit)
		print(name, "enemy exited adjacency:", unit.name, "direction:", direction)
		# Only mark out of combat if NO enemies remain adjacent.
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
			# Fetch the attack panel and show it for this unit.
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

				# --- Ally adjacency bonus (player only) ---
				# If the attacking unit is on the player team and has at least
				# one adjacent ally, add a flat bonus based on its strength.
				if attacker.get_team() == true and attacker.has_method("has_adjacent_ally"):
					if attacker.has_adjacent_ally():
						var bonus :int= attacker.loaded_data.strength / 2  # 50% extra
						dmg += bonus
						print("Bonus damage applied (+%d) due to adjacent ally." % bonus)

				# Use the instance's take_damage so UnitData signals fire and cleanup happens
				take_damage(dmg)
				print("%s attacked %s for %d damage" % [attacker.name, name, dmg])
				# Consumes one action for the attacker’s team
				if attacker and attacker.has_method("step_increment"):
					attacker.step_increment()
				# Clear the selected attack and hide the panel after the attack resolves.
				attack_panel.selected_attack = ""
				attack_panel.hide()
				return

			# Normal selection logic
			if SelectionManager.selected_shape != self:
				# If another shape was selected, unselect it first.
				if SelectionManager.selected_shape:
					SelectionManager.selected_shape.is_selected = false
				# Select this shape.
				SelectionManager.selected_shape = self
				is_selected = true
				# Refresh adjacency so UI/logic can respond to nearby enemies.
				check_adjacent_enemies()
				# Optional click sound feedback.
				if click_sound: 
					click_sound.play()
			else:
				# Clicking again on the same shape toggles it off (deselect).
				is_selected = false
				SelectionManager.selected_shape = null
				if click_sound: click_sound.play()

func check_collision(direction: String) -> bool:
	# Check whether moving in the given direction ("right", "left", "up", "down")
	# would cause a collision according to this unit's raycasts.
	for ray in raycasts:
		# Skip invalid or disabled raycasts.
		if ray == null or !ray.enabled:
			continue
		# Compute the ray's direction in global space (takes rotation into account).
		var global_ray_dir = ray.target_position.rotated(global_rotation)
		# Depending on the desired direction, only consider rays that point that way.
		match direction:
			"right":
				# A ray pointing right with a collision means movement is blocked.
				if global_ray_dir.x > 0 and ray.is_colliding(): return true
			"left":
				# A ray pointing left with a collision means movement is blocked.
				if global_ray_dir.x < 0 and ray.is_colliding(): return true
			"up":
				# A ray pointing up with a collision means movement is blocked.
				if global_ray_dir.y < 0 and ray.is_colliding(): return true
			"down":
				# A ray pointing down with a collision means movement is blocked.
				if global_ray_dir.y > 0 and ray.is_colliding(): return true
	# If no collision is detected, return false
	return false

func check_all_collisions() -> bool:
	# Validating rotations that might cause overlap in any direction. Returns true if ANY direction is currently blocked.
	return check_collision("right") or check_collision("left") or check_collision("up") or check_collision("down")

# Rotation function
func perform_rotation() -> bool:
	# Remember the current global rotation so we can revert on failure.
	var old_angle := global_rotation_degrees
	# Compute the candidate new angle (90° step, wrapping around at 360).
	var new_angle := current_rotation + 90.0
	new_angle = fmod(new_angle, 360.0)

	# Temporarily apply the new rotation to test for collisions.
	global_rotation_degrees = new_angle

	# If colliding after rotation, revert
	if check_all_collisions():
		global_rotation_degrees = old_angle
		return false

	# commit the rotation as the new current orientation.
	current_rotation = new_angle
	# Play sound
	if has_node("rotate_sound"):
		$rotate_sound.play()
	# Notify any adjacency/visual systems that our orientation changed.
	_adj_update()
	return true

"""
-------------------------------------------------------------
Requirement 2 – Move selected shape with WASD / movement keys
_move() & _physic_process
-------------------------------------------------------------
"""

func _physics_process(delta: float) -> void:
	# Ignore input if this piece is not the currently selected unit.
	if current_turn and team == true:
		# Only respond to input if this piece is selected
		if !is_selected:
			return
		# If a tween is animating the sprite position, wait until it finishes, before accepting new movement input.
		if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
			return

		var move_vec := Vector2.ZERO

		# For each direction key, check if the key was just pressed AND the path is clear.
		# If so, set the move vector and consume one action via step_increment().
		if Input.is_action_just_pressed("ui_right") and !check_collision("right"):
			move_vec = Vector2.RIGHT
			step_increment()
		elif Input.is_action_just_pressed("ui_left") and !check_collision("left"):
			move_vec = Vector2.LEFT
			step_increment()
		elif Input.is_action_just_pressed("ui_up") and !check_collision("up"):
			move_vec = Vector2.UP
			step_increment()
		elif Input.is_action_just_pressed("ui_down") and !check_collision("down"):
			move_vec = Vector2.DOWN
			step_increment()

		# If a movement direction was chosen, actually move the unit on the grid.
		if move_vec != Vector2.ZERO:
			_move(move_vec)

		# Rotation is also a valid action if it succeeds
		if Input.is_action_just_pressed("space"):
			# The rotation is committed and an action is consumed.
			if perform_rotation():
				step_increment()

# -------------------------
# Enemy AI units
# -------------------------
	# When it is NOT the player's turn (current_turn == false) and this unit belongs to the enemy team, 
	# we run the AI controller instead.
	elif current_turn == false and team == false:
		# Delegate behavior to the AI step, which may move/attack, etc.
		_enemy_ai_step(delta)

"""
---------------------------------------------------------
Requirement 6 – AI controls opposing shapes on their turn
func _enemy_ai_step() & perform_action()
---------------------------------------------------------
"""

# function for Enemy AI step
func _enemy_ai_step(delta: float) -> void:
	# Don’t act while tweening
	if sprite_node_pos_tween and sprite_node_pos_tween.is_running():
		return
	
	# Decrease the AI cooldown timer by the delta time.
	enemy_ai_cooldown -= delta
	# Cooldown so enemy doesn’t act every single frame
	if enemy_ai_cooldown > 0.0:
		return

	# -------------------------
	# Decide a direction
	# -------------------------
	# Default direction is "down".
	var direction := "down"

	# Prefer moving down. If blocked, try other directions in a fixed order.
	if check_collision("down"):
		if !check_collision("up"):
			direction = "up"
		elif !check_collision("left"):
			direction = "left"
		elif !check_collision("right"):
			direction = "right"
		else:
			# Completely surrounded: try a rotation in place
			var rotated := perform_action("down", true)
			if rotated:
				# Only consume an action if the rotation succeeded.
				step_increment()
			# Reset cooldown so the AI waits before trying again.
			enemy_ai_cooldown = 0.25
			return

	# Randomly decide whether to rotate as part of this action
	var do_rotate := randf() < 0.2

	# Perform movement (and possibly rotation) using the chosen direction.
	var did_action := perform_action(direction, do_rotate)
	if did_action:
		# If we actually did something, consume one enemy action.
		step_increment()

	# Reset cooldown so the enemy waits a short time before its next move.
	enemy_ai_cooldown = 0.25

func _move(direction: Vector2):
	# Grid-based movement: shift the unit's global position by one tile.
	var new_pos := global_position + direction * TILE_SIZE
	global_position = new_pos

	# Play movement sound if available.
	if move_sound:
		move_sound.play()

	# If the AttackPanel is visible and currently showing this unit's info, hide it because the unit has moved.
	var attack_panel = get_tree().current_scene.get_node_or_null("PanelContainer")
	if attack_panel and attack_panel.visible and attack_panel.get_meta("selected_unit") == self:
		attack_panel.hide()
	# Kill any existing tween so we don't stack multiple tweens.
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill()

	# Create a new tween to smoothly animate the sprite to the new position.
	sprite_node_pos_tween = create_tween()
	sprite_node_pos_tween.set_parallel(true)
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sprite_node_pos_tween.tween_property(shape_sprite, "global_position", new_pos, 0.185).set_trans(Tween.TRANS_SINE)

	# Wait until the tween finishes before continuing.
	await sprite_node_pos_tween.finished
	# After moving, re-check adjacency for enemies (for combat / highlighting).
	check_adjacent_enemies()

# Friend's adjacency detection system — made resilient to freed nodes
# Friend's adjacency detection system — safe around freed nodes
func _adj_update(prime: bool = false) -> void:
	var now: Dictionary = {}

	# --- Scan all raycasts for current hits ---
	for ray in raycasts:
		# Skip invalid or disabled raycasts.
		if ray == null or !ray.enabled:
			continue

		# Refresh collision info for this ray.
		ray.force_raycast_update()
		if !ray.is_colliding():
			continue

		# Only count collisions within roughly one tile distance.
		var origin: Vector2 = ray.to_global(Vector2.ZERO)
		var hit_p: Vector2 = ray.get_collision_point()
		if origin.distance_to(hit_p) > float(TILE_SIZE) * 1.1:
			continue

		# Find the "unit root" node for the collider.
		var col = ray.get_collider()
		var unit: Node = _adj_find_unit_root(col)

		# skip null / freed / self
		if unit == null or !is_instance_valid(unit) or unit == self:
			continue

		# remember current hit for this ray
		now[ray] = unit

		# if this ray was not hitting anyone last time (and this isn’t the prime pass),
		# emit "entered"
		if !_adj_prev_hit.has(ray) and !prime:
			var dir := _adj_direction_of(ray)
			emit_signal("adjacent_unit_entered", unit, dir, _adj_is_enemy(unit))

	# --- Compare with previous hits to find exits ---
	if !prime:
		for r in _adj_prev_hit.keys():
			var prev_val = _adj_prev_hit[r]  # untyped on purpose (Variant)

			# if value is null or freed, just drop it
			if prev_val == null or !is_instance_valid(prev_val):
				continue
			var prev_unit: Node = prev_val
			# if this ray no longer hits the same unit, emit "exited"
			if !now.has(r):
				var d := _adj_direction_of(r)
				emit_signal("adjacent_unit_exited", prev_unit, d, _adj_is_enemy(prev_unit))

	# store the set of current hits for the next frame
	_adj_prev_hit = now

	if !prime:
		# Iterate over previous hits; skip any freed nodes safely
		for r in _adj_prev_hit.keys():
			var prev_val :Object= _adj_prev_hit[r]
			# If the stored value is null or already freed, skip it
			if prev_val == null or !is_instance_valid(prev_val):
				continue

			var prev_unit := prev_val as Node
			if prev_unit == null:
				continue

			# If this ray no longer hits the same unit, emit 'exited'
			if !now.has(r):
				var d: String = _adj_direction_of(r)
				emit_signal("adjacent_unit_exited", prev_unit, d, _adj_is_enemy(prev_unit))
	_adj_prev_hit = now

func _adj_direction_of(ray: RayCast2D) -> String:
	# Determine a logical direction ("right", "left", "up", "down") for a ray,
	# based on its rotated target vector relative to this unit.
	var v: Vector2 = ray.target_position.rotated(global_rotation)
	# Compare absolute x vs y to decide whether the ray is more horizontal or vertical.
	if abs(v.x) >= abs(v.y):
		return "right" if v.x >= 0.0 else "left"
	else:
		return "down" if v.y >= 0.0 else "up"

func _adj_find_unit_root(x: Object) -> Node:
	# Starting from an arbitrary collider object, walk up its parent chain until
	# we find a node that looks like a "unit root".
	var n: Node = x as Node
	while n != null:
		var has_prop: bool = false
		# Check for loaded_data.
		var ud: Variant = n.get("loaded_data")
		if ud != null and typeof(ud) != TYPE_NIL:
			has_prop = true
		# If no loaded_data, check for a boolean team property.
		if !has_prop:
			var t: Variant = n.get("team")
			if t != null and typeof(t) == TYPE_BOOL:
				has_prop = true
		# If we found something that looks like a unit, return it.
		if has_prop:
			return n
		# Otherwise, climb one level up the scene tree.
		n = n.get_parent()
	return null

func _adj_is_enemy(unit: Node) -> bool:
	# Determine whether 'unit' is an enemy relative to this unit.
	# Returns true if both have valid boolean team flags and they differ.
	var my_team: Variant = _adj_team_of(self)
	var their_team: Variant = _adj_team_of(unit)
	# If either team flag is not a bool, we cannot safely compare.
	if typeof(my_team) != TYPE_BOOL or typeof(their_team) != TYPE_BOOL:
		return false
	# Enemy if teams are different.
	return bool(my_team) != bool(their_team)

# Function use to retrieve a team flag from a node.
func _adj_team_of(node: Node) -> Variant:
	if node == null:
		return null
	# Try team from loaded_data first.
	var ud: Variant = node.get("loaded_data")
	if ud != null and typeof(ud) != TYPE_NIL:
		var obj: Object = ud as Object
		var t: Variant = obj.get("team")
		if typeof(t) == TYPE_BOOL:
			return t
	# Fallback: direct team property on the node.
	var t2: Variant = node.get("team")
	if typeof(t2) == TYPE_BOOL:
		return t2
	return null

func has_enemy_adjacent(direction: String) -> bool:
	# Check if there is at least one enemy unit adjacent in the given direction.
	# Direction is one of "up", "down", "left", "right" (case-insensitive).
	var dir: String = direction.to_lower()
	for ray in raycasts:
		# Skip invalid or disabled raycasts.
		if ray == null or !ray.enabled:
			continue
		# Only consider rays whose logical direction matches 'dir'.
		var d: String = _adj_direction_of(ray)
		if d != dir:
			continue
		# Refresh raycast; if it doesn't hit anything, skip.
		ray.force_raycast_update()
		# Check hit distance; only consider hits within one tile radius.
		if ray.is_colliding():
			var origin: Vector2 = ray.to_global(Vector2.ZERO)
			var p: Vector2 = ray.get_collision_point()
			# Find the unit root for the collider and check if it is an enemy.
			if origin.distance_to(p) <= float(TILE_SIZE) * 1.1:
				var collider: Object = ray.get_collider()
				var u: Node = _adj_find_unit_root(collider)
				if u != null and _adj_is_enemy(u):
					return true
	return false

func _process(_delta: float) -> void:
	# Visual feedback based on adjacency and team
	if adjacent_enemies.size() > 0:
		shape_sprite.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.005) * 0.2
	elif team == false:
		shape_sprite.modulate = Color(0.655, 0.208, 0.188, 0.965)
	else:
		shape_sprite.modulate = Color(1, 1, 1, 1)

#Enemy AI's movement functions below
###############################################################################################

func perform_action(direction: String, rotation_bool: bool) -> bool:
	#if unit is adjacent to foe: 
	#then attack the foe with the highest priority (check foe priority with raycasts) and return false
	if rotation_bool == true:
		if check_all_collisions() == false:
			perform_rotation()
			return true
	if  check_collision(direction) == false:
		match direction:
			"right":
				_move(Vector2.RIGHT)
				return true
			"left":
				_move(Vector2.LEFT)
				return true
			"up":
				_move(Vector2.UP)
				return true
			"down":
				_move(Vector2.DOWN)
				return true
	return false
	
func get_current_position():
	return global_position.y
	
func change_turn_var():
	current_turn = not current_turn
	
func step_increment() -> void:
	step += 1
	# Inform the main controller (play.gd) that an action occurred
	emit_signal("action_performed", self)
	
func get_steps()-> int:
	return step
	
func reset_step():
	step = 0
