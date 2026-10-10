extends Node2D

## Level 1 logic controller.
## Manages HUD updates, player spawn/death/retry, pause, and exit completion flow.

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
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

# Fall pit detection
@onready var pit_hazard_area: Area2D = $PitHazardArea

func _ready() -> void:
	# Register player in group
	player.add_to_group("player")
	
	# Connect signals
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)
	
	pause_button.pressed.connect(_on_pause_pressed)
	death_overlay.retry_requested.connect(_on_retry)
	level_complete_overlay.replay_requested.connect(_on_retry)
	pit_hazard_area.body_entered.connect(_on_pit_entered)
	
	_setup_touch_controls()
	
	# Initial states
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false
	
	_reset_level()

func _setup_touch_controls() -> void:
	touch_btn_left.button_down.connect(func(): player.touch_left = true)
	touch_btn_left.button_up.connect(func(): player.touch_left = false)
	
	touch_btn_right.button_down.connect(func(): player.touch_right = true)
	touch_btn_right.button_up.connect(func(): player.touch_right = false)
	
	touch_btn_jump.button_down.connect(func():
		player.touch_jump = true
		player.touch_jump_just_pressed = true
	)
	touch_btn_jump.button_up.connect(func(): player.touch_jump = false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.open()

func _on_coin_collected(current: int, total: int) -> void:
	coin_counter_label.text = "COINS: %d / %d" % [current, total]

func _on_player_died() -> void:
	death_overlay.open()

func _on_level_completed(level_id: int) -> void:
	player.disable_input()
	level_complete_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_pit_entered(body: Node2D) -> void:
	if body == player:
		player.die()

func _on_retry() -> void:
	_reset_level()

func _reset_level() -> void:
	death_overlay.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / %d" % GameManager.total_coins_required
	player.reset_to(spawn_point.global_position)
	exit_gate.reset()
