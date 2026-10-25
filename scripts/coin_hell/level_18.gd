extends Node2D

## Level 18: "The Rising Abyss" — World 4: Final Hell Stage 3
## Escalating challenge significantly harder than Levels 16 & 17:
## - Rising Abyss hazard climbing from the depths creating continuous upward time pressure
## - Section A: The Awakening Pit (Staggered Hell Runes over rising abyss)
## - Section B: The Sinking Path (Switchback climbing leftward on collapsing obsidian platforms)
## - Section C: The Infernal Climb (Timed Infernal Energy Gates synchronized with Hell Runes)
## - Section D: The Last Ascent (High-pressure summit gauntlet with deceptive lower ambush and true high sanctum)
## - Exactly 10 distinct collectible coins required to unlock the Infernal Exit Gate at the summit

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D
@onready var rising_abyss: Node2D = $RisingAbyss

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var abyss_indicator_label: Label = get_node_or_null("HUD/MarginContainer/TopBar/AbyssIndicator")
@onready var pause_button: Button = $HUD/MarginContainer/TopBar/PauseBtn

# Touch Controls
@onready var touch_controls: Control = $HUD/TouchControls
@onready var touch_btn_left: TextureButton = $HUD/TouchControls/LeftBtn
@onready var touch_btn_right: TextureButton = $HUD/TouchControls/RightBtn
@onready var touch_btn_jump: TextureButton = $HUD/TouchControls/JumpBtn

# Overlays
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var death_overlay: Control = $HUD/DeathOverlay
@onready var level_complete_overlay: Control = $HUD/LevelCompleteOverlay

# Pit hazard area
@onready var pit_hazard_area: Area2D = get_node_or_null("PitHazardArea")

var _facility_elapsed: float = 0.0

func _ready() -> void:
	player.add_to_group("player")

	# Connect core game signals
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)

	pause_button.pressed.connect(_on_pause_pressed)
	death_overlay.retry_requested.connect(_on_retry)
	level_complete_overlay.replay_requested.connect(_on_retry)

	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(_on_player_revived)

	if pit_hazard_area:
		pit_hazard_area.body_entered.connect(_on_pit_entered)

	_setup_touch_controls()

	# Initial overlay states
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false

	# Setup HUD and stage intro card for World 4 Stage 18
	GameManager.setup_level_hud(self, 18)

	_reset_level()

func _process(delta: float) -> void:
	_facility_elapsed += delta
	# Update Abyss Threat indicator on HUD based on rising abyss progression
	if abyss_indicator_label and rising_abyss and rising_abyss.has_method("get_abyss_progress_percentage"):
		var pct: float = float(rising_abyss.get_abyss_progress_percentage())
		abyss_indicator_label.text = "ABYSS THREAT: %d%%" % int(pct)
		if pct >= 75.0:
			abyss_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.35, 1.0))
		elif pct >= 40.0:
			abyss_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2, 1.0))
		else:
			abyss_indicator_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4, 1.0))

func _setup_touch_controls() -> void:
	touch_btn_left.action_name = "move_left"
	touch_btn_right.action_name = "move_right"
	touch_btn_jump.action_name = "jump"

	touch_btn_left.touch_down.connect(func(): player.touch_left = true)
	touch_btn_left.touch_up.connect(func(): player.touch_left = false)

	touch_btn_right.touch_down.connect(func(): player.touch_right = true)
	touch_btn_right.touch_up.connect(func(): player.touch_right = false)

	touch_btn_jump.touch_down.connect(func():
		player.touch_jump = true
		player.touch_jump_just_pressed = true
	)
	touch_btn_jump.touch_up.connect(func():
		player.touch_jump = false
		player.touch_jump_just_released = true
	)

func _clear_touch_controls() -> void:
	if touch_btn_left and touch_btn_left.has_method("reset"):
		touch_btn_left.reset()
	if touch_btn_right and touch_btn_right.has_method("reset"):
		touch_btn_right.reset()
	if touch_btn_jump and touch_btn_jump.has_method("reset"):
		touch_btn_jump.reset()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed() -> void:
	_clear_touch_controls()
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("click")
	pause_overlay.open()

func _on_coin_collected(current: int, total: int) -> void:
	coin_counter_label.text = "COINS: %d / %d" % [current, total]

func _on_player_died() -> void:
	_clear_touch_controls()
	death_overlay.open()

func _on_level_completed(_level_id: int) -> void:
	_clear_touch_controls()
	player.disable_input()
	level_complete_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_pit_entered(body: Node2D) -> void:
	if body == player:
		player.die()

func _on_player_revived(_pos: Vector2) -> void:
	_clear_touch_controls()
	_facility_elapsed = 0.0
	death_overlay.visible = false
	pause_overlay.visible = false
	level_complete_overlay.visible = false
	GameManager.is_gameplay_active = true

func _on_retry() -> void:
	_reset_level()

func _reset_level() -> void:
	_clear_touch_controls()
	_facility_elapsed = 0.0
	death_overlay.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false
	GameManager.is_gameplay_active = true
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / %d" % GameManager.total_coins_required

	player.reset_to(spawn_point.global_position)
	exit_gate.reset()

	if rising_abyss and rising_abyss.has_method("reset"):
		rising_abyss.reset()

	# Reset all platforms
	var platforms = get_node_or_null("Platforms")
	if platforms:
		for p in platforms.get_children():
			if p.has_method("reset"):
				p.reset()

	# Reset all hazards, runes, and energy gates
	var hazards = get_node_or_null("Hazards")
	if hazards:
		for h in hazards.get_children():
			if h.has_method("reset"):
				h.reset()

	# Reset all coins
	var coins = get_node_or_null("Coins")
	if coins:
		for c in coins.get_children():
			if c.has_method("reset"):
				c.reset()
