extends Node2D

## Level 10: "Haunted Survival" — World 2: The Haunted Hall Boss Stage
## Fixed 960x540 arena with 5 connected platforms, each with a signature hazard:
## 1. SPIKES, 2. PHANTOM, 3. CRUMBLING, 4. SURPRISE CHAINS, 5. COUNTDOWN.
## Features:
## - Dramatic Boss Stage Introduction ("SURVIVE FOR 1 MINUTE!")
## - 60-Second Survival Objective with 5-phase progressive hazard scheduling
## - Urgent 10-second alert and final 5-second countdown
## - Exactly 10 collectible coins
## - Clean retry/pause/reset and dramatic World 2 Boss Victory sequence.

@export var survival_duration: float = 60.0

var _survival_elapsed: float = 0.0
var _is_surviving: bool = false
var _is_victory: bool = false
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

# Coins
@onready var coins_container: Node2D = $Coins

# HUD
@onready var coin_counter_label: Label = $HUD/MarginContainer/TopBar/CoinCounter
@onready var level_name_label: Label = $HUD/MarginContainer/TopBar/LevelName
@onready var survival_timer_label: Label = $HUD/MarginContainer/TopBar/TimerContainer/SurvivalTimer
@onready var pause_button: Button = $HUD/MarginContainer/TopBar/PauseBtn
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
	# Coordinated 5-phase schedule: [timestamp, [platform_indices 1..5], warn_time, active_time]
	# Phase 1: 0-15s (Awakening) - 1 hazard at a time, generous warning
	_scheduled_waves.append({"time": 2.0, "plats": [1], "warn": 1.0, "act": 1.8})
	_scheduled_waves.append({"time": 6.0, "plats": [4], "warn": 1.0, "act": 2.0})
	_scheduled_waves.append({"time": 10.0, "plats": [2], "warn": 1.0, "act": 1.8})
	_scheduled_waves.append({"time": 13.5, "plats": [5], "warn": 1.2, "act": 1.8})
	
	# Phase 2: 15-30s (Haunting) - 1 to 2 hazards, upper/mid tier alternation
	_scheduled_waves.append({"time": 17.0, "plats": [3], "warn": 0.9, "act": 1.8})
	_scheduled_waves.append({"time": 20.5, "plats": [1, 5], "warn": 0.9, "act": 1.8})
	_scheduled_waves.append({"time": 24.5, "plats": [4], "warn": 0.85, "act": 2.0})
	_scheduled_waves.append({"time": 27.5, "plats": [2], "warn": 0.85, "act": 1.8})
	
	# Phase 3: 30-45s (Nightmare) - Coordinated pairs, faster cadence
	_scheduled_waves.append({"time": 31.0, "plats": [1, 4], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 34.5, "plats": [2, 5], "warn": 0.8, "act": 1.8})
	_scheduled_waves.append({"time": 38.0, "plats": [3, 1], "warn": 0.75, "act": 1.8})
	_scheduled_waves.append({"time": 41.5, "plats": [4, 2], "warn": 0.75, "act": 1.8})
	
	# Phase 4: 45-55s (Final Descent) - Intense rotation, 10s alert
	_scheduled_waves.append({"time": 45.0, "plats": [3, 5], "warn": 0.7, "act": 1.8})
	_scheduled_waves.append({"time": 48.5, "plats": [1, 4], "warn": 0.7, "act": 1.8})
	_scheduled_waves.append({"time": 52.0, "plats": [2, 5], "warn": 0.65, "act": 1.8})
	
	# Phase 5: 55-60s (Final 5s) - Surprise finale sweeps
	_scheduled_waves.append({"time": 55.5, "plats": [4], "warn": 0.7, "act": 1.8})
	_scheduled_waves.append({"time": 57.5, "plats": [1, 5], "warn": 0.6, "act": 1.8})

func _start_intro_flow() -> void:
	_is_surviving = false
	_is_victory = false
	_survival_elapsed = 0.0
	_update_timer_hud(survival_duration)
	
	if player:
		if spawn_point:
			player.reset_to(spawn_point.global_position)
		player.disable_input()
			
	_reset_all_hazards()
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
	
	GameManager.current_level_id = 10
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	GameManager.is_gameplay_active = true
	coin_counter_label.text = "COINS: 0 / 10"

func _physics_process(delta: float) -> void:
	if not _is_surviving or _is_victory:
		return
		
	_survival_elapsed += delta
	var remaining := maxf(0.0, survival_duration - _survival_elapsed)
	_update_timer_hud(remaining)
	
	# Process hazard scheduler
	_process_hazard_scheduler(_survival_elapsed)
	
	# Process dramatic countdown banners
	_process_countdown_alerts(_survival_elapsed, remaining)
	
	# Check 60-second survival completion
	if _survival_elapsed >= survival_duration and not _is_victory:
		_trigger_survival_victory()

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
	var tween := create_tween()
	tween.tween_property(alert_banner, "scale", Vector2(1.15, 1.15), 0.15)
	tween.tween_property(alert_banner, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(dur - 0.3)
	tween.tween_callback(func():
		if remaining_time_is_past():
			alert_banner.visible = false
	)

func remaining_time_is_past() -> bool:
	return _survival_elapsed >= survival_duration or not _is_surviving

func _trigger_survival_victory() -> void:
	_is_victory = true
	_is_surviving = false
	alert_banner.visible = false
	
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
	
	_shown_10s_alert = false
	_last_5s_announced = -1
	_survival_elapsed = 0.0
	_is_victory = false
	_is_surviving = true
	_executed_wave_indices.clear()
	
	_update_timer_hud(survival_duration)
	
	GameManager.current_level_id = 10
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	coin_counter_label.text = "COINS: 0 / 10"
	
	# Spawn player and restore control immediately
	if player and spawn_point:
		player.reset_to(spawn_point.global_position)
		player.revive()
		
	# Reset coins
	if coins_container:
		for coin in coins_container.get_children():
			if coin.has_method("reset"):
				coin.reset()
				
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
