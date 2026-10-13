extends Node2D

## Level 7 ("Hall of Illusions" - World 2: The Haunted Hall) logic controller.
## Manages HUD updates, world/stage transition card, player spawn/death/retry,
## touch controls, and exit flows.
## Features Moving Phantom Bars, Falling Crushers, and Spikes across 5 distinct sections with exactly 10 coins.

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var exit_gate: Area2D = $ExitGate
@onready var camera: Camera2D = $Player/Camera2D

# HUD nodes
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_name_label: Label = $HUD/MarginContainer/TopBar/LevelName
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
	
	# Update HUD world/stage label
	level_name_label.text = "WORLD 2 · STAGE 7: HALL OF ILLUSIONS"
	
	# Present brief transition card if first entry in this gameplay session
	GameManager.present_stage_intro(self, 7)
	
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
	AudioManager.play_sfx("death")
	death_overlay.open()

func _on_pit_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if player.has_method("die"):
			player.die()
		else:
			GameManager.player_died.emit()

func _on_level_completed(completed_id: int) -> void:
	if completed_id == 7:
		_clear_touch_controls()
		AudioManager.play_sfx("win")
		level_complete_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_retry() -> void:
	_clear_touch_controls()
	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false
	_reset_level()

func _reset_level() -> void:
	_clear_touch_controls()
	GameManager.current_level_id = 7
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	
	coin_counter_label.text = "COINS: 0 / 10"
	
	# Spawn player safely
	if player:
		player.position = spawn_point.position
		player.velocity = Vector2.ZERO
		if player.has_method("revive"):
			player.revive()
			
	# Reset all coins in level
	var coins_container := get_node_or_null("Coins")
	if coins_container:
		for coin in coins_container.get_children():
			if coin.has_method("reset"):
				coin.reset()
				
	# Reset Exit Gate
	if exit_gate and exit_gate.has_method("reset"):
		exit_gate.reset()
		
	# Broadcast coins_reset to all traps, crushers, and phantom platforms
	GameManager.coins_reset.emit()
	GameManager.is_gameplay_active = true
