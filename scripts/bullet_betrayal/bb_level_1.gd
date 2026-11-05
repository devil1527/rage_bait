class_name BulletBetrayalLevel1
extends Node2D

## World 1 Level 1: "The Green Hills" for Bullet Betrayal.
## Orchestrates level lifecycle, player respawns, HUD binding, and completion.

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var extraction_beacon: BulletBetrayalExtractionBeacon = $ExtractionBeacon
@onready var intro_banner: Control = $HUD/IntroBanner
@onready var enemies_container: Node2D = $Enemies
@onready var pickups_container: Node2D = $Pickups

var _enemies_eliminated: int = 0
var _is_completed: bool = false

func _ready() -> void:
	# Bind HUD
	if hud and player:
		hud.connect_player(player)
		hud.restart_requested.connect(restart_level)
		hud.menu_requested.connect(return_to_menu)

	# Bind Extraction
	if extraction_beacon:
		extraction_beacon.extraction_reached.connect(_on_extraction_reached)

	# Bind Enemy signals
	_setup_enemy_signals()

	# Intro Banner animation
	_animate_intro_banner()

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
	tween.tween_callback(func(): intro_banner.visible = false)

func _physics_process(_delta: float) -> void:
	# Pit hazard check: falling below level bounds
	if player and player.is_alive and player.global_position.y > 520.0:
		player.die()

func _on_enemy_eliminated() -> void:
	_enemies_eliminated += 1

func _on_extraction_reached() -> void:
	if _is_completed:
		return
	_is_completed = true
	if player:
		player.input_disabled = true
		player.velocity = Vector2.ZERO
	if hud:
		hud.show_victory(player.current_ammo if player else 0)

func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
