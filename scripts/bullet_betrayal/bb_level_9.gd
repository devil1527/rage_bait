class_name BulletBetrayalLevel9
extends Node2D

## World 2 Level 4 (Stage 9): "Worm Minefield" for Bullet Betrayal.
## World: DESERT OUTPOST.
## Introduces slower, cunning subterranean desert sandworms that leave a
## partially buried proximity mine at each completed retreat underground.
## Difficulty comes from accumulating battlefield pressure, multi-worm basins,
## tactical waiting decisions, and elevated watchtower escape routes while
## guaranteeing fair landing/takeoff clearances and safe cap cleanup.
## Mandatory Rules: 10 starting bullets, 10 required enemies, 1-hit enemy kills,
## 0 ammo pickups, locked extraction beacon requiring 10 kills, safe-position revive.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const WORM_MINE_SCENE: PackedScene = preload("res://scenes/bullet_betrayal/bb_worm_mine.tscn")

const TOTAL_REQUIRED_ENEMIES: int = 10
const MAX_ACTIVE_MINES: int = 8
const MAX_MINES_PER_ZONE: int = 3
const MIN_MINE_SPACING: float = 42.0
const PLATFORM_EDGE_MARGIN: float = 42.0
const SAFE_SPAWN_MAX_X: float = 480.0
const EXTRACTION_CLEARANCE: float = 95.0
const PLAYER_CLEARANCE_X: float = 58.0
const PLAYER_CLEARANCE_Y: float = 56.0
const SAFE_CLEANUP_MIN_PLAYER_DIST: float = 180.0
const SAFE_CLEANUP_ABS_MIN_DIST: float = 96.0

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = get_node_or_null("HUD/IntroBanner")
@onready var enemies_container: Node2D = $Enemies
@onready var worms_container: Node2D = get_node_or_null("Worms")
@onready var worm_mines_container: Node2D = get_node_or_null("WormMines")
@onready var platforms_container: Node2D = get_node_or_null("Platforms")

var _enemies_eliminated: int = 0
var _is_completed: bool = false
var _mines_spawned_count: int = 0
var _mines_disarmed_count: int = 0


func _ready() -> void:
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
	cam.limit_right = 3240
	cam.limit_top = 80
	cam.limit_bottom = 508

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
			if not worm.submerged_at.is_connected(_on_worm_submerged_at):
				worm.submerged_at.connect(_on_worm_submerged_at)


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
	if player and player.is_alive and player.global_position.y > 520.0:
		player.die()


func _on_worm_submerged_at(world_pos: Vector2) -> void:
	try_spawn_worm_mine(world_pos)


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

	var mine := WORM_MINE_SCENE.instantiate() as BulletBetrayalWormMine
	if not mine:
		return null
	mine.position = candidate_pos
	worm_mines_container.add_child(mine)
	_mines_spawned_count += 1
	return mine


func can_place_mine_at(world_pos: Vector2) -> bool:
	if world_pos.x < SAFE_SPAWN_MAX_X:
		return false

	if extraction_beacon and world_pos.distance_to(extraction_beacon.global_position) < EXTRACTION_CLEARANCE:
		return false

	var surface_y := _find_valid_ground_surface_y(world_pos)
	if is_nan(surface_y):
		return false

	if _is_blocked_by_wall_or_platform(Vector2(world_pos.x, surface_y - 6.0)):
		return false

	if player and (not ("is_alive" in player) or player.is_alive):
		var dx := absf(player.global_position.x - world_pos.x)
		var dy := absf(player.global_position.y - (surface_y - 16.0))
		if dx < PLAYER_CLEARANCE_X and dy < PLAYER_CLEARANCE_Y:
			return false

	for mine in get_active_worm_mines():
		if mine.global_position.distance_to(Vector2(world_pos.x, surface_y)) < MIN_MINE_SPACING:
			return false

	return true


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


func get_zone_for_x(x_pos: float) -> int:
	if x_pos < 1100.0:
		return 0
	if x_pos < 1980.0:
		return 1
	if x_pos < 2320.0:
		return 2
	return 3


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


func _ensure_mine_capacity_for_zone(zone_id: int) -> bool:
	var zone_mines := get_active_mines_in_zone(zone_id)
	if zone_mines.size() >= MAX_MINES_PER_ZONE:
		var victim := _pick_oldest_distant_mine(zone_mines)
		if not victim:
			return false
		_disarm_mine_safely(victim)

	var all_mines := get_active_worm_mines()
	if all_mines.size() >= MAX_ACTIVE_MINES:
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

		# Disperse any surfaced or emerging worm near the revive spot (does not drop a mine)
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
