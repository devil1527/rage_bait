class_name BulletBetrayalLevel9
extends Node2D

## World 2 Level 4 (Stage 9): "Worm Minefield" for Bullet Betrayal.
## World: DESERT OUTPOST.
## Multi-elevation uneven desert terrain (raised mesas, sunken canyon basins,
## narrow stepping pillars, deep pits, steep climbs, and controlled descents)
## with ZERO overhead bars or sky-bridge bypasses.
## Level 8-speed sandworms coordinate unique underground exit locations:
## every completed retreat buries one permanent stationary proximity mine at
## the exact disappearance coordinate, and that exit is permanently recorded in
## used-exit history for the current level attempt (never reused by any worm).
## Mandatory Rules: 10 starting bullets, 10 required enemies, 1-hit enemy kills,
## 0 ammo pickups, locked extraction beacon requiring 10 kills, safe-position revive.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const WORM_MINE_SCENE: PackedScene = preload("res://scenes/bullet_betrayal/bb_worm_mine.tscn")

const TOTAL_REQUIRED_ENEMIES: int = 10
const MAX_ACTIVE_MINES: int = 10
const MAX_MINES_PER_ZONE: int = 3
const MIN_MINE_SPACING: float = 44.0
const MIN_EXIT_SPACING: float = 44.0
const PLATFORM_EDGE_MARGIN: float = 46.0
const SAFE_SPAWN_MAX_X: float = 360.0
const EXTRACTION_CLEARANCE: float = 95.0
const PLAYER_CLEARANCE_X: float = 58.0
const PLAYER_CLEARANCE_Y: float = 56.0
const SAFE_CLEANUP_MIN_PLAYER_DIST: float = 180.0
const SAFE_CLEANUP_ABS_MIN_DIST: float = 96.0

@export var max_active_mines: int = MAX_ACTIVE_MINES
@export var max_mines_per_zone: int = MAX_MINES_PER_ZONE
@export var min_exit_spacing: float = MIN_EXIT_SPACING

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = get_node_or_null("HUD/IntroBanner")
@onready var enemies_container: Node2D = $Enemies
@onready var worms_container: Node2D = get_node_or_null("Worms")
@onready var worm_mines_container: Node2D = get_node_or_null("WormMines")
@onready var platforms_container: Node2D = get_node_or_null("Platforms")
@onready var props_container: Node2D = get_node_or_null("EnvironmentProps")

var _enemies_eliminated: int = 0
var _is_completed: bool = false
var _mines_spawned_count: int = 0
var _mines_disarmed_count: int = 0
var _used_exit_positions: Array[Vector2] = []
var _exit_reservations: Dictionary = {} # worm instance_id (int) -> Vector2


func _ready() -> void:
	_used_exit_positions.clear()
	_exit_reservations.clear()

	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		GameManager.current_run_id += 1

	if hud and player:
		hud.current_stage_id = 9
		hud.stage_clear_subtitle = "WORM MINEFIELD CLEARED"
		hud.update_stage_title(9)
		hud.connect_player(player)
		hud.restart_requested.connect(restart_level)
		hud.menu_requested.connect(return_to_menu)
		hud.arcade_requested.connect(_on_arcade_requested)
		hud.revive_requested.connect(_on_player_revived)
		hud.update_targets(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)

	_update_camera_framing()
	if get_viewport() and not get_viewport().size_changed.is_connected(_update_camera_framing):
		get_viewport().size_changed.connect(_update_camera_framing)
	if player:
		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.reset_smoothing()

	if extraction_beacon:
		extraction_beacon.required_enemies = TOTAL_REQUIRED_ENEMIES
		extraction_beacon.update_target_progress(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)
		extraction_beacon.extraction_reached.connect(_on_extraction_reached)

	_setup_enemy_signals()
	_setup_worm_signals()
	_animate_intro_banner()


func _update_camera_framing() -> void:
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam:
		return
	cam.limit_left = 0
	cam.limit_right = 3655
	cam.limit_top = 40
	cam.limit_bottom = 540

	var vp := get_viewport()
	var vis_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(960.0, 540.0)
	if vis_size.x <= 0.0 or vis_size.y <= 0.0:
		vis_size = Vector2(960.0, 540.0)

	var target_vis_height: float = 360.0
	var base_zoom: float = clampf(vis_size.y / target_vis_height, 1.30, 1.60)
	var max_horz_zoom: float = vis_size.x / 640.0
	var final_zoom: float = clampf(minf(base_zoom, max_horz_zoom), 1.20, 1.60)
	cam.zoom = Vector2(final_zoom, final_zoom)


func _exit_tree() -> void:
	_exit_reservations.clear()
	if GameManager:
		GameManager.is_gameplay_active = false


func _setup_enemy_signals() -> void:
	if not enemies_container:
		return
	for enemy in enemies_container.get_children():
		if enemy is BulletBetrayalEnemySoldier:
			if not enemy.eliminated.is_connected(_on_enemy_eliminated):
				enemy.eliminated.connect(_on_enemy_eliminated)


func _setup_worm_signals() -> void:
	if not worms_container:
		return
	for worm in worms_container.get_children():
		if worm is BulletBetrayalDesertWorm:
			worm.require_exit_validation = true
			worm.exit_coordinator = self
			if not worm.submerged_at.is_connected(_on_worm_submerged_at_for_worm):
				worm.submerged_at.connect(_on_worm_submerged_at_for_worm.bind(worm))


func _animate_intro_banner() -> void:
	if not intro_banner:
		return
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(intro_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.0)
	tween.tween_property(intro_banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): if is_instance_valid(intro_banner): intro_banner.visible = false)


func _physics_process(_delta: float) -> void:
	if player and player.is_alive and player.global_position.y > 518.0:
		player.die()


func _on_worm_submerged_at_for_worm(world_pos: Vector2, worm: BulletBetrayalDesertWorm = null) -> void:
	var w_id: int = worm.get_instance_id() if is_instance_valid(worm) else -1
	var had_reservation := (w_id != -1 and _exit_reservations.has(w_id))
	if had_reservation:
		_exit_reservations.erase(w_id)
		_place_mine_for_completed_retreat(world_pos)
		return
	try_spawn_worm_mine(world_pos)


func _place_mine_for_completed_retreat(world_pos: Vector2) -> BulletBetrayalWormMine:
	if not worm_mines_container or not WORM_MINE_SCENE:
		return null

	var snapped_surface_y := _find_valid_ground_surface_y(world_pos)
	var final_pos := Vector2(world_pos.x, snapped_surface_y if not is_nan(snapped_surface_y) else world_pos.y)
	var zone_id := get_zone_for_x(final_pos.x)
	_ensure_mine_capacity_for_zone(zone_id)

	return _instantiate_and_record_mine(final_pos)


func try_spawn_worm_mine(world_pos: Vector2) -> BulletBetrayalWormMine:
	if not worm_mines_container or not WORM_MINE_SCENE:
		return null

	var snapped_surface_y := _find_valid_ground_surface_y(world_pos)
	if is_nan(snapped_surface_y):
		return null

	var candidate_pos := Vector2(world_pos.x, snapped_surface_y)
	if not can_place_mine_at(candidate_pos):
		return null

	var zone_id := get_zone_for_x(candidate_pos.x)
	if not _ensure_mine_capacity_for_zone(zone_id):
		return null

	return _instantiate_and_record_mine(candidate_pos)


func _instantiate_and_record_mine(surface_pos: Vector2) -> BulletBetrayalWormMine:
	var mine := WORM_MINE_SCENE.instantiate() as BulletBetrayalWormMine
	if not mine:
		return null
	mine.position = surface_pos
	worm_mines_container.add_child(mine)
	_mines_spawned_count += 1
	_record_used_exit(surface_pos)
	return mine


func _record_used_exit(surface_pos: Vector2) -> void:
	for existing in _used_exit_positions:
		if existing.distance_to(surface_pos) < 1.0:
			return
	_used_exit_positions.append(surface_pos)


func is_valid_exit_position(world_pos: Vector2, requesting_worm: Node = null, check_player: bool = true) -> bool:
	if world_pos.x < SAFE_SPAWN_MAX_X:
		return false

	if extraction_beacon and world_pos.distance_to(extraction_beacon.global_position) < EXTRACTION_CLEARANCE:
		return false

	var surface_y := _find_valid_ground_surface_y(world_pos)
	if is_nan(surface_y):
		return false

	var check_pos := Vector2(world_pos.x, surface_y)
	if _is_blocked_by_wall_or_platform(Vector2(world_pos.x, surface_y - 6.0)):
		return false

	if _is_blocked_by_prop(check_pos):
		return false

	if check_player and player and (not ("is_alive" in player) or player.is_alive):
		var dx := absf(player.global_position.x - check_pos.x)
		var dy := absf(player.global_position.y - (surface_y - 16.0))
		if dx < PLAYER_CLEARANCE_X and dy < PLAYER_CLEARANCE_Y:
			return false

	for mine in get_active_worm_mines():
		if mine.global_position.distance_to(check_pos) < min_exit_spacing:
			return false

	for used_pos in _used_exit_positions:
		if used_pos.distance_to(check_pos) < min_exit_spacing:
			return false

	var requester_id: int = requesting_worm.get_instance_id() if is_instance_valid(requesting_worm) else -1
	for worm_id in _exit_reservations.keys():
		if worm_id == requester_id:
			continue
		var reserved_pos: Vector2 = _exit_reservations[worm_id]
		if reserved_pos.distance_to(check_pos) < min_exit_spacing:
			return false

	return true


func can_place_mine_at(world_pos: Vector2, requesting_worm: Node = null) -> bool:
	return is_valid_exit_position(world_pos, requesting_worm, true)


func request_worm_exit(worm: BulletBetrayalDesertWorm) -> float:
	if not is_instance_valid(worm):
		return -99999.0

	release_worm_exit(worm)

	var left_x: float = worm.territory_min_x + 22.0
	var right_x: float = worm.territory_max_x - 22.0
	if right_x <= left_x:
		return -99999.0

	var probe_pos := Vector2(clampf(worm.global_position.x, left_x, right_x), worm.surface_y)
	var zone_id := get_zone_for_x(probe_pos.x)
	if not _can_zone_accept_new_mine(zone_id):
		return -99999.0

	var candidates: Array[float] = []
	var scan_x: float = left_x
	while scan_x <= right_x + 0.01:
		var cand_pos := Vector2(scan_x, worm.surface_y)
		if is_valid_exit_position(cand_pos, worm, true):
			candidates.append(scan_x)
		scan_x += 4.0

	if candidates.is_empty():
		return -99999.0

	# Prefer varied exits separated from the worm's emergence spot when options allow
	var varied: Array[float] = []
	for cx in candidates:
		if absf(cx - worm._last_emerge_x) >= 24.0:
			varied.append(cx)
	var pool: Array[float] = varied if not varied.is_empty() else candidates
	var chosen_x: float = pool[randi() % pool.size()]
	_exit_reservations[worm.get_instance_id()] = Vector2(chosen_x, worm.surface_y)
	return chosen_x


func can_complete_retreat_at(world_pos: Vector2, worm: Node = null) -> bool:
	if not is_valid_exit_position(world_pos, worm, true):
		return false
	return _can_zone_accept_new_mine(get_zone_for_x(world_pos.x))


func release_worm_exit(worm: Node) -> void:
	if not is_instance_valid(worm):
		return
	_exit_reservations.erase(worm.get_instance_id())


func is_exit_used(world_pos: Vector2) -> bool:
	for used_pos in _used_exit_positions:
		if used_pos.distance_to(world_pos) < min_exit_spacing:
			return true
	return false


func is_exit_reserved(world_pos: Vector2, ignoring_worm: Node = null) -> bool:
	var ignore_id: int = ignoring_worm.get_instance_id() if is_instance_valid(ignoring_worm) else -1
	for worm_id in _exit_reservations.keys():
		if worm_id == ignore_id:
			continue
		var reserved_pos: Vector2 = _exit_reservations[worm_id]
		if reserved_pos.distance_to(world_pos) < min_exit_spacing:
			return true
	return false


func get_used_exit_positions() -> Array[Vector2]:
	return _used_exit_positions.duplicate()


func get_reserved_exits() -> Dictionary:
	return _exit_reservations.duplicate()


func _find_valid_ground_surface_y(world_pos: Vector2) -> float:
	if not platforms_container:
		return NAN

	for node in platforms_container.get_children():
		if not (node is StaticBody2D):
			continue
		if not node.name.begins_with("Ground"):
			continue
		var col := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not col or not (col.shape is RectangleShape2D):
			continue
		var rect := col.shape as RectangleShape2D
		var half := rect.size * 0.5
		var center := (node as StaticBody2D).global_position + col.position
		var left_x := center.x - half.x + PLATFORM_EDGE_MARGIN
		var right_x := center.x + half.x - PLATFORM_EDGE_MARGIN
		var top_y := center.y - half.y
		if world_pos.x >= left_x and world_pos.x <= right_x and absf(world_pos.y - top_y) <= 14.0:
			return top_y

	return NAN


func _is_blocked_by_wall_or_platform(check_pos: Vector2) -> bool:
	if not platforms_container:
		return false

	for node in platforms_container.get_children():
		if not (node is StaticBody2D):
			continue
		if node.name.begins_with("Ground"):
			continue
		var col := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not col or not (col.shape is RectangleShape2D):
			continue
		var rect := col.shape as RectangleShape2D
		var half := rect.size * 0.5
		var center := (node as StaticBody2D).global_position + col.position
		if absf(check_pos.x - center.x) <= half.x + 8.0 and absf(check_pos.y - center.y) <= half.y + 6.0:
			return true

	return false


func _is_blocked_by_prop(surface_pos: Vector2) -> bool:
	if not props_container:
		return false

	for node in props_container.get_children():
		if not (node is Sprite2D):
			continue
		var spr := node as Sprite2D
		if not spr.texture:
			continue
		var half_w := float(spr.texture.get_width()) * 0.5 * absf(spr.scale.x)
		var half_h := float(spr.texture.get_height()) * 0.5 * absf(spr.scale.y)
		var prop_bottom_y := spr.global_position.y + half_h
		if absf(prop_bottom_y - surface_pos.y) <= 14.0:
			if absf(surface_pos.x - spr.global_position.x) < (half_w + 10.0):
				return true

	return false


func get_zone_for_x(x_pos: float) -> int:
	if x_pos < 760.0:
		return 0
	if x_pos < 1350.0:
		return 1
	if x_pos < 2100.0:
		return 2
	if x_pos < 2550.0:
		return 3
	if x_pos < 3180.0:
		return 4
	return 5


func get_active_worm_mines() -> Array[BulletBetrayalWormMine]:
	var result: Array[BulletBetrayalWormMine] = []
	if not worm_mines_container:
		return result
	for child in worm_mines_container.get_children():
		if child is BulletBetrayalWormMine:
			var m := child as BulletBetrayalWormMine
			if is_instance_valid(m) and not m.is_queued_for_deletion() and not m.has_detonated() and not m.is_disarming():
				result.append(m)
	return result


func get_active_mines_in_zone(zone_id: int) -> Array[BulletBetrayalWormMine]:
	var result: Array[BulletBetrayalWormMine] = []
	for mine in get_active_worm_mines():
		if get_zone_for_x(mine.global_position.x) == zone_id:
			result.append(mine)
	return result


func _can_zone_accept_new_mine(zone_id: int) -> bool:
	var zone_mines := get_active_mines_in_zone(zone_id)
	if zone_mines.size() >= max_mines_per_zone and _pick_oldest_distant_mine(zone_mines) == null:
		return false

	var all_mines := get_active_worm_mines()
	if all_mines.size() >= max_active_mines and _pick_oldest_distant_mine(all_mines) == null:
		return false

	return true


func _ensure_mine_capacity_for_zone(zone_id: int) -> bool:
	var zone_mines := get_active_mines_in_zone(zone_id)
	if zone_mines.size() >= max_mines_per_zone:
		var victim := _pick_oldest_distant_mine(zone_mines)
		if not victim:
			return false
		_disarm_mine_safely(victim)

	var all_mines := get_active_worm_mines()
	if all_mines.size() >= max_active_mines:
		var global_victim := _pick_oldest_distant_mine(all_mines)
		if not global_victim:
			return false
		_disarm_mine_safely(global_victim)

	return true


func _pick_oldest_distant_mine(candidates: Array[BulletBetrayalWormMine]) -> BulletBetrayalWormMine:
	if candidates.is_empty():
		return null

	var has_alive_player := player != null and is_instance_valid(player) and (not ("is_alive" in player) or player.is_alive)
	if not has_alive_player:
		return candidates[0]

	# Prefer the oldest candidate well away from the player (>= 180 px).
	for mine in candidates:
		if mine.global_position.distance_to(player.global_position) >= SAFE_CLEANUP_MIN_PLAYER_DIST:
			return mine

	# Fallback only to candidates outside proximity warning range; never delete beside player.
	for mine in candidates:
		if mine.global_position.distance_to(player.global_position) >= SAFE_CLEANUP_ABS_MIN_DIST:
			return mine

	return null


func _disarm_mine_safely(mine: BulletBetrayalWormMine) -> void:
	# Note: intentionally preserves the mine's coordinate inside _used_exit_positions
	# so worms never reuse an exit whose mine was removed by capacity cleanup.
	if is_instance_valid(mine) and not mine.is_disarming():
		mine.disarm_and_cleanup()
		_mines_disarmed_count += 1


func _on_enemy_eliminated() -> void:
	_enemies_eliminated += 1
	if hud:
		hud.update_targets(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)
	if extraction_beacon:
		extraction_beacon.update_target_progress(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)


func _on_extraction_reached() -> void:
	if _is_completed or _enemies_eliminated < TOTAL_REQUIRED_ENEMIES:
		return
	_is_completed = true

	if player:
		player.input_disabled = true
		player.velocity = Vector2.ZERO

	if hud:
		hud.complete_and_record_stage(9, "WORM MINEFIELD CLEARED", player.current_ammo if player else 0)
	else:
		var earned_stars: int = 2 if (GameManager and GameManager.revives_used_this_run > 0) else 3
		if SaveManager:
			SaveManager.complete_bb_level(9, earned_stars)
		if AudioManager:
			AudioManager.play_sfx("complete")


func _on_player_revived() -> void:
	if player:
		var safe_pos: Vector2 = player.get_safe_revive_position()
		player.global_position = safe_pos
		player.velocity = Vector2.ZERO

		# Disperse any surfaced or emerging worm near the revive spot (cancels reservation cleanly; no mine)
		if worms_container:
			for worm in worms_container.get_children():
				if worm is BulletBetrayalDesertWorm and worm.global_position.distance_to(safe_pos) < 95.0:
					if worm.is_emerged() or worm.state == BulletBetrayalDesertWorm.WormState.WARNING:
						worm.force_submerge(1.5)

		# Disarm any active worm mine too close to the respawn anchor so recovery is fair
		for mine in get_active_worm_mines():
			if mine.global_position.distance_to(safe_pos) < 62.0:
				_disarm_mine_safely(mine)

		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.reset_smoothing()
	if hud:
		hud.update_targets(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)


func restart_level() -> void:
	if hud:
		hud.reset_touch_controls()
	get_tree().paused = false
	get_tree().reload_current_scene()


func return_to_menu() -> void:
	if GameManager:
		GameManager.is_gameplay_active = false
	if hud:
		hud.reset_touch_controls()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_arcade_requested() -> void:
	if GameManager:
		GameManager.is_gameplay_active = false
	if hud:
		hud.reset_touch_controls()
	get_tree().paused = false
	get_tree().change_scene_to_file(ARCADE_SCENE)
