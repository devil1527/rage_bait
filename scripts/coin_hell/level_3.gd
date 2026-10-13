extends Node2D

## Level 3 ("Fire & Fury" - Neon Ruins) logic controller.
## Manages HUD updates, player spawn/death/retry, pause, touch controls, and exit flows.
## Signature mechanic: Inferno Gate (vertical proximity-activated fire barrier).

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
	player.add_to_group("player")
	
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)
	
	pause_button.pressed.connect(_on_pause_pressed)
	death_overlay.retry_requested.connect(_on_retry)
	level_complete_overlay.replay_requested.connect(_on_retry)
	if pit_hazard_area:
		pit_hazard_area.body_entered.connect(_on_pit_entered)
	
	_setup_touch_controls()
	
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false
	
	GameManager.setup_level_hud(self, 3)
	
	_reset_level()

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
	
	if exit_gate and exit_gate.has_method("reset"):
		exit_gate.reset()
		
	var platforms = get_node_or_null("Platforms")
	if platforms:
		for p in platforms.get_children():
			if p.has_method("reset"):
				p.reset()
				
	var traps = get_node_or_null("Traps")
	if traps:
		for t in traps.get_children():
			if t.has_method("reset"):
				t.reset()
				
	var hazards = get_node_or_null("Hazards")
	if hazards:
		for h in hazards.get_children():
			if h.has_method("reset"):
				h.reset()
