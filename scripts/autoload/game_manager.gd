extends Node

## GameManager manages level data, navigation flows, and gameplay state signals.

signal coin_collected(current: int, total: int)
signal level_completed(level_id: int)
signal player_died
signal player_revived(position: Vector2)
signal coins_reset

var current_level_id: int = 1
var current_coins: int = 0
var total_coins_required: int = 10
var is_gameplay_active: bool = false

# Player reference and safe checkpoint / revive tracking
var active_player: CharacterBody2D = null
var level_spawn_point: Vector2 = Vector2.ZERO
var safe_anchors: Array[Vector2] = []
var last_safe_position: Vector2 = Vector2.ZERO
var last_death_position: Vector2 = Vector2.ZERO
var revives_used_this_death: int = 0
var revives_used_this_run: int = 0
var current_run_id: int = 1
const MAX_REVIVES_PER_RUN: int = 1
var last_run_stars: int = 3

# 4 Worlds definitions organizing all 20 planned stages
var worlds: Dictionary = {
	1: {"id": 1, "name": "NEON RUINS", "stages": [1, 2, 3, 4, 5]},
	2: {"id": 2, "name": "THE HAUNTED HALL", "stages": [6, 7, 8, 9, 10]},
	3: {"id": 3, "name": "RAGE FACTORY", "stages": [11, 12, 13, 14, 15]},
	4: {"id": 4, "name": "FINAL HELL", "stages": [16, 17, 18, 19, 20]}
}

# 20 planned levels definitions as specified in section 7
var levels: Dictionary = {
	1: {"id": 1, "name": "The Warm-Up", "world_id": 1, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_1.tscn", "coin_count": 10},
	2: {"id": 2, "name": "Trust Nothing", "world_id": 1, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_2.tscn", "coin_count": 10},
	3: {"id": 3, "name": "Fire & Fury", "world_id": 1, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_3.tscn", "coin_count": 10},
	4: {"id": 4, "name": "Crushing Silence", "world_id": 1, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_4.tscn", "coin_count": 10},
	5: {"id": 5, "name": "The Final Betrayal", "world_id": 1, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_5.tscn", "coin_count": 10},
	6: {"id": 6, "name": "Phantom's Curse", "world_id": 2, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_6.tscn", "coin_count": 10},
	7: {"id": 7, "name": "Hall of Illusions", "world_id": 2, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_7.tscn", "coin_count": 10},
	8: {"id": 8, "name": "The Cursed Wind", "world_id": 2, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_8.tscn", "coin_count": 10},
	9: {"id": 9, "name": "Chains of the Damned", "world_id": 2, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_9.tscn", "coin_count": 10},
	10: {"id": 10, "name": "Haunted Survival", "world_id": 2, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_10.tscn", "coin_count": 10},
	11: {"id": 11, "name": "Meltdown", "world_id": 3, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_11.tscn", "coin_count": 10},
	12: {"id": 12, "name": "Pressure Overload", "world_id": 3, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_12.tscn", "coin_count": 10},
	13: {"id": 13, "name": "Factory Climb", "world_id": 3, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_13.tscn", "coin_count": 10},
	14: {"id": 14, "name": "Overpressure", "world_id": 3, "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_14.tscn", "coin_count": 10},
	15: {"id": 15, "name": "Rage Furnace", "world_id": 3, "implemented": false, "scene": "", "coin_count": 10},
	16: {"id": 16, "name": "Chaos Theory", "world_id": 4, "implemented": false, "scene": "", "coin_count": 18},
	17: {"id": 17, "name": "No Turning Back", "world_id": 4, "implemented": false, "scene": "", "coin_count": 20},
	18: {"id": 18, "name": "The Developer Laughs", "world_id": 4, "implemented": false, "scene": "", "coin_count": 15},
	19: {"id": 19, "name": "Dragon's Doorstep", "world_id": 4, "implemented": false, "scene": "", "coin_count": 22},
	20: {"id": 20, "name": "Dragon's Den", "world_id": 4, "implemented": false, "scene": "", "coin_count": 25}
}

var shown_stage_intros: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	_setup_input_actions()

func _setup_input_actions() -> void:
	# Ensure custom actions exist with desktop and keyboard bindings
	_ensure_action("move_left", [KEY_LEFT, KEY_A])
	_ensure_action("move_right", [KEY_RIGHT, KEY_D])
	_ensure_action("jump", [KEY_SPACE, KEY_UP, KEY_W])
	_ensure_action("pause", [KEY_ESCAPE])

func _ensure_action(action_name: String, key_codes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for code in key_codes:
		var has_key := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == code:
				has_key = true
				break
		if not has_key:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action_name, event)

func get_level_info(level_id: int) -> Dictionary:
	return levels.get(level_id, {})

func can_play_level(level_id: int) -> bool:
	var info: Dictionary = get_level_info(level_id)
	return bool(info.get("implemented", false))

func get_implemented_level_count() -> int:
	var count: int = 0
	for lvl_id in levels.keys():
		if bool(levels[lvl_id].get("implemented", false)):
			count += 1
	return count

func start_new_run() -> void:
	current_run_id += 1
	revives_used_this_run = 0
	revives_used_this_death = 0
	safe_anchors.clear()
	if level_spawn_point != Vector2.ZERO:
		safe_anchors.append(level_spawn_point)
		last_safe_position = level_spawn_point
	else:
		last_safe_position = Vector2.ZERO

func can_revive_this_run() -> bool:
	return is_gameplay_active and (revives_used_this_run < MAX_REVIVES_PER_RUN)

func go_to_main_menu() -> void:
	is_gameplay_active = false
	start_new_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func go_to_level_select() -> void:
	is_gameplay_active = false
	start_new_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/coin_hell_level_select.tscn")

func start_level(level_id: int) -> bool:
	var info: Dictionary = get_level_info(level_id)
	if not info.get("implemented", false):
		return false

	current_level_id = level_id
	total_coins_required = int(info.get("coin_count", 10))
	current_coins = 0
	is_gameplay_active = true
	start_new_run()
	get_tree().paused = false

	var scene_path: String = info.get("scene", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Scene file missing: " + scene_path)
		return false

	if get_tree().current_scene and get_tree().current_scene.name == "TestRunner":
		return true

	get_tree().change_scene_to_file(scene_path)
	return true

func restart_current_level() -> void:
	start_level(current_level_id)

func reset_coins() -> void:
	current_coins = 0
	start_new_run()
	coin_collected.emit(current_coins, total_coins_required)
	coins_reset.emit()

func collect_coin() -> void:
	current_coins = clampi(current_coins + 1, 0, total_coins_required)
	coin_collected.emit(current_coins, total_coins_required)
	AudioManager.play_sfx("coin")

func are_all_coins_collected() -> bool:
	return current_coins >= total_coins_required

func trigger_level_complete() -> void:
	if not is_gameplay_active:
		return
	is_gameplay_active = false
	last_run_stars = 2 if revives_used_this_run > 0 else 3
	SaveManager.complete_level(current_level_id, last_run_stars)
	AudioManager.play_sfx("complete")
	level_completed.emit(current_level_id)

func trigger_player_death() -> void:
	AudioManager.play_sfx("death")
	# A new death resets the revive eligibility for this specific death event
	revives_used_this_death = 0
	player_died.emit()

func register_player(p: CharacterBody2D) -> void:
	active_player = p
	if not p.tree_exiting.is_connected(_on_player_tree_exiting):
		p.tree_exiting.connect(_on_player_tree_exiting)

func _on_player_tree_exiting() -> void:
	active_player = null

func set_level_spawn_point(pos: Vector2) -> void:
	level_spawn_point = pos
	safe_anchors.clear()
	if pos != Vector2.ZERO:
		safe_anchors.append(pos)
	last_safe_position = pos

func register_safe_anchor(pos: Vector2) -> void:
	record_safe_position(pos)

func record_safe_position(pos: Vector2) -> void:
	# Only register candidate foothold if it is within reasonable bounds above pits
	if pos.y >= 480.0 or pos.y <= 0.0:
		return
	if safe_anchors.is_empty():
		safe_anchors.append(pos)
		last_safe_position = pos
		return
	var last_pos: Vector2 = safe_anchors.back()
	if pos.distance_to(last_pos) >= 48.0:
		safe_anchors.append(pos)
		last_safe_position = pos
		if safe_anchors.size() > 15:
			safe_anchors.pop_front()

func record_death_position(pos: Vector2) -> void:
	last_death_position = pos

func is_position_safe_for_spawn(pos: Vector2) -> bool:
	if pos.y >= 480.0 or pos.y <= 0.0:
		return false

	var p: CharacterBody2D = active_player
	if p == null or not is_instance_valid(p) or not p.is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			p = players[0]

	if p and is_instance_valid(p) and p.is_inside_tree() and p.get_world_2d():
		var space_state := p.get_world_2d().direct_space_state
		var col_shape := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if space_state and col_shape and col_shape.shape:
			# 1. Physics query for overlapping hazards (layer 4)
			var shape_query := PhysicsShapeQueryParameters2D.new()
			shape_query.shape = col_shape.shape
			shape_query.transform = Transform2D(0.0, pos + col_shape.position)
			shape_query.collision_mask = 4 # Hazard layer (spikes, crushers, etc.)
			shape_query.collide_with_areas = true
			shape_query.collide_with_bodies = true
			var hazard_hits := space_state.intersect_shape(shape_query, 1)
			if not hazard_hits.is_empty():
				print("[GameManager] Candidate anchor %s rejected: intersects lethal hazard." % str(pos))
				return false

			# 2. Physics query for overlapping walls (layer 2)
			shape_query.collision_mask = 2 # Solid wall layer
			shape_query.collide_with_areas = false
			shape_query.collide_with_bodies = true
			var wall_hits := space_state.intersect_shape(shape_query, 1)
			if not wall_hits.is_empty():
				print("[GameManager] Candidate anchor %s rejected: inside wall geometry." % str(pos))
				return false

			# 3. Physics raycast down 32px to ensure solid ground support
			var ray_query := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, 32), 2)
			var ground_hit := space_state.intersect_ray(ray_query)
			if ground_hit.is_empty():
				print("[GameManager] Candidate anchor %s rejected: no ground support beneath." % str(pos))
				return false

			var collider = ground_hit.get("collider")
			if collider is Node:
				if collider.is_in_group("hazard") or collider.is_in_group("traps"):
					return false
				if collider.get_script():
					var s_path: String = collider.get_script().resource_path.to_lower()
					if "falling" in s_path or "crumbling" in s_path or "fake" in s_path or "greedy" in s_path:
						return false
				if collider.has_method("is_triggered") and collider.call("is_triggered"):
					return false

	return true

func find_safe_revive_position(death_pos: Vector2) -> Vector2:
	# Priority 1: Search backwards through verified safe anchors history
	for i in range(safe_anchors.size() - 1, -1, -1):
		var candidate: Vector2 = safe_anchors[i]
		if is_position_safe_for_spawn(candidate):
			print("[GameManager] Selected verified safe anchor from history: %s" % str(candidate))
			return candidate

	# Priority 2: Use validated level spawn point
	if level_spawn_point != Vector2.ZERO and is_position_safe_for_spawn(level_spawn_point):
		print("[GameManager] Selected validated level spawn point: %s" % str(level_spawn_point))
		return level_spawn_point

	# Priority 3: Fallback to level SpawnPoint node in active tree
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p.get_parent():
			var spawn_node = p.get_parent().get_node_or_null("SpawnPoint")
			if spawn_node is Marker2D or spawn_node is Node2D:
				return spawn_node.global_position

	# Safe elevated fallback above pits
	return Vector2(100.0, 350.0)

func revive_current_player() -> bool:
	if not can_revive_this_run():
		push_warning("[GameManager] Revive rejected: Run allowance exceeded (%d/%d) or gameplay inactive." % [revives_used_this_run, MAX_REVIVES_PER_RUN])
		return false

	var p: CharacterBody2D = active_player
	if p == null or not is_instance_valid(p):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			p = players[0]

	if p == null or not is_instance_valid(p):
		push_warning("[GameManager] Revive requested but no active player found.")
		return false

	# 1. Select verified safe target position
	var target_safe_pos := find_safe_revive_position(last_death_position)

	# 2. Reset dynamic traps and platforms to intact state BEFORE placing player
	player_revived.emit(target_safe_pos)

	# 3. Position and restore player state authoritatively
	p.global_position = target_safe_pos
	p.revive()
	p.apply_spawn_protection(1.5) # 1.5s bounded spawn protection with flicker

	# 4. Consume 1-revive allowance
	revives_used_this_run += 1
	revives_used_this_death += 1

	# 5. Restore gameplay
	is_gameplay_active = true
	get_tree().paused = false

	AudioManager.play_sfx("coin")
	print("[GameManager] Player successfully revived at verified safe anchor: %s (run revives: %d/%d)" % [str(target_safe_pos), revives_used_this_run, MAX_REVIVES_PER_RUN])
	return true

func get_world_id_for_stage(stage_id: int) -> int:
	if stage_id <= 5:
		return 1
	elif stage_id <= 10:
		return 2
	elif stage_id <= 15:
		return 3
	else:
		return 4

func get_world_name(world_id: int) -> String:
	if worlds.has(world_id):
		return str(worlds[world_id].get("name", ""))
	return ""

func get_world_name_for_stage(stage_id: int) -> String:
	return get_world_name(get_world_id_for_stage(stage_id))

func get_stage_hud_label(stage_id: int) -> String:
	var wid := get_world_id_for_stage(stage_id)
	return "WORLD %d · STAGE %d" % [wid, stage_id]

func get_stage_title(stage_id: int) -> String:
	var info: Dictionary = get_level_info(stage_id)
	return str(info.get("name", "STAGE %d" % stage_id))

func should_show_stage_intro(stage_id: int) -> bool:
	return not shown_stage_intros.get(stage_id, false)

func mark_stage_intro_shown(stage_id: int) -> void:
	shown_stage_intros[stage_id] = true

func reset_stage_intros() -> void:
	shown_stage_intros.clear()

func present_stage_intro(parent: Node, stage_id: int) -> Node:
	if not should_show_stage_intro(stage_id):
		return null
	mark_stage_intro_shown(stage_id)
	var intro_scene: PackedScene = load("res://scenes/shared/stage_intro_card.tscn")
	if not intro_scene:
		return null
	var card = intro_scene.instantiate()
	parent.add_child(card)
	var wid := get_world_id_for_stage(stage_id)
	var wname := get_world_name(wid)
	var sname := get_stage_title(stage_id)
	if card.has_method("setup"):
		card.setup(wid, wname, stage_id, sname)
	return card

func setup_level_hud(level_root: Node, stage_id: int) -> void:
	var top_bar: Node = level_root.get_node_or_null("HUD/MarginContainer/TopBar")
	if top_bar:
		var world_stage_text := get_stage_hud_label(stage_id)
		var target_lbl: Label = null
		if top_bar.has_node("WorldName"):
			target_lbl = top_bar.get_node("WorldName")
		elif top_bar.has_node("LevelInfoBox/WorldTitle"):
			target_lbl = top_bar.get_node("LevelInfoBox/WorldTitle")
		elif top_bar.has_node("LevelName"):
			target_lbl = top_bar.get_node("LevelName")
		elif top_bar.has_node("LevelTitle"):
			target_lbl = top_bar.get_node("LevelTitle")
		if target_lbl:
			target_lbl.text = world_stage_text

	var spawn_node = level_root.get_node_or_null("SpawnPoint")
	if spawn_node is Marker2D or spawn_node is Node2D:
		set_level_spawn_point(spawn_node.global_position)

	present_stage_intro(level_root, stage_id)


