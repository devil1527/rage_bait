extends Node2D

## Level 16: "The Platform That Lied" — World 4: Final Hell Stage 1
## The premiere infernal platforming gauntlet featuring 5 escalating sections:
## - Section A: The Ashen Approach (Obsidian ruins, Hell Rune introduced in isolation)
## - Section B: The Burning Passage (Vanishing platforms paired with Hell Runes, safe recovery)
## - Section C: The Infernal Gate (Infernal Energy Gates laser barriers and precision timing)
## - Section D: The False Finish (Demonic approach to deceptive summit gap, environmental hints)
## - Section E: The Platform That Lied (Signature secret reveal mechanism and two-jump finale)
## - Exactly 10 collectible coins and locked infernal exit gate
## - Full persistent secret reveal across retries and resets

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D

# Secret Hidden Platform for Section E
@onready var secret_platform: AnimatableBody2D = get_node_or_null("Platforms/SecretHellPlatform")
@onready var final_gap_area: Area2D = get_node_or_null("FinalGapTriggerArea")

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var inferno_indicator_label: Label = get_node_or_null("HUD/MarginContainer/TopBar/InfernoIndicator")
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
var _reached_takeoff: bool = false
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

	if final_gap_area:
		final_gap_area.body_entered.connect(_on_final_gap_area_entered)

	_setup_touch_controls()

	# Initial overlay states
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false

	# Setup HUD and stage intro card for World 4 Stage 16
	GameManager.setup_level_hud(self, 16)

	# Initialize secret platform state
	_check_secret_platform_state()

	_reset_level()

func _check_secret_platform_state() -> void:
	if secret_platform:
		secret_platform.reset()

func _process(delta: float) -> void:
	_facility_elapsed += delta
	# Update Inferno Core Depth indicator on HUD based on player horizontal progression
	if inferno_indicator_label and player:
		var progress: float = clampf(player.global_position.x / 2650.0, 0.0, 1.0)
		var depth: int = 666 + int(progress * 333.0)
		inferno_indicator_label.text = "HELL DEPTH: %dM" % depth
		if progress >= 0.8:
			inferno_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.35, 1.0))
		elif progress >= 0.4:
			inferno_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2, 1.0))
		else:
			inferno_indicator_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4, 1.0))

	# Track takeoff arrival and final jump attempt into the exit chasm
	if player:
		var p_pos := player.global_position
		# Player reaches TakeoffPlatform (x: 2170 to 2260, y <= 270)
		if not _reached_takeoff and p_pos.x >= 2170.0 and p_pos.x <= 2260.0 and p_pos.y <= 270.0:
			_reached_takeoff = true
		# Player launches rightward into the final gap from takeoff (x > 2250)
		if _reached_takeoff and not _attempted_final_jump and p_pos.x > 2250.0:
			_attempted_final_jump = true

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
	# Check if death occurred during a genuine final gap leap or in the final chasm abyss
	if (player and player.global_position.x > 2250.0 and player.global_position.y >= 270.0) or (_attempted_final_jump and player and player.global_position.y >= 270.0):
		_trigger_final_jump_reveal()

	death_overlay.open()

func _on_final_gap_area_entered(body: Node2D) -> void:
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
	_reached_takeoff = false
	_attempted_final_jump = false
	death_overlay.visible = false
	pause_overlay.visible = false
	level_complete_overlay.visible = false
	GameManager.is_gameplay_active = true

func _on_retry() -> void:
	_reset_level()

func _reset_level() -> void:
	_clear_touch_controls()
	_facility_elapsed = 0.0
	_reached_takeoff = false
	_attempted_final_jump = false
	death_overlay.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false
	GameManager.is_gameplay_active = true
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / %d" % GameManager.total_coins_required

	player.reset_to(spawn_point.global_position)
	exit_gate.reset()

	_check_secret_platform_state()

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
