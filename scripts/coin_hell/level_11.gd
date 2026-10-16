extends Node2D

## Level 11: "Meltdown" — World 3: Rage Factory Stage 1
## Industrial ascending escape level featuring:
## - 7 Connected Sections from furnace entrance to emergency exit
## - Rising molten lava controller with deterministic rise and warning phases
## - Direction-reversing conveyor belts with visible LED warning beacons
## - Industrial pneumatic ceiling crusher with lethal slam and safe passing window
## - Risky greed coin detour (Coins 8 & 9)
## - Exactly 10 collectible coins
## - Clean full reset on death and retry

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D
@onready var rising_lava: Node2D = $RisingLava

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var lava_indicator_label: Label = get_node_or_null("HUD/MarginContainer/TopBar/LavaIndicator")
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

# Fall pit safety detection
@onready var pit_hazard_area: Area2D = get_node_or_null("PitHazardArea")

func _ready() -> void:
	player.add_to_group("player")

	# Connect core game signals
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)

	pause_button.pressed.connect(_on_pause_pressed)
	death_overlay.retry_requested.connect(_on_retry)
	level_complete_overlay.replay_requested.connect(_on_retry)

	if pit_hazard_area:
		pit_hazard_area.body_entered.connect(_on_pit_entered)

	_setup_touch_controls()

	# Initial overlay states
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false

	# Setup HUD and stage intro card for World 3 Stage 11
	GameManager.setup_level_hud(self, 11)

	_reset_level()

func _process(_delta: float) -> void:
	# Update lava pressure HUD indicator
	if lava_indicator_label and rising_lava and rising_lava.has_method("get_lava_progress_percentage"):
		var pct: float = float(rising_lava.get_lava_progress_percentage())
		lava_indicator_label.text = "LAVA: %d%%" % int(pct)
		if pct >= 75.0:
			lava_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1.0))
		elif pct >= 40.0:
			lava_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1, 1.0))
		else:
			lava_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))

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
	AudioManager.play_sfx("click")
	pause_overlay.open()

func _on_coin_collected(current: int, total: int) -> void:
	coin_counter_label.text = "COINS: %d / %d" % [current, total]

func _on_player_died() -> void:
	_clear_touch_controls()
	death_overlay.open()

func _on_level_completed(level_id: int) -> void:
	_clear_touch_controls()
	player.disable_input()
	level_complete_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_pit_entered(body: Node2D) -> void:
	if body == player:
		player.die()

func _on_retry() -> void:
	_reset_level()

func _reset_level() -> void:
	_clear_touch_controls()
	death_overlay.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false
	GameManager.is_gameplay_active = true
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / %d" % GameManager.total_coins_required

	player.reset_to(spawn_point.global_position)
	exit_gate.reset()

	if rising_lava:
		rising_lava.reset()

	# Reset all platforms, conveyors, and crushers
	var platforms = get_node_or_null("Platforms")
	if platforms:
		for p in platforms.get_children():
			if p.has_method("reset"):
				p.reset()

	var hazards = get_node_or_null("Hazards")
	if hazards:
		for h in hazards.get_children():
			if h.has_method("reset"):
				h.reset()
