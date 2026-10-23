extends Node2D

## Level 19: "The Soul Gauntlet" — World 4: Final Hell Stage 4
## The ultimate chained precision gauntlet of World 4:
## Substantially harder than Level 18's rising abyss:
## - Chained precision landing constraints: Landing position and momentum dictate next jump
## - Hazardous co-location: Collapsing obsidian platforms paired with rapid Hell Runes and timed energy gates
## - Section A: The Toll of Souls (Ascending precision gauntlet with staggered Hell Runes)
## - Section B: The Broken Covenant (Dual collapsing ledges and micro-window Hell Runes)
## - Section C: The Execution Chamber (Triple phased Infernal Energy Gates over narrow perches)
## - Section D: The Soul Collector (The Deceptive Traitor's Altar vs True Upper Ascension)
## - Exactly 10 distinct collectible coins required to unlock the Infernal Exit Gate

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var gauntlet_indicator_label: Label = get_node_or_null("HUD/MarginContainer/TopBar/GauntletIndicator")
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

	# Setup HUD and stage intro card for World 4 Stage 19
	GameManager.setup_level_hud(self, 19)

	# Register verified safe anchors for revive system
	_register_safe_anchors()

	_reset_level()

func _register_safe_anchors() -> void:
	GameManager.safe_anchors.clear()
	# Spawn anchor
	GameManager.safe_anchors.append(spawn_point.global_position)
	# Platform 4 (Section B gateway)
	GameManager.safe_anchors.append(Vector2(610.0, 195.0))
	# Platform 6 (Section C gateway)
	GameManager.safe_anchors.append(Vector2(1220.0, 30.0))
	# Platform 9 (Section D gateway)
	GameManager.safe_anchors.append(Vector2(1735.0, -95.0))

func _process(delta: float) -> void:
	_facility_elapsed += delta
	# Update Soul Gauntlet progress indicator on HUD based on player horizontal progression
	if gauntlet_indicator_label and player:
		var start_x: float = 80.0
		var finish_x: float = 2320.0
		var current_x: float = player.global_position.x
		var pct: float = clampf(((current_x - start_x) / (finish_x - start_x)) * 100.0, 0.0, 100.0)
		gauntlet_indicator_label.text = "GAUNTLET: %d%%" % int(pct)
		if pct >= 80.0:
			gauntlet_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
		elif pct >= 45.0:
			gauntlet_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
		else:
			gauntlet_indicator_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.45, 1.0))

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
