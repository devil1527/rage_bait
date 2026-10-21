extends Node2D

## Level 15: "Rage Furnace" — World 3: Rage Factory Stage 5 (Finale)
## The ultimate World 3 platforming gauntlet featuring 5 escalating phases:
## - Phase A: The Gauntlet (Precision ledges, spikes, falling and vanishing bars)
## - Phase B: The Boulder Run (Demanding rolling slag boulder sequence with jump hurdles)
## - Phase C: The Vanishing Hall (Alternating phantom bars, industrial crushers, steam vents)
## - Phase D: The Final Furnace Ascent (Elevator piston, counter-conveyor, rapid falling ledges)
## - Phase E: The Impossible Final Jump (Signature secret reveal mechanism)
## - Exactly 10 collectible coins and locked summit exit gate
## - Full persistent secret reveal across retries and resets

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D

# Secret Hidden Platform for Phase E
@onready var secret_platform: AnimatableBody2D = get_node_or_null("Platforms/SecretHiddenPlatform")
@onready var final_gap_fall_area: Area2D = get_node_or_null("FinalGapFallArea")

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var furnace_indicator_label: Label = get_node_or_null("HUD/MarginContainer/TopBar/FurnaceIndicator")
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

var _facility_elapsed: float = 0.0
var _attempted_final_jump: bool = false

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

	if final_gap_fall_area:
		final_gap_fall_area.body_entered.connect(_on_final_gap_fall_area_entered)

	_setup_touch_controls()

	# Initial overlay states
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false

	# Setup HUD and stage intro card for World 3 Stage 15
	GameManager.setup_level_hud(self, 15)

	# Initialize secret platform state
	_check_secret_platform_state()

	_reset_level()

func _check_secret_platform_state() -> void:
	if secret_platform:
		if SaveManager and SaveManager.has_method("is_level_15_secret_revealed") and SaveManager.is_level_15_secret_revealed():
			secret_platform.set_revealed_instant(true)
		else:
			secret_platform.set_revealed_instant(false)

func _process(delta: float) -> void:
	_facility_elapsed += delta
	# Update Furnace Core Temperature based on player vertical altitude
	if furnace_indicator_label and player:
		var alt: float = clampf((400.0 - player.global_position.y) / 10.0, 0.0, 140.0)
		var temp: int = 800 + int(alt * 10.5)
		furnace_indicator_label.text = "CORE TEMP: %d°C" % temp
		if temp >= 1800:
			furnace_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15, 1.0))
		elif temp >= 1300:
			furnace_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15, 1.0))
		else:
			furnace_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))

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
	# Check if death occurred during a genuine final gap leap
	if player:
		var p_pos := player.global_position
		# Final gap is bounded horizontally by 350 to 580 and vertically at the summit (y < -650)
		if p_pos.x >= 350.0 and p_pos.x <= 580.0 and p_pos.y <= -650.0:
			_trigger_final_jump_reveal()

	death_overlay.open()

func _on_final_gap_fall_area_entered(body: Node2D) -> void:
	if body == player or (body and body.is_in_group("player")):
		_trigger_final_jump_reveal()

func _trigger_final_jump_reveal() -> void:
	if secret_platform and not secret_platform.is_revealed:
		secret_platform.reveal()

func _on_level_completed(level_id: int) -> void:
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
	_check_secret_platform_state()

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

	_check_secret_platform_state()

	# Reset all platforms, conveyors, boulders, and moving platforms
	var platforms = get_node_or_null("Platforms")
	if platforms:
		for p in platforms.get_children():
			if p.has_method("reset"):
				p.reset()

	# Reset all hazards, crushers, steam vents, and boulders
	var hazards = get_node_or_null("Hazards")
	if hazards:
		for h in hazards.get_children():
			if h.has_method("reset"):
				h.reset()
