class_name BulletBetrayalHUD
extends CanvasLayer

## Mobile-first gameplay HUD for Bullet Betrayal.
## Manages health display, ammunition counters, dry-fire alerts,
## on-screen multitouch controls, and gameplay state overlays.

signal restart_requested
signal menu_requested

@onready var health_label: Label = $TopBar/HBox/HealthBox/HealthLabel
@onready var ammo_label: Label = $TopBar/HBox/AmmoBox/AmmoLabel
@onready var stage_label: Label = $TopBar/HBox/StageBox/StageLabel
@onready var pause_btn: Button = $TopBar/PauseBtn

# Overlays
@onready var pause_overlay: Control = $Overlays/PauseOverlay
@onready var death_overlay: Control = $Overlays/DeathOverlay
@onready var victory_overlay: Control = $Overlays/VictoryOverlay

# Pause Overlay buttons
@onready var pause_resume_btn: Button = $Overlays/PauseOverlay/Panel/VBox/ResumeBtn
@onready var pause_restart_btn: Button = $Overlays/PauseOverlay/Panel/VBox/RestartBtn
@onready var pause_menu_btn: Button = $Overlays/PauseOverlay/Panel/VBox/MenuBtn

# Death Overlay buttons
@onready var death_retry_btn: Button = $Overlays/DeathOverlay/Panel/VBox/RetryBtn
@onready var death_menu_btn: Button = $Overlays/DeathOverlay/Panel/VBox/MenuBtn

# Victory Overlay buttons
@onready var victory_replay_btn: Button = $Overlays/VictoryOverlay/Panel/VBox/ReplayBtn
@onready var victory_menu_btn: Button = $Overlays/VictoryOverlay/Panel/VBox/MenuBtn
@onready var victory_stats_label: Label = $Overlays/VictoryOverlay/Panel/VBox/StatsLabel

# Touch Controls container
@onready var touch_controls: Control = $TouchControls

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pause_btn.pressed.connect(_on_pause_pressed)
	pause_resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_restart_btn.pressed.connect(_on_restart_pressed)
	pause_menu_btn.pressed.connect(_on_menu_pressed)
	
	death_retry_btn.pressed.connect(_on_restart_pressed)
	death_menu_btn.pressed.connect(_on_menu_pressed)
	
	victory_replay_btn.pressed.connect(_on_restart_pressed)
	victory_menu_btn.pressed.connect(_on_menu_pressed)
	
	pause_overlay.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false

func connect_player(player: BulletBetrayalPlayer) -> void:
	player.health_updated.connect(update_health)
	player.ammo_updated.connect(update_ammo)
	player.dry_fire.connect(_on_dry_fire)
	player.player_died.connect(_on_player_died)
	update_health(player.current_health, player.max_health)
	update_ammo(player.current_ammo, player.max_ammo)

func update_health(current: int, max_amount: int) -> void:
	if not health_label:
		return
	var text_val := ""
	for i in range(max_amount):
		if i < current:
			text_val += "♥ "
		else:
			text_val += "♡ "
	health_label.text = "HP: " + text_val.strip_edges()
	if current <= 1:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	else:
		health_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))

func update_ammo(current: int, _max_amount: int) -> void:
	if not ammo_label:
		return
	ammo_label.text = "AMMO: %d" % current
	if current == 0:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	elif current <= 4:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1.0))
	else:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))

func _on_dry_fire() -> void:
	if not ammo_label:
		return
	var tween := create_tween()
	tween.tween_property(ammo_label, "modulate", Color(2.0, 0.2, 0.2, 1.0), 0.05)
	tween.tween_property(ammo_label, "modulate", Color.WHITE, 0.1)

func show_pause() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = true
	get_tree().paused = true

func _on_pause_pressed() -> void:
	show_pause()

func _on_pause_resume_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false
	get_tree().paused = false
	restart_requested.emit()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	menu_requested.emit()

func _on_player_died() -> void:
	var death_timer := get_tree().create_timer(0.4)
	death_timer.timeout.connect(func():
		death_overlay.visible = true
	)

func show_victory(ammo_remaining: int) -> void:
	if victory_stats_label:
		victory_stats_label.text = "MISSION ACCOMPLISHED\nAMMO REMAINING: %d BULLETS" % ammo_remaining
	victory_overlay.visible = true
