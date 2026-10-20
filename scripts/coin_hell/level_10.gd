extends Node2D

## Level 10: "Haunted Survival" — World 2: The Haunted Hall Boss Stage
## Fixed 960x540 arena with 5 connected platforms and 10 progressive 6-second rounds:
## Features:
## - Dramatic Boss Stage Introduction ("SURVIVE FOR 1 MINUTE!")
## - 10 Six-Second Rounds totaling 60 seconds with continuous countdown
## - Dynamic Hazard System: Controls BOTH WHEN and WHERE hazards activate
## - Variable Spikes: Multiple spawn positions (left, center apex, right, mids, sequential, dual)
## - Variable Disappearing Platforms: Any platform can become intangible (phantom)
## - Variable Crumbling Platforms: Different platforms crumble across rounds
## - Multiple Ceiling Chains: 5 distinct ceiling attachment points with 1, 2, or 3 chains
## - Dynamic Coin Spawning: Exactly 1 coin per round (10 total) spawned at safe/reachable platforms
## - Controlled Randomization: Multiple curated, validated variants across attempts
## - Anti-Camping: Active rotation guarantees standing still is penalized within 5-6s
## - Clean retry/pause/reset and dramatic World 2 Boss Victory sequence.

@export var survival_duration: float = 60.0

const ROUND_DURATION: float = 6.0
const TOTAL_ROUNDS: int = 10
const COIN_SCENE: PackedScene = preload("res://scenes/coin_hell/coin.tscn")

# Platform Hazard Types reference
const HT_SPIKES := 0
const HT_PHANTOM := 1
const HT_CRUMBLING := 2
const HT_CHAINS := 3
const HT_COUNTDOWN := 4

# Chain Indices:
# 0: ChainLeft (X=260, Y=50)
# 1: ChainMidLeft (X=400, Y=50)
# 2: ChainCenter (X=480, Y=50)
# 3: SurpriseGhostChain (X=620, Y=50)
# 4: ChainRight (X=740, Y=50)

# Optional override for deterministic testing (-1 = randomized per attempt)
var variant_override: int = -1
var current_variant: int = 0
var _last_attempt_variant: int = -1

var _survival_elapsed: float = 0.0
var _is_surviving: bool = false
var _is_victory: bool = false
var current_round: int = 1
var _executed_round_numbers: Dictionary = {}
var _coins_spawned_count: int = 0
var _scheduled_waves: Array[Dictionary] = []
var _executed_wave_indices: Dictionary = {}
var _round_coin_positions: Dictionary = {}

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

# 5 Ceiling Chains
@onready var chain_left: SurpriseGhostChain = $ChainLeft
@onready var chain_mid_left: SurpriseGhostChain = $ChainMidLeft
@onready var chain_center: SurpriseGhostChain = $ChainCenter
@onready var surprise_chain: SurpriseGhostChain = $SurpriseGhostChain
@onready var chain_right: SurpriseGhostChain = $ChainRight

var all_platforms: Array[SurvivalArenaPlatform] = []
var all_chains: Array[SurpriseGhostChain] = []

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
	
	all_platforms = [plat1_spikes, plat2_phantom, plat3_crumbling, plat4_chains, plat5_countdown]
	all_chains = [chain_left, chain_mid_left, chain_center, surprise_chain, chain_right]
	
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.player_died.connect(_on_player_died)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(_on_player_revived)
	
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

func _init_hazard_schedule(chosen_variant: int = -1) -> void:
	_scheduled_waves.clear()
	_round_coin_positions.clear()
	
	var active_v: int = chosen_variant
	if active_v < 0:
		if variant_override >= 0:
			active_v = variant_override
		else:
			var candidates: Array[int] = [0, 1, 2]
			if _last_attempt_variant >= 0 and candidates.size() > 1:
				candidates.erase(_last_attempt_variant)
			active_v = candidates[randi() % candidates.size()]
	
	_last_attempt_variant = active_v
	current_variant = active_v
	
	# Build the 10-round dynamic schedule for the chosen variant
	match active_v:
		0: _build_variant_0()
		1: _build_variant_1()
		2: _build_variant_2()
		_: _build_variant_0()

func _build_variant_0() -> void:
	# VARIANT 0: Balanced Arena Sweep & Sequential Attacks
	# Round 1 (0-6s): P1 Spikes (warn 0.8s), Chain 3 (Mid-Right, X=620)
	_round_coin_positions[1] = Vector2(340, 260) # P2
	_add_wave(1.5, [{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.8, "act": 1.8}])
	_add_wave(3.5, [{"type": "chain", "cid": 3, "warn": 0.8, "act": 1.8, "angle": 46.0, "speed": 2.4}])
	
	# Round 2 (6-12s): P2 Phantom (X=340), Chain 0 (Left, X=260)
	_round_coin_positions[2] = Vector2(480, 170) # P3
	_add_wave(6.8, [{"type": "platform", "pid": 2, "htype": HT_PHANTOM, "warn": 0.8, "act": 1.8}])
	_add_wave(8.5, [{"type": "chain", "cid": 0, "warn": 0.8, "act": 1.8, "angle": 42.0, "speed": 2.5}])
	
	# Round 3 (12-18s): P3 Crumbling (X=480), Spikes on P5 (Right, X=760)
	_round_coin_positions[3] = Vector2(620, 260) # P4
	_add_wave(12.8, [{"type": "platform", "pid": 3, "htype": HT_CRUMBLING, "warn": 0.8, "act": 1.8}])
	_add_wave(14.5, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	
	# Round 4 (18-24s): Chain 3 (X=620), Spikes on P2 (Mid-Left, X=340), P1 Phantom
	_round_coin_positions[4] = Vector2(760, 350) # P5
	_add_wave(18.8, [{"type": "chain", "cid": 3, "warn": 0.75, "act": 1.8, "angle": 46.0, "speed": 2.4}])
	_add_wave(19.8, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(20.8, [{"type": "platform", "pid": 1, "htype": HT_PHANTOM, "warn": 0.75, "act": 1.8}])
	
	# Round 5 (24-30s): P5 Countdown, Dual Chains: Chain 1 (X=400) & Chain 4 (X=740)
	_round_coin_positions[5] = Vector2(480, 160) # P3
	_add_wave(24.8, [{"type": "platform", "pid": 5, "htype": HT_COUNTDOWN, "warn": 0.8, "act": 1.8}])
	_add_wave(26.5, [
		{"type": "chain", "cid": 1, "warn": 0.75, "act": 1.8, "angle": -40.0, "speed": 2.6},
		{"type": "chain", "cid": 4, "warn": 0.75, "act": 1.8, "angle": -44.0, "speed": 2.5}
	])
	
	# Round 6 (30-36s): Spikes on P3 (Center Apex, X=480), P4 Crumbling, Chain 4 (Right, X=740)
	_round_coin_positions[6] = Vector2(200, 350) # P1
	_add_wave(30.8, [{"type": "platform", "pid": 3, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(31.8, [{"type": "platform", "pid": 4, "htype": HT_CRUMBLING, "warn": 0.75, "act": 1.8}])
	_add_wave(33.0, [{"type": "chain", "cid": 4, "warn": 0.75, "act": 1.8, "angle": -44.0, "speed": 2.5}])
	
	# Round 7 (36-42s): Dual Spikes on P1 (X=200) & P5 (X=760), Chain 2 (Center, X=480)
	_round_coin_positions[7] = Vector2(340, 250) # P2
	_add_wave(36.8, [
		{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.7, "act": 1.8},
		{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.7, "act": 1.8}
	])
	_add_wave(38.5, [{"type": "chain", "cid": 2, "warn": 0.7, "act": 1.8, "angle": 45.0, "speed": 2.7}])
	
	# Round 8 (42-48s): P4 Phantom, Spikes on P2, Dual Chains: Chain 0 (X=260) & Chain 3 (X=620)
	_round_coin_positions[8] = Vector2(480, 160) # P3
	_add_wave(42.8, [{"type": "platform", "pid": 4, "htype": HT_PHANTOM, "warn": 0.7, "act": 1.8}])
	_add_wave(43.8, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	_add_wave(44.8, [
		{"type": "chain", "cid": 0, "warn": 0.65, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 3, "warn": 0.65, "act": 1.8, "angle": 46.0, "speed": 2.4}
	])
	
	# Round 9 (48-54s): Sequential Spikes: P1 at 48.8s -> P4 at 50.2s; P3 Crumbling, Chain 1 (X=400)
	_round_coin_positions[9] = Vector2(760, 350) # P5
	_add_wave(48.8, [{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	_add_wave(50.2, [{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	_add_wave(50.8, [{"type": "platform", "pid": 3, "htype": HT_CRUMBLING, "warn": 0.65, "act": 1.8}])
	_add_wave(51.8, [{"type": "chain", "cid": 1, "warn": 0.65, "act": 1.8, "angle": -40.0, "speed": 2.6}])
	
	# Round 10 (54-60s): Dual Spikes on P2 & P5, P1 Phantom, Triple Chains: Chain 0, Chain 2, Chain 4
	_round_coin_positions[10] = Vector2(480, 160) # P3
	_add_wave(54.4, [
		{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8},
		{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8}
	])
	_add_wave(55.2, [{"type": "platform", "pid": 1, "htype": HT_PHANTOM, "warn": 0.6, "act": 1.8}])
	_add_wave(55.8, [
		{"type": "chain", "cid": 0, "warn": 0.6, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 2, "warn": 0.6, "act": 1.8, "angle": 45.0, "speed": 2.7},
		{"type": "chain", "cid": 4, "warn": 0.6, "act": 1.8, "angle": -44.0, "speed": 2.5}
	])

func _build_variant_1() -> void:
	# VARIANT 1: Left-to-Right Flank Rotation & Multiple Chains
	# Round 1 (0-6s): P1 Spikes at 1.5s, Chain 0 (Left, X=260) at 3.2s, Spikes on P5 (Right) at 4.2s
	_round_coin_positions[1] = Vector2(480, 170) # P3
	_add_wave(1.5, [{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.8, "act": 1.8}])
	_add_wave(3.2, [{"type": "chain", "cid": 0, "warn": 0.75, "act": 1.8, "angle": 42.0, "speed": 2.5}])
	_add_wave(4.2, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	
	# Round 2 (6-12s): P4 Phantom dissolves (mid-right), Spikes on P2 at 7.5s, Chain 1 (Mid-Left, X=400) at 8.8s
	_round_coin_positions[2] = Vector2(760, 350) # P5
	_add_wave(6.8, [{"type": "platform", "pid": 4, "htype": HT_PHANTOM, "warn": 0.8, "act": 1.8}])
	_add_wave(7.5, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(8.8, [{"type": "chain", "cid": 1, "warn": 0.8, "act": 1.8, "angle": -40.0, "speed": 2.6}])
	
	# Round 3 (12-18s): P2 Crumbling collapses, Dual Chains: Chain 0 (X=260) & Chain 3 (X=620)
	_round_coin_positions[3] = Vector2(480, 170) # P3
	_add_wave(12.8, [{"type": "platform", "pid": 2, "htype": HT_CRUMBLING, "warn": 0.8, "act": 1.8}])
	_add_wave(13.8, [
		{"type": "chain", "cid": 0, "warn": 0.75, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 3, "warn": 0.75, "act": 1.8, "angle": 46.0, "speed": 2.4}
	])
	_add_wave(14.8, [{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	
	# Round 4 (18-24s): Spikes on P3 (Apex), P5 Phantom, Dual Chains: Chain 2 (X=480) & Chain 4 (X=740)
	_round_coin_positions[4] = Vector2(200, 350) # P1
	_add_wave(18.8, [{"type": "platform", "pid": 3, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(19.5, [{"type": "platform", "pid": 5, "htype": HT_PHANTOM, "warn": 0.75, "act": 1.8}])
	_add_wave(20.8, [
		{"type": "chain", "cid": 2, "warn": 0.7, "act": 1.8, "angle": 45.0, "speed": 2.7},
		{"type": "chain", "cid": 4, "warn": 0.7, "act": 1.8, "angle": -44.0, "speed": 2.5}
	])
	
	# Round 5 (24-30s): P2 Crumbling, Spikes on P5, Dual Chains: Chain 0 (X=260) & Chain 2 (X=480)
	_round_coin_positions[5] = Vector2(620, 260) # P4
	_add_wave(24.8, [{"type": "platform", "pid": 2, "htype": HT_CRUMBLING, "warn": 0.8, "act": 1.8}])
	_add_wave(25.8, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(27.0, [
		{"type": "chain", "cid": 0, "warn": 0.7, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 2, "warn": 0.7, "act": 1.8, "angle": 45.0, "speed": 2.7}
	])
	
	# Round 6 (30-36s): Dual Spikes (P1 & P4), P2 Phantom, Chain 4 (X=740)
	_round_coin_positions[6] = Vector2(480, 160) # P3
	_add_wave(30.8, [
		{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8},
		{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}
	])
	_add_wave(32.5, [{"type": "platform", "pid": 2, "htype": HT_PHANTOM, "warn": 0.75, "act": 1.8}])
	_add_wave(33.5, [{"type": "chain", "cid": 4, "warn": 0.7, "act": 1.8, "angle": -44.0, "speed": 2.5}])
	
	# Round 7 (36-42s): Spikes on P5, P4 Phantom, Dual Chains: Chain 0 (X=260) & Chain 4 (X=740)
	_round_coin_positions[7] = Vector2(200, 350) # P1
	_add_wave(36.8, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.7, "act": 1.8}])
	_add_wave(37.5, [{"type": "platform", "pid": 4, "htype": HT_PHANTOM, "warn": 0.7, "act": 1.8}])
	_add_wave(38.8, [
		{"type": "chain", "cid": 0, "warn": 0.7, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 4, "warn": 0.7, "act": 1.8, "angle": -44.0, "speed": 2.5}
	])
	
	# Round 8 (42-48s): P4 Phantom, Spikes on P5, Dual Chains: Chain 1 (X=400) & Chain 3 (X=620)
	_round_coin_positions[8] = Vector2(340, 250) # P2
	_add_wave(42.8, [{"type": "platform", "pid": 4, "htype": HT_PHANTOM, "warn": 0.7, "act": 1.8}])
	_add_wave(43.8, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	_add_wave(44.8, [
		{"type": "chain", "cid": 1, "warn": 0.65, "act": 1.8, "angle": -40.0, "speed": 2.6},
		{"type": "chain", "cid": 3, "warn": 0.65, "act": 1.8, "angle": 46.0, "speed": 2.4}
	])
	
	# Round 9 (48-54s): Dual Chains: Chain 1 (X=400) & Chain 4 (X=740), P4 Phantom, Spikes on P5
	_round_coin_positions[9] = Vector2(480, 160) # P3
	_add_wave(48.8, [
		{"type": "chain", "cid": 1, "warn": 0.65, "act": 1.8, "angle": -40.0, "speed": 2.6},
		{"type": "chain", "cid": 4, "warn": 0.65, "act": 1.8, "angle": -44.0, "speed": 2.5}
	])
	_add_wave(50.8, [{"type": "platform", "pid": 4, "htype": HT_PHANTOM, "warn": 0.65, "act": 1.8}])
	_add_wave(51.8, [{"type": "platform", "pid": 5, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	
	# Round 10 (54-60s): Dual Spikes (P2 & P4), P1 Countdown, Triple Chains (Chain 1, 4, 0)
	_round_coin_positions[10] = Vector2(480, 160) # P3
	_add_wave(54.4, [
		{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8},
		{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8}
	])
	_add_wave(55.2, [{"type": "platform", "pid": 1, "htype": HT_COUNTDOWN, "warn": 0.6, "act": 1.8}])
	_add_wave(55.8, [
		{"type": "chain", "cid": 1, "warn": 0.6, "act": 1.8, "angle": -40.0, "speed": 2.6},
		{"type": "chain", "cid": 4, "warn": 0.6, "act": 1.8, "angle": -44.0, "speed": 2.5},
		{"type": "chain", "cid": 0, "warn": 0.6, "act": 1.8, "angle": 42.0, "speed": 2.5}
	])

func _build_variant_2() -> void:
	# VARIANT 2: Apex Pressure & Sweeping Chains
	# Round 1 (0-6s): P1 Spikes at 1.5s, Chain 1 (X=400) at 3.0s, Chain 4 (X=740) at 4.2s
	_round_coin_positions[1] = Vector2(620, 260) # P4
	_add_wave(1.5, [{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.8, "act": 1.8}])
	_add_wave(3.0, [{"type": "chain", "cid": 1, "warn": 0.75, "act": 1.8, "angle": -40.0, "speed": 2.6}])
	_add_wave(4.2, [{"type": "chain", "cid": 4, "warn": 0.75, "act": 1.8, "angle": -44.0, "speed": 2.5}])
	
	# Round 2 (6-12s): P3 Phantom (Center Apex dissolves!), P1 Countdown, Chain 3 (X=620)
	_round_coin_positions[2] = Vector2(340, 250) # P2
	_add_wave(6.8, [{"type": "platform", "pid": 3, "htype": HT_PHANTOM, "warn": 0.8, "act": 1.8}])
	_add_wave(8.0, [{"type": "platform", "pid": 1, "htype": HT_COUNTDOWN, "warn": 0.8, "act": 1.8}])
	_add_wave(9.0, [{"type": "chain", "cid": 3, "warn": 0.8, "act": 1.8, "angle": 46.0, "speed": 2.4}])
	
	# Round 3 (12-18s): P4 Crumbling, Spikes on P3 (Apex), Dual Chains: Chain 1 (X=400) & Chain 2 (X=480)
	_round_coin_positions[3] = Vector2(200, 350) # P1
	_add_wave(12.8, [{"type": "platform", "pid": 4, "htype": HT_CRUMBLING, "warn": 0.8, "act": 1.8}])
	_add_wave(13.8, [{"type": "platform", "pid": 3, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(15.0, [
		{"type": "chain", "cid": 1, "warn": 0.75, "act": 1.8, "angle": -40.0, "speed": 2.6},
		{"type": "chain", "cid": 2, "warn": 0.75, "act": 1.8, "angle": 45.0, "speed": 2.7}
	])
	
	# Round 4 (18-24s): P1 Phantom, Spikes on P4, Chain 1 (X=400)
	_round_coin_positions[4] = Vector2(480, 160) # P3
	_add_wave(18.8, [{"type": "platform", "pid": 1, "htype": HT_PHANTOM, "warn": 0.75, "act": 1.8}])
	_add_wave(19.8, [{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(21.0, [{"type": "chain", "cid": 1, "warn": 0.75, "act": 1.8, "angle": -40.0, "speed": 2.6}])
	
	# Round 5 (24-30s): P4 Countdown, Spikes on P2, Chain 4 (X=740)
	_round_coin_positions[5] = Vector2(200, 350) # P1
	_add_wave(24.8, [{"type": "platform", "pid": 4, "htype": HT_COUNTDOWN, "warn": 0.8, "act": 1.8}])
	_add_wave(26.0, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(27.2, [{"type": "chain", "cid": 4, "warn": 0.75, "act": 1.8, "angle": -44.0, "speed": 2.5}])
	
	# Round 6 (30-36s): Sequential Spikes: P1 at 30.8s -> P2 at 32.2s; P4 Crumbling, Chain 2 (X=480)
	_round_coin_positions[6] = Vector2(760, 350) # P5
	_add_wave(30.8, [{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.75, "act": 1.8}])
	_add_wave(32.2, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.7, "act": 1.8}])
	_add_wave(32.8, [{"type": "platform", "pid": 4, "htype": HT_CRUMBLING, "warn": 0.7, "act": 1.8}])
	_add_wave(33.8, [{"type": "chain", "cid": 2, "warn": 0.7, "act": 1.8, "angle": 45.0, "speed": 2.7}])
	
	# Round 7 (36-42s): P3 Crumbling, Spikes on P2, Chain 3 (X=620)
	_round_coin_positions[7] = Vector2(620, 250) # P4
	_add_wave(36.8, [{"type": "platform", "pid": 3, "htype": HT_CRUMBLING, "warn": 0.7, "act": 1.8}])
	_add_wave(38.0, [{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.7, "act": 1.8}])
	_add_wave(39.0, [{"type": "chain", "cid": 3, "warn": 0.7, "act": 1.8, "angle": 46.0, "speed": 2.4}])
	
	# Round 8 (42-48s): Spikes on P3 (Apex), P1 Crumbling, Dual Chains: Chain 0 (X=260) & Chain 2 (X=480)
	_round_coin_positions[8] = Vector2(760, 350) # P5
	_add_wave(42.8, [{"type": "platform", "pid": 3, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}])
	_add_wave(44.0, [{"type": "platform", "pid": 1, "htype": HT_CRUMBLING, "warn": 0.65, "act": 1.8}])
	_add_wave(45.2, [
		{"type": "chain", "cid": 0, "warn": 0.65, "act": 1.8, "angle": 42.0, "speed": 2.5},
		{"type": "chain", "cid": 2, "warn": 0.65, "act": 1.8, "angle": 45.0, "speed": 2.7}
	])
	
	# Round 9 (48-54s): Dual Spikes (P2 & P4), P3 Crumbling, Chain 2 (Center, X=480)
	_round_coin_positions[9] = Vector2(200, 350) # P1
	_add_wave(48.8, [
		{"type": "platform", "pid": 2, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8},
		{"type": "platform", "pid": 4, "htype": HT_SPIKES, "warn": 0.65, "act": 1.8}
	])
	_add_wave(50.5, [{"type": "platform", "pid": 3, "htype": HT_CRUMBLING, "warn": 0.65, "act": 1.8}])
	_add_wave(51.8, [{"type": "chain", "cid": 2, "warn": 0.65, "act": 1.8, "angle": 45.0, "speed": 2.7}])
	
	# Round 10 (54-60s): Dual Spikes (P1 & P3), P4 Crumbling, Triple Chains (Chain 3, 2, 1)
	_round_coin_positions[10] = Vector2(760, 350) # P5
	_add_wave(54.4, [
		{"type": "platform", "pid": 1, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8},
		{"type": "platform", "pid": 3, "htype": HT_SPIKES, "warn": 0.6, "act": 1.8}
	])
	_add_wave(55.2, [{"type": "platform", "pid": 4, "htype": HT_CRUMBLING, "warn": 0.6, "act": 1.8}])
	_add_wave(55.8, [
		{"type": "chain", "cid": 3, "warn": 0.6, "act": 1.8, "angle": 46.0, "speed": 2.4},
		{"type": "chain", "cid": 2, "warn": 0.6, "act": 1.8, "angle": 45.0, "speed": 2.7},
		{"type": "chain", "cid": 1, "warn": 0.6, "act": 1.8, "angle": -40.0, "speed": 2.6}
	])

func _add_wave(t: float, hazards: Array[Dictionary]) -> void:
	_scheduled_waves.append({
		"time": t,
		"hazards": hazards
	})

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
			
	# Advance to Round 1 immediately
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
		
	var coin_pos: Vector2 = _round_coin_positions.get(round_num, Vector2(480, 170))
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
			var hazards: Array = wave.get("hazards", [])
			for h in hazards:
				var h_type: String = h.get("type", "platform")
				if h_type == "platform":
					var pid: int = h.get("pid", 1)
					var htype: int = h.get("htype", HT_SPIKES)
					var warn: float = h.get("warn", 0.8)
					var act: float = h.get("act", 1.8)
					trigger_platform_hazard(pid, htype, warn, act)
				elif h_type == "chain":
					var cid: int = h.get("cid", 3)
					var warn: float = h.get("warn", 0.8)
					var act: float = h.get("act", 1.8)
					var angle: float = h.get("angle", 46.0)
					var speed: float = h.get("speed", 2.4)
					trigger_chain_attack(cid, warn, act, angle, speed)

func trigger_platform_hazard(pid: int, htype: int, warn: float, act: float) -> void:
	if pid < 1 or pid > all_platforms.size():
		return
	var target_plat: SurvivalArenaPlatform = all_platforms[pid - 1]
	if target_plat:
		target_plat.trigger_hazard(warn, act, htype)

func trigger_chain_attack(cid: int, warn: float, act: float, angle: float = 46.0, speed: float = 2.4) -> void:
	if cid < 0 or cid >= all_chains.size():
		return
	var target_chain: SurpriseGhostChain = all_chains[cid]
	if target_chain:
		target_chain.max_swing_angle = angle
		target_chain.swing_speed = speed
		target_chain.trigger_attack(warn, act)

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

func _on_player_revived(_pos: Vector2) -> void:
	_is_surviving = true
	_reset_all_hazards()
	alert_banner.visible = false
	if round_banner:
		round_banner.visible = false
	if death_overlay:
		death_overlay.visible = false

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
			
	# Re-initialize hazard schedule for a fresh, varied attempt
	_init_hazard_schedule()
	
	# Start Round 1
	_advance_to_round(1)
	
	_reset_all_hazards()
	GameManager.coins_reset.emit()
	GameManager.is_gameplay_active = true

func _reset_all_hazards() -> void:
	for plat in all_platforms:
		if plat:
			plat.reset_hazard()
	for ch in all_chains:
		if ch:
			ch.reset()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed() -> void:
	if boss_intro_overlay.is_playing:
		return
	_clear_touch_controls()
	AudioManager.play_sfx("click")
	pause_overlay.open()
