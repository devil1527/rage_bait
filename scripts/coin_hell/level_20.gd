extends Node2D

## Level 20: "The Final Betrayal" — World 4: Final Hell Boss Stage
## The ultimate climactic trial of RETRO RAGE ARCADE:
## - Survival Boss encounter against THE COIN DRAGON in an infernal multi-tier platform arena.
## - Survive 60 seconds against the hunting dragon.
## - Collect all 10 coins released at 6-second intervals during the fight.
## - Dragon contact triggers immediate player death.
## - After 60s AND collecting 10/10 coins, the Infernal Exit Gate unlocks at the central altar.
## - Entering the gate defeats the Coin Dragon and completes World 4 with full 3-star victory!

const TOTAL_COINS: int = 10
const SURVIVAL_DURATION: float = 60.0

# 10 reachable platform target positions for released coins
const COIN_TARGET_POSITIONS: Array[Vector2] = [
	Vector2(190.0, 360.0), # Coin 1 (T=6s) -> LeftStep
	Vector2(420.0, 415.0), # Coin 2 (T=12s) -> CenterBridge Left
	Vector2(320.0, 235.0), # Coin 3 (T=18s) -> MidLeftPerch
	Vector2(770.0, 360.0), # Coin 4 (T=24s) -> RightStep
	Vector2(540.0, 415.0), # Coin 5 (T=30s) -> CenterBridge Right
	Vector2(130.0, 285.0), # Coin 6 (T=36s) -> LeftMid
	Vector2(830.0, 285.0), # Coin 7 (T=42s) -> RightMid
	Vector2(640.0, 235.0), # Coin 8 (T=48s) -> MidRightPerch
	Vector2(480.0, 415.0), # Coin 9 (T=54s) -> CenterBridge Center
	Vector2(480.0, 170.0)  # Coin 10 (T=60s) -> CentralAltar Sanctuary
]

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var dragon = $CoinDragon
@onready var exit_gate: Area2D = $ExitGate
@onready var coins_container: Node2D = $Coins
@onready var platforms_container: Node2D = $Platforms
@onready var pit_hazard_area: Area2D = get_node_or_null("PitHazardArea")

# HUD
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_title_label: Label = $HUD/MarginContainer/TopBar/LevelTitle
@onready var timer_label: Label = $HUD/MarginContainer/TopBar/TimerLabel
@onready var boss_status_label: Label = $HUD/BossStatusLabel
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

var _survival_elapsed: float = 0.0
var _is_encounter_active: bool = false
var _is_survived: bool = false
var _is_completed: bool = false
var _executed_cycles: Dictionary = {}
var _released_coins_map: Dictionary = {}

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

	if dragon:
		dragon.coin_released.connect(_on_dragon_coin_released)

	if exit_gate and exit_gate.has_signal("level_completed"):
		exit_gate.level_completed.connect(_on_exit_gate_entered)

	_setup_touch_controls()

	pause_overlay.visible = false
	death_overlay.visible = false
	level_complete_overlay.visible = false

	# Setup HUD and stage intro card for World 4 Stage 20
	GameManager.setup_level_hud(self, 20)

	_register_safe_anchors()
	_reset_level()
	_start_encounter()

func _register_safe_anchors() -> void:
	GameManager.safe_anchors.clear()
	GameManager.safe_anchors.append(spawn_point.global_position)
	GameManager.safe_anchors.append(Vector2(480.0, 410.0)) # CenterBridge
	GameManager.safe_anchors.append(Vector2(820.0, 430.0)) # RightGround
	GameManager.safe_anchors.append(Vector2(480.0, 165.0)) # CentralAltar

func _start_encounter() -> void:
	_is_encounter_active = true
	_is_survived = false
	_is_completed = false
	_survival_elapsed = 0.0
	_executed_cycles.clear()
	_update_timer_hud(SURVIVAL_DURATION)

	if boss_status_label:
		boss_status_label.text = "SURVIVE THE COIN DRAGON! (60s)"
		boss_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))

	if dragon:
		dragon.activate(player)

func _process(delta: float) -> void:
	if not _is_encounter_active or _is_completed:
		return

	_survival_elapsed += delta
	var time_remaining: float = maxf(0.0, SURVIVAL_DURATION - _survival_elapsed)
	_update_timer_hud(time_remaining)

	# 6-Second Coin Release Cycle (10 coins at T = 6, 12, 18, 24, 30, 36, 42, 48, 54, 60)
	for i in range(1, TOTAL_COINS + 1):
		var target_time: float = float(i) * 6.0
		if _survival_elapsed >= target_time and not _executed_cycles.has(i):
			_executed_cycles[i] = true
			_trigger_coin_release_cycle(i)

	# Check 60-second survival completion
	if _survival_elapsed >= SURVIVAL_DURATION and not _is_survived:
		_is_survived = true
		_check_gate_unlock_conditions()

func _update_timer_hud(remaining: float) -> void:
	if timer_label:
		var secs: int = int(ceilf(remaining))
		timer_label.text = "SURVIVE: %02ds" % secs
		if secs <= 10:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		elif secs <= 30:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1.0))
		else:
			timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))

func _trigger_coin_release_cycle(coin_idx: int) -> void:
	if coin_idx < 1 or coin_idx > TOTAL_COINS:
		return
	var target_land_pos: Vector2 = COIN_TARGET_POSITIONS[coin_idx - 1]
	var coin_node = coins_container.get_node_or_null("Coin%d" % coin_idx)
	if coin_node:
		coin_node.visible = true
	if dragon:
		dragon.trigger_coin_release(coin_idx, target_land_pos)
	else:
		_on_dragon_coin_released(Vector2(480.0, 200.0), coin_idx)

func _on_dragon_coin_released(snout_pos: Vector2, coin_idx: int) -> void:
	if coin_idx < 1 or coin_idx > TOTAL_COINS:
		return
	var coin_node = coins_container.get_node_or_null("Coin%d" % coin_idx)
	if not coin_node:
		return

	_released_coins_map[coin_idx] = true
	coin_node.visible = true
	coin_node.global_position = snout_pos

	var target_pos: Vector2 = COIN_TARGET_POSITIONS[coin_idx - 1]
	var col_shape = coin_node.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.set_deferred("disabled", true)

	# Smooth parabolic arc launch to target platform
	var apex_y: float = minf(snout_pos.y, target_pos.y) - 35.0
	var tween_x := create_tween()
	tween_x.tween_property(coin_node, "global_position:x", target_pos.x, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var tween_y := create_tween()
	tween_y.tween_property(coin_node, "global_position:y", apex_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(coin_node, "global_position:y", target_pos.y, 0.27).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_y.tween_callback(func():
		if col_shape and is_instance_valid(col_shape):
			col_shape.set_deferred("disabled", false)
	)

func _check_gate_unlock_conditions() -> void:
	if not _is_survived:
		return

	if GameManager.current_coins >= TOTAL_COINS:
		if exit_gate and not exit_gate._is_open:
			exit_gate.unlock_gate()
			if boss_status_label:
				boss_status_label.text = "EXIT OPEN! ENTER GATE TO DEFEAT DRAGON!"
				boss_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
	else:
		var remaining: int = TOTAL_COINS - GameManager.current_coins
		if boss_status_label:
			boss_status_label.text = "TIME EXPIRED! COLLECT %d REMAINING COIN%s!" % [remaining, "" if remaining == 1 else "S"]
			boss_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))

func _on_coin_collected(current: int, total: int) -> void:
	coin_counter_label.text = "COINS: %d / %d" % [current, total]
	_check_gate_unlock_conditions()

func _on_exit_gate_entered() -> void:
	if _is_completed:
		return
	_is_completed = true
	_is_encounter_active = false
	_clear_touch_controls()

	if player:
		player.disable_input()

	if dragon:
		dragon.defeat()

	if boss_status_label:
		boss_status_label.text = "THE COIN DRAGON HAS BEEN SLAIN!"
		boss_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))

	# Complete level through GameManager
	GameManager.trigger_level_complete()

func _on_level_completed(_level_id: int) -> void:
	_clear_touch_controls()
	if player:
		player.disable_input()
	level_complete_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_player_died() -> void:
	_is_encounter_active = false
	_clear_touch_controls()
	if dragon:
		dragon.deactivate()
	death_overlay.open()

func _on_pit_entered(body: Node2D) -> void:
	if body == player:
		player.die()

func _on_player_revived(_pos: Vector2) -> void:
	_clear_touch_controls()
	death_overlay.visible = false
	pause_overlay.visible = false
	level_complete_overlay.visible = false
	GameManager.is_gameplay_active = true
	_is_encounter_active = true
	if dragon:
		dragon.activate(player)

func _on_retry() -> void:
	_reset_level()
	_start_encounter()

func _reset_level() -> void:
	_clear_touch_controls()
	_survival_elapsed = 0.0
	_is_encounter_active = false
	_is_survived = false
	_is_completed = false
	_executed_cycles.clear()
	_released_coins_map.clear()

	death_overlay.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false

	GameManager.is_gameplay_active = true
	GameManager.current_level_id = 20
	GameManager.total_coins_required = TOTAL_COINS
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / %d" % TOTAL_COINS

	player.reset_to(spawn_point.global_position)

	if exit_gate:
		exit_gate.reset()

	if dragon:
		dragon.reset_to(Vector2(780.0, 420.0))

	# Hide all coins until released by dragon
	if coins_container:
		for i in range(1, TOTAL_COINS + 1):
			var c = coins_container.get_node_or_null("Coin%d" % i)
			if c:
				c.reset()
				c.visible = false
				var col_shape = c.get_node_or_null("CollisionShape2D")
				if col_shape:
					col_shape.set_deferred("disabled", true)
				c.global_position = COIN_TARGET_POSITIONS[i - 1]

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
