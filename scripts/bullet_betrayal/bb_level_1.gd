class_name BulletBetrayalLevel1
extends Node2D

## World 1 Level 1: "The Green Hills" for Bullet Betrayal.
## Orchestrates level lifecycle, player respawns, 10-enemy elimination objective,
## locked/unlocked extraction beacon, ambush trigger zones, and HUD binding.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const TOTAL_REQUIRED_ENEMIES: int = 10

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = $HUD/IntroBanner
@onready var enemies_container: Node2D = $Enemies
@onready var pickups_container: Node2D = $Pickups
@onready var ambushes_container: Node2D = get_node_or_null("Ambushes")

var _enemies_eliminated: int = 0
var _is_completed: bool = false

func _ready() -> void:
	# Critical: Enable gameplay active flag and reset run revives for new attempt
	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		GameManager.current_run_id += 1

	# Bind HUD
	if hud and player:
		hud.connect_player(player)
		hud.restart_requested.connect(restart_level)
		hud.menu_requested.connect(return_to_menu)
		hud.arcade_requested.connect(_on_arcade_requested)
		hud.revive_requested.connect(_on_player_revived)
		hud.update_targets(_enemies_eliminated, TOTAL_REQUIRED_ENEMIES)

	# Bind Extraction
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
	tween.tween_interval(1.8)
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
	if hud:
		hud.show_victory(player.current_ammo if player else 0)

func _on_player_revived() -> void:
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
