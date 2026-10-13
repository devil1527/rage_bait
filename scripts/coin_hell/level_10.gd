extends Node2D

## Level 10: "Haunted Survival" — World 2: The Haunted Hall Boss Stage
## Fixed 960x540 arena with 5 connected platforms and 10 progressive 6-second rounds:
## 1. SPIKES, 2. PHANTOM, 3. CRUMBLING, 4. SURPRISE CHAINS, 5. COUNTDOWN.
## Features:
## - Dramatic Boss Stage Introduction ("SURVIVE FOR 1 MINUTE!")
## - 10 Six-Second Rounds totaling 60 seconds with continuous countdown
## - Dynamic Coin Spawning: Exactly one coin spawned at the start of each round (10 total)
## - Dynamic Anti-Camping Hazard Scheduler: Every round forces movement across platforms
## - Urgent 10-second alert and final 5-second countdown
## - Clean retry/pause/reset and dramatic World 2 Boss Victory sequence.

@export var survival_duration: float = 60.0

const ROUND_DURATION: float = 6.0
const TOTAL_ROUNDS: int = 10
const COIN_SCENE: PackedScene = preload("res://scenes/coin_hell/coin.tscn")

# 10 Reachable Coin Spawn Positions across the 5 platforms:
# Round 1: Platform 2 (mid-left)
# Round 2: Platform 3 (center high)
# Round 3: Platform 4 (mid-right)
# Round 4: Platform 5 (bottom-right)
# Round 5: Platform 3 (center apex)
# Round 6: Platform 1 (bottom-left)
# Round 7: Platform 2 (mid-left)
# Round 8: Platform 4 (mid-right)
# Round 9: Platform 5 (bottom-right)
# Round 10: Platform 3 (center apex stand)
const COIN_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(340, 260), # Round 1: Plat 2 (Player forced off P1 by spikes)
	Vector2(480, 170), # Round 2: Plat 3 (P2 phantom dissolves, jump up)
	Vector2(620, 260), # Round 3: Plat 4 (P3 crumbles, jump right)
	Vector2(760, 350), # Round 4: Plat 5 (P4 chains strike, drop right)
	Vector2(480, 160), # Round 5: Plat 3 (P5 countdown dissolves, leap center)
	Vector2(200, 350), # Round 6: Plat 1 (Right flank attacked, flee left)
	Vector2(340, 250), # Round 7: Plat 2 (P1 spikes fire, jump to P2)
	Vector2(620, 250), # Round 8: Plat 4 (P2 phantom dissolves, cross to P4)
	Vector2(760, 350), # Round 9: Plat 5 (P4 chains strike, drop to P5)
	Vector2(480, 160), # Round 10: Plat 3 (Bottom platforms lethal, apex stand)
]

var _survival_elapsed: float = 0.0
var _is_surviving: bool = false
var _is_victory: bool = false
var current_round: int = 1
var _executed_round_numbers: Dictionary = {}
var _coins_spawned_count: int = 0
var _scheduled_waves: Array[Dictionary] = []
var _executed_wave_indices: Dictionary = {}

# Node references
@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var camera: Camera2D = $Player/Camera2D

# 5 Arena Platforms
@onready var plat1_spikes: SurvivalArenaPlatform = $Platforms/Platform1_Spikes
@onready var plat2_phantom: SurvivalArenaPlatform = $Platforms/Platform2_Phantom
@onready var plat3_crumbling: SurvivalArenaPlatform = $Platforms/Platform3_Crumbling
@onready var plat4_chains: SurvivalArenaPlatform = $Platforms/Platform4_Chains
@onready var plat5_countdown: SurvivalArenaPlatform = $Platforms/Platform5_Countdown
@onready var surprise_chain: SurpriseGhostChain = $SurpriseGhostChain

# Fall Pit
@onready var pit_hazard_area: Area2D = $PitHazardArea

# Coins container
@onready var coins_container: Node2D = $Coins

# HUD
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_name_label: Label = $HUD/MarginContainer/TopBar/LevelName
@onready var survival_timer_label: Label = $HUD/MarginContainer/TopBar/TimerContainer/SurvivalTimer
@onready var round_indicator: Label = $HUD/MarginContainer/TopBar/TimerContainer/RoundIndicator
@onready var pause_button: Button = $HUD/MarginContainer/TopBar/PauseBtn
@onready var round_banner: Label = $HUD/RoundBanner
@onready var alert_banner: Label = $HUD/AlertBanner

# Mobile Controls
@onready var touch_controls: Control = $HUD/TouchControls
@onready var touch_btn_left: TextureButton = $HUD/TouchControls/LeftBtn
@onready var touch_btn_right: TextureButton = $HUD/TouchControls/RightBtn
@onready var touch_btn_jump: TextureButton = $HUD/TouchControls/JumpBtn

# Overlays
@onready var boss_intro_overlay: BossIntroOverlay = $HUD/BossIntroOverlay
@onready var boss_victory_overlay: BossVictoryOverlay = $HUD/BossVictoryOverlay
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var death_overlay: Control = $HUD/DeathOverlay

var _round_banner_tween: Tween = null
var _alert_banner_tween: Tween = null

func _ready() -> void:
	player.add_to_group("player")
	
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	
	pause_button.pressed.connect(_on_pause_pressed)
	death_overlay.retry_requested.connect(_on_retry)
	boss_victory_overlay.replay_requested.connect(_on_retry)
	boss_intro_overlay.intro_completed.connect(_on_intro_completed)
	
	if pit_hazard_area:
		pit_hazard_area.body_entered.connect(_on_pit_entered)
		
	# Link surprise ghost chain to Platform 4
	if plat4_chains:
		plat4_chains.linked_surprise_chain = surprise_chain
		
	_setup_touch_controls()
	_init_hazard_schedule()
	
	pause_overlay.visible = false
	death_overlay.visible = false
	boss_victory_overlay.visible = false
	alert_banner.visible = false
	if round_banner:
		round_banner.visible = false
	
	level_name_label.text = "WORLD 2 · BOSS: HAUNTED SURVIVAL"
	
	# Start with dramatic Boss Intro
	_start_intro_flow()

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

func _init_hazard_schedule() -> void:
	_scheduled_waves.clear()
	# Coordinated 10-Round Anti-Camping Schedule:
	# Each round lasts 6 seconds. Hazards actively rotate and force movement.
	
	# Round 1: 0.0 - 6.0s (Coin 1 @ P2)
	# Platform 1 (spikes) fires at 1.5s -> forces player off spawn!
	_scheduled_waves.append({"time": 1.5, "plats": [1], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 3.5, "plats": [4], "warn": 0.8, "act": 1.8})
	
	# Round 2: 6.0 - 12.0s (Coin 2 @ P3)
	# Platform 2 (phantom) dissolves at 6.8s -> forces player up to P3!
	_scheduled_waves.append({"time": 6.8, "plats": [2], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 8.5, "plats": [5], "warn": 0.9, "act": 1.8})
	
	# Round 3: 12.0 - 18.0s (Coin 3 @ P4)
	# Platform 3 (crumbling) drops at 12.8s -> forces player to P4!
	_scheduled_waves.append({"time": 12.8, "plats": [3], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 14.5, "plats": [1], "warn": 0.75, "act": 1.8})
	
	# Round 4: 18.0 - 24.0s (Coin 4 @ P5)
	# Platform 4 (chains) strike at 18.8s -> forces player down to P5!
	_scheduled_waves.append({"time": 18.8, "plats": [4], "warn": 0.75, "act": 1.8})
	_scheduled_waves.append({"time": 20.5, "plats": [2], "warn": 0.75, "act": 1.8})
	
	# Round 5: 24.0 - 30.0s (Coin 5 @ P3 Apex)
	# Platform 5 (countdown) dissolves at 24.8s -> forces player back up to P3/P4!
	_scheduled_waves.append({"time": 24.8, "plats": [5], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 26.5, "plats": [1], "warn": 0.75, "act": 1.8})
	
	# Round 6: 30.0 - 36.0s (Coin 6 @ P1)
	# Right flank attacked (P4 chains + P3 crumbling) -> forces player left to P1!
	_scheduled_waves.append({"time": 30.8, "plats": [3, 4], "warn": 0.75, "act": 1.8})
	_scheduled_waves.append({"time": 33.0, "plats": [5], "warn": 0.75, "act": 1.8})
	
	# Round 7: 36.0 - 42.0s (Coin 7 @ P2)
	# Platform 1 (spikes) fires at 36.8s -> forces player to P2!
	_scheduled_waves.append({"time": 36.8, "plats": [1], "warn": 0.7, "act": 1.8})
	_scheduled_waves.append({"time": 38.5, "plats": [4], "warn": 0.7, "act": 1.8})
	
	# Round 8: 42.0 - 48.0s (Coin 8 @ P4)
	# Left tier (P2 phantom + P3 crumbling + P1 spikes) -> forces cross to P4/P5!
	_scheduled_waves.append({"time": 42.8, "plats": [2], "warn": 0.7, "act": 1.8})
	_scheduled_waves.append({"time": 44.5, "plats": [3], "warn": 0.65, "act": 1.8})
	_scheduled_waves.append({"time": 45.5, "plats": [1], "warn": 0.65, "act": 1.8})
	
	# Round 9: 48.0 - 54.0s (Coin 9 @ P5)
	# Platform 4 chains + P2 phantom + P1 spikes -> forces jump to P5 (Coin 9) & P3!
	_scheduled_waves.append({"time": 48.8, "plats": [4], "warn": 0.65, "act": 1.8})
	_scheduled_waves.append({"time": 50.8, "plats": [2], "warn": 0.65, "act": 1.8})
	_scheduled_waves.append({"time": 51.8, "plats": [1], "warn": 0.65, "act": 1.8})
	
	# Round 10: 54.0 - 60.0s (Coin 10 @ P3 Final Stand)
	# Both bottom platforms (P1 spikes + P5 countdown) activate at 54.4s!
	# Forces player to center apex Platform 3 to grab Coin 10 and survive the final stand!
	_scheduled_waves.append({"time": 54.4, "plats": [1, 5], "warn": 0.6, "act": 1.8})
	_scheduled_waves.append({"time": 56.5, "plats": [4], "warn": 0.6, "act": 1.8})

func _start_intro_flow() -> void:
	_is_surviving = false
	_is_victory = false
	_survival_elapsed = 0.0
	current_round = 1
	_executed_round_numbers.clear()
	_update_timer_hud(survival_duration)
	_update_round_hud(1)
	
	if player:
		if spawn_point:
			player.reset_to(spawn_point.global_position)
		player.disable_input()
			
	_reset_all_hazards()
	
	# Clear any previous coins
	if coins_container:
		for coin in coins_container.get_children():
			coins_container.remove_child(coin)
			coin.queue_free()
			
	boss_intro_overlay.play_intro()

func _on_intro_completed() -> void:
	# Give player control and start survival timer together
	if player:
		player.revive()
	_start_survival_gameplay()

func _start_survival_gameplay() -> void:
	_is_surviving = true
	_is_victory = false
	_survival_elapsed = 0.0
	_executed_wave_indices.clear()
	_executed_round_numbers.clear()
	_coins_spawned_count = 0
	
	GameManager.current_level_id = 10
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	GameManager.is_gameplay_active = true
	coin_counter_label.text = "COINS: 0 / 10"
	
	# Clear any lingering coins
	if coins_container:
		for coin in coins_container.get_children():
			coins_container.remove_child(coin)
			coin.queue_free()
			
	# Start Round 1 immediately
	_advance_to_round(1)

func _physics_process(delta: float) -> void:
	if not _is_surviving or _is_victory:
		return
		
	_survival_elapsed += delta
	var remaining := maxf(0.0, survival_duration - _survival_elapsed)
	_update_timer_hud(remaining)
	
	# Process 6-second round progression (Rounds 1 to 10)
	var target_round: int = clampi(int(_survival_elapsed / ROUND_DURATION) + 1, 1, TOTAL_ROUNDS)
	while current_round < target_round:
		_advance_to_round(current_round + 1)
	
	# Process hazard scheduler
	_process_hazard_scheduler(_survival_elapsed)
	
	# Process dramatic countdown banners
	_process_countdown_alerts(_survival_elapsed, remaining)
	
	# Check 60-second survival completion
	if _survival_elapsed >= survival_duration and not _is_victory:
		_trigger_survival_victory()

func _advance_to_round(r: int) -> void:
	if r < 1 or r > TOTAL_ROUNDS:
		return
	if _executed_round_numbers.has(r):
		return
	_executed_round_numbers[r] = true
	current_round = r
	
	# Update HUD
	_update_round_hud(r)
	
	# Spawn round coin
	_spawn_coin_for_round(r)
	
	# Announce round transition
	_show_round_indicator(r)

func _spawn_coin_for_round(round_num: int) -> void:
	if round_num < 1 or round_num > TOTAL_ROUNDS:
		return
	var coin_name := "Coin%d" % round_num
	if coins_container.has_node(coin_name):
		return
		
	var coin_pos: Vector2 = COIN_SPAWN_POSITIONS[round_num - 1]
	var coin = COIN_SCENE.instantiate()
	coin.name = coin_name
	coin.position = coin_pos
	coins_container.add_child(coin)
	_coins_spawned_count += 1
	
	# Retro appearance scale-in animation
	coin.scale = Vector2.ZERO
	var tw := coin.create_tween()
	tw.tween_property(coin, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("coin")

func _update_round_hud(r: int) -> void:
	if round_indicator:
		round_indicator.text = "[R%d/10]" % r
		if r >= 9:
			round_indicator.modulate = Color(1.0, 0.35, 0.35)
		elif r >= 6:
			round_indicator.modulate = Color(1.0, 0.75, 0.2)
		else:
			round_indicator.modulate = Color(0.85, 0.9, 1.0)

func _show_round_indicator(r: int) -> void:
	if not round_banner:
		return
	if _round_banner_tween:
		_round_banner_tween.kill()
		
	if r == 10:
		round_banner.text = "ROUND 10 / 10 · FINAL ROUND! SURVIVE!"
		round_banner.modulate = Color(1.0, 0.3, 0.35, 1.0)
	elif r >= 8:
		round_banner.text = "ROUND %d / 10" % r
		round_banner.modulate = Color(1.0, 0.7, 0.2, 1.0)
	else:
		round_banner.text = "ROUND %d / 10" % r
		round_banner.modulate = Color(0.9, 0.95, 1.0, 1.0)
		
	round_banner.visible = true
	round_banner.scale = Vector2(1.15, 1.15)
	_round_banner_tween = create_tween()
	_round_banner_tween.tween_property(round_banner, "scale", Vector2.ONE, 0.15)
	_round_banner_tween.tween_interval(1.1)
	_round_banner_tween.tween_property(round_banner, "modulate:a", 0.0, 0.35)
	_round_banner_tween.tween_callback(func():
		round_banner.visible = false
		round_banner.modulate.a = 1.0
	)

func _update_timer_hud(seconds_left: float) -> void:
	var sec := ceili(seconds_left)
	survival_timer_label.text = "SURVIVE: %ds" % sec
	if seconds_left <= 5.0:
		survival_timer_label.modulate = Color(1.0, 0.2, 0.3)
	elif seconds_left <= 10.0:
		survival_timer_label.modulate = Color(1.0, 0.7, 0.2)
	else:
		survival_timer_label.modulate = Color(1.0, 0.85, 0.2)

func _process_hazard_scheduler(elapsed: float) -> void:
	for idx in range(_scheduled_waves.size()):
		if _executed_wave_indices.has(idx):
			continue
		var wave: Dictionary = _scheduled_waves[idx]
		if elapsed >= wave["time"]:
			_executed_wave_indices[idx] = true
			var plat_ids: Array = wave["plats"]
			var warn_t: float = wave["warn"]
			var act_t: float = wave["act"]
			for pid in plat_ids:
				_trigger_platform_by_id(pid, warn_t, act_t)

func _trigger_platform_by_id(pid: int, warn: float, act: float) -> void:
	match pid:
		1: if plat1_spikes: plat1_spikes.trigger_hazard(warn, act)
		2: if plat2_phantom: plat2_phantom.trigger_hazard(warn, act)
		3: if plat3_crumbling: plat3_crumbling.trigger_hazard(warn, act)
		4: if plat4_chains: plat4_chains.trigger_hazard(warn, act)
		5: if plat5_countdown: plat5_countdown.trigger_hazard(warn, act)

var _shown_10s_alert: bool = false
var _last_5s_announced: int = -1

func _process_countdown_alerts(elapsed: float, remaining: float) -> void:
	# 50s elapsed / 10s remaining alert
	if elapsed >= 50.0 and not _shown_10s_alert:
		_shown_10s_alert = true
		_show_alert("10 SECONDS LEFT!\nDON'T DIE NOW!", Color(1.0, 0.7, 0.2), 2.0)
		
	# Final 5s countdown
	if remaining <= 5.0 and remaining > 0.0:
		var sec := ceili(remaining)
		if sec != _last_5s_announced:
			_last_5s_announced = sec
			if sec == 5:
				_show_alert("FINAL 5 SECONDS!", Color(1.0, 0.25, 0.35), 0.9)
			else:
				_show_alert(str(sec), Color(1.0, 0.2, 0.3), 0.85)

func _show_alert(msg: String, col: Color, dur: float) -> void:
	alert_banner.text = msg
	alert_banner.modulate = col
	alert_banner.visible = true
	if _alert_banner_tween:
		_alert_banner_tween.kill()
	_alert_banner_tween = create_tween()
	_alert_banner_tween.tween_property(alert_banner, "scale", Vector2(1.15, 1.15), 0.15)
	_alert_banner_tween.tween_property(alert_banner, "scale", Vector2.ONE, 0.15)
	_alert_banner_tween.tween_interval(dur - 0.3)
	_alert_banner_tween.tween_callback(func():
		if remaining_time_is_past():
			alert_banner.visible = false
	)

func remaining_time_is_past() -> bool:
	return _survival_elapsed >= survival_duration or not _is_surviving

func _trigger_survival_victory() -> void:
	_is_victory = true
	_is_surviving = false
	alert_banner.visible = false
	if round_banner:
		round_banner.visible = false
	
	# Stop and safely deactivate all hazards
	_reset_all_hazards()
	
	# Trigger official completion flow
	GameManager.trigger_level_complete()
	_clear_touch_controls()
	
	# Present dramatic victory overlay
	boss_victory_overlay.open(GameManager.current_coins, GameManager.total_coins_required)

func _on_coin_collected(current: int, total: int) -> void:
	coin_counter_label.text = "COINS: %d / %d" % [current, total]

func _on_player_died() -> void:
	_is_surviving = false
	_clear_touch_controls()
	alert_banner.visible = false
	if round_banner:
		round_banner.visible = false
	_reset_all_hazards()
	death_overlay.open()

func _on_pit_entered(body: Node2D) -> void:
	if body == player or body.is_in_group("player"):
		player.die()

func _on_retry() -> void:
	_reset_level()

func _reset_level() -> void:
	_clear_touch_controls()
	pause_overlay.visible = false
	death_overlay.visible = false
	boss_victory_overlay.visible = false
	alert_banner.visible = false
	if round_banner:
		round_banner.visible = false
	
	_shown_10s_alert = false
	_last_5s_announced = -1
	_survival_elapsed = 0.0
	_is_victory = false
	_is_surviving = true
	_executed_wave_indices.clear()
	_executed_round_numbers.clear()
	_coins_spawned_count = 0
	
	_update_timer_hud(survival_duration)
	
	GameManager.current_level_id = 10
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / 10"
	
	# Spawn player and restore control immediately
	if player and spawn_point:
		player.reset_to(spawn_point.global_position)
		player.revive()
		
	# Clear all spawned coins
	if coins_container:
		for coin in coins_container.get_children():
			coins_container.remove_child(coin)
			coin.queue_free()
			
	# Start Round 1
	_advance_to_round(1)
	
	_reset_all_hazards()
	GameManager.coins_reset.emit()
	GameManager.is_gameplay_active = true

func _reset_all_hazards() -> void:
	if plat1_spikes: plat1_spikes.reset_hazard()
	if plat2_phantom: plat2_phantom.reset_hazard()
	if plat3_crumbling: plat3_crumbling.reset_hazard()
	if plat4_chains: plat4_chains.reset_hazard()
	if plat5_countdown: plat5_countdown.reset_hazard()
	if surprise_chain: surprise_chain.reset()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed() -> void:
	if boss_intro_overlay.is_playing:
		return
	_clear_touch_controls()
	AudioManager.play_sfx("click")
	pause_overlay.open()
