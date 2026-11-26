class_name BulletBetrayalLevel8
extends Node2D

## World 2 Level 3 (Stage 8): "Desert Worm Nightmare" for Bullet Betrayal.
## World: DESERT OUTPOST.
## Escalates World 2's subterranean Desert Sandworm threat with faster worms,
## tighter visual warning windows, unpredictable emergence cadences, dual-worm
## crossfire basins, ahead-of-route ambushers, desert landmines, and canyon leaps.
## Mandatory Rules: 10 starting bullets, 10 required enemies, 1-hit enemy kills,
## 0 ammo pickups, locked extraction beacon requiring 10 kills, safe-position revive.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const TOTAL_REQUIRED_ENEMIES: int = 10

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = get_node_or_null("HUD/IntroBanner")
@onready var enemies_container: Node2D = $Enemies
@onready var worms_container: Node2D = get_node_or_null("Worms")
@onready var landmines_container: Node2D = get_node_or_null("Landmines")

var _enemies_eliminated: int = 0
var _is_completed: bool = false


func _ready() -> void:
	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		GameManager.current_run_id += 1

	if hud and player:
		hud.current_stage_id = 8
		hud.stage_clear_subtitle = "DESERT WORM NIGHTMARE CLEARED"
		hud.update_stage_title(8)
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
	_animate_intro_banner()


func _update_camera_framing() -> void:
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam:
		return
	cam.limit_left = 0
	cam.limit_right = 3165
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
		hud.complete_and_record_stage(8, "DESERT WORM NIGHTMARE CLEARED", player.current_ammo if player else 0)
	else:
		var earned_stars: int = 2 if (GameManager and GameManager.revives_used_this_run > 0) else 3
		if SaveManager:
			SaveManager.complete_bb_level(8, earned_stars)
		if AudioManager:
			AudioManager.play_sfx("complete")


func _on_player_revived() -> void:
	if player:
		var safe_pos: Vector2 = player.get_safe_revive_position()
		player.global_position = safe_pos
		player.velocity = Vector2.ZERO

		# Disperse any surfaced or emerging worm right beside respawn anchor for fair recovery
		if worms_container:
			for worm in worms_container.get_children():
				if worm is BulletBetrayalDesertWorm and worm.global_position.distance_to(safe_pos) < 95.0:
					if worm.is_emerged() or worm.state == BulletBetrayalDesertWorm.WormState.WARNING:
						worm.force_submerge(1.2)

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
