class_name BulletBetrayalLevel5
extends Node2D

## World 1 Level 5: "Operation Last Stand" for Bullet Betrayal.
## The climax and hardest stage of World 1.
## Introduces surprise explosive rushers that emerge from cover and sprint
## towards the player with accelerating alarm beeps, alongside mobile hunting
## mines and stationary minefields.
## Exact Rules: 10 bullets, 10 required enemies, 1-hit enemy kills,
## 3 explosive rushers + 7 soldiers, 0 ammo pickups.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const TOTAL_REQUIRED_ENEMIES: int = 10

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = get_node_or_null("HUD/IntroBanner")
@onready var enemies_container: Node2D = $Enemies
@onready var landmines_container: Node2D = get_node_or_null("Landmines")
@onready var hunting_mines_container: Node2D = get_node_or_null("HuntingMines")
@onready var pickups_container: Node2D = get_node_or_null("Pickups")
@onready var ambushes_container: Node2D = get_node_or_null("Ambushes")

var _enemies_eliminated: int = 0
var _is_completed: bool = false

func _ready() -> void:
	# Enable gameplay active flag and reset run revives for new attempt
	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		GameManager.current_run_id += 1

	# Bind HUD
	if hud and player:
		hud.current_stage_id = 5
		hud.stage_clear_subtitle = "OPERATION LAST STAND CLEARED"
		hud.update_stage_title(5)
		hud.connect_player(player)
		hud.restart_requested.connect(restart_level)
		hud.menu_requested.connect(return_to_menu)
		hud.arcade_requested.connect(_on_arcade_requested)
		hud.revive_requested.connect(_on_player_revived)
		hud.update_targets(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)

	# Configure Level 5 camera boundary to encompass extraction beacon zone
	if player:
		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_right = 2860
			cam.limit_top = 0
			cam.limit_bottom = 540
			cam.reset_smoothing()

	# Bind Extraction Beacon
	if extraction_beacon:
		extraction_beacon.required_enemies = TOTAL_REQUIRED_ENEMIES
		extraction_beacon.update_target_progress(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)
		extraction_beacon.extraction_reached.connect(_on_extraction_reached)

	# Bind Enemy signals
	_setup_enemy_signals()

	# Intro Banner animation
	_animate_intro_banner()

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
	# Pit hazard check: falling below level bounds
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

	# Calculate stars: 3 stars for clean run (0 revives), 2 stars if revived
	var earned_stars: int = 2 if (GameManager and GameManager.revives_used_this_run > 0) else 3
	if SaveManager:
		SaveManager.complete_bb_level(5, earned_stars)
	if AudioManager:
		AudioManager.play_sfx("complete")

	if hud:
		hud.current_stage_id = 5
		hud.stage_clear_subtitle = "OPERATION LAST STAND CLEARED"
		hud.show_victory(player.current_ammo if player else 0, earned_stars)

func _on_player_revived() -> void:
	if player and spawn_point:
		player.global_position = spawn_point.global_position
		player.velocity = Vector2.ZERO
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
