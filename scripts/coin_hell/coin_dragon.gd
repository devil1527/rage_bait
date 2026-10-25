class_name CoinDragon
extends CharacterBody2D

## World 4 Climactic Final Boss: THE COIN DRAGON
## A massive, golden infernal coin-beast commanding the sanctum of Stage 20 ("The Final Betrayal").
## Features:
## - Distinctive silhouette: coin-shaped embossed torso, obsidian horns, fiery eyes, claws, and spiked tail.
## - Arena-aware navigation: traverses between 10 verified platform stations using exact kinematic trajectories.
## - Readable attack sequence: chooses target station -> telegraphs -> launches -> lands -> recovers.
## - Edge protection: never walks off platform edges into lava.
## - Instant-kill hazard collision: contact with the dragon immediately slays the player.
## - Predictable 5.5-second coin release routine: halts, roars, and launches collectible coins across the arena.
## - Dragon Rage Phase: triggered at 9/10 coins, increasing horizontal movement and attack cadence to 3x baseline.
## - Scripted defeat sequence: flips upside down and plunges into the lava pit upon player entering the exit gate.

enum State {
	IDLE,           # Grounded, observing
	PATROL,         # Pacing safely along current platform
	TELEGRAPH,      # Coiling/crouching, audio warning, signaling target platform
	LEAP,           # Parabolic jump to target station
	LANDING,        # Landing recovery window
	RELEASE_COIN,   # Roaring, launching coin
	RECOVERY,       # Post-coin release recovery
	TRANSFORMATION, # Brief rage transformation pause
	DEFEATED        # Scripted defeat cutscene (falls upside down into lava)
}

signal coin_release_started(index: int)
signal coin_released(spawn_pos: Vector2, index: int)
signal dragon_defeated
signal leap_telegraphed(target_station: String, target_pos: Vector2)
signal leap_started(target_station: String, target_pos: Vector2)
signal leap_landed(station: String, pos: Vector2)
signal dragon_enraged

# Established Normal Baseline Constants
const BASE_MOVE_SPEED: float = 160.0
const BASE_TELEGRAPH_TIME: float = 0.65
const BASE_LANDING_RECOVERY: float = 0.70
const BASE_PATROL_TIME_MIN: float = 1.0
const BASE_PATROL_TIME_MAX: float = 1.5

@export var move_speed: float = BASE_MOVE_SPEED
@export var jump_velocity: float = -440.0
@export var gravity: float = 1150.0

var telegraph_duration: float = BASE_TELEGRAPH_TIME
var landing_recovery_duration: float = BASE_LANDING_RECOVERY
var is_enraged: bool = false

var current_state: State = State.IDLE
var is_active: bool = false
var is_defeated: bool = false
var target_player: CharacterBody2D = null

# 10 Verified Arena Platform Stations
# Each station specifies the exact grounded boss position, platform safe X bounds, and verified connections.
var STATIONS: Dictionary = {
	"RightGround": {
		"pos": Vector2(820.0, 418.0),
		"min_x": 750.0,
		"max_x": 890.0,
		"connections": ["RightStep"]
	},
	"RightStep": {
		"pos": Vector2(770.0, 344.0),
		"min_x": 740.0,
		"max_x": 800.0,
		"connections": ["RightGround", "CenterBridge", "RightMid", "MidRightPerch"]
	},
	"RightMid": {
		"pos": Vector2(830.0, 269.0),
		"min_x": 785.0,
		"max_x": 875.0,
		"connections": ["RightStep", "MidRightPerch"]
	},
	"MidRightPerch": {
		"pos": Vector2(640.0, 219.0),
		"min_x": 605.0,
		"max_x": 675.0,
		"connections": ["CentralAltar", "RightMid", "RightStep", "CenterBridge"]
	},
	"CentralAltar": {
		"pos": Vector2(480.0, 153.0),
		"min_x": 435.0,
		"max_x": 525.0,
		"connections": ["MidLeftPerch", "MidRightPerch"]
	},
	"CenterBridge": {
		"pos": Vector2(480.0, 398.0),
		"min_x": 390.0,
		"max_x": 570.0,
		"connections": ["LeftStep", "RightStep", "MidLeftPerch", "MidRightPerch"]
	},
	"MidLeftPerch": {
		"pos": Vector2(320.0, 219.0),
		"min_x": 285.0,
		"max_x": 355.0,
		"connections": ["CentralAltar", "LeftMid", "LeftStep", "CenterBridge"]
	},
	"LeftMid": {
		"pos": Vector2(130.0, 269.0),
		"min_x": 85.0,
		"max_x": 175.0,
		"connections": ["LeftStep", "MidLeftPerch"]
	},
	"LeftStep": {
		"pos": Vector2(190.0, 344.0),
		"min_x": 160.0,
		"max_x": 220.0,
		"connections": ["LeftGround", "CenterBridge", "LeftMid", "MidLeftPerch"]
	},
	"LeftGround": {
		"pos": Vector2(140.0, 418.0),
		"min_x": 70.0,
		"max_x": 210.0,
		"connections": ["LeftStep"]
	}
}

var current_station_id: String = "RightGround"
var target_station_id: String = ""
var last_station_id: String = ""

var _state_timer: float = 0.0
var _patrol_dir: float = -1.0
var _jump_flight_time: float = 0.0
var _jump_elapsed: float = 0.0
var _target_land_pos: Vector2 = Vector2.ZERO
var _target_jump_vx: float = 0.0

var _pending_coin_idx: int = -1
var _pending_coin_target: Vector2 = Vector2.ZERO
var _coin_has_spawned_for_cycle: bool = false
var _queued_coin_release: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hazard_area: Area2D = $HazardArea
@onready var hazard_shape: CollisionShape2D = $HazardArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var embers_particles: CPUParticles2D = get_node_or_null("EmbersParticles")
@onready var defeat_particles: CPUParticles2D = get_node_or_null("DefeatParticles")

var tex_idle: Texture2D = preload("res://assets/sprites/coin_dragon_idle.png")
var tex_walk: Texture2D = preload("res://assets/sprites/coin_dragon_walk.png")
var tex_jump: Texture2D = preload("res://assets/sprites/coin_dragon_jump.png")
var tex_roar: Texture2D = preload("res://assets/sprites/coin_dragon_roar.png")

func _ready() -> void:
	current_station_id = "RightGround"
	global_position = STATIONS["RightGround"]["pos"]
	if hazard_area:
		hazard_area.body_entered.connect(_on_hazard_body_entered)
	_apply_texture(tex_idle)

func activate(player_ref: CharacterBody2D) -> void:
	target_player = player_ref
	is_active = true
	is_defeated = false
	current_station_id = "RightGround"
	global_position = STATIONS["RightGround"]["pos"]
	velocity = Vector2.ZERO
	current_state = State.PATROL
	_state_timer = 1.2
	_patrol_dir = -1.0
	if hazard_shape:
		hazard_shape.set_deferred("disabled", false)
	if body_shape:
		body_shape.set_deferred("disabled", false)
	if embers_particles:
		embers_particles.emitting = true
	if is_enraged:
		_apply_rage_visuals()

func deactivate() -> void:
	is_active = false
	velocity = Vector2.ZERO
	current_state = State.IDLE
	_apply_texture(tex_idle)
	if embers_particles:
		embers_particles.emitting = false

func _physics_process(delta: float) -> void:
	if is_defeated or not is_active:
		return

	# Continuous proximity / overlap check to prevent tunneling
	_check_player_contact()

	# Bounds safety: prevent falling into pit under any circumstance
	_check_bounds()

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_apply_texture(tex_idle)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_transition_to_next_action()

		State.PATROL:
			_process_patrol_state(delta)

		State.TELEGRAPH:
			_process_telegraph_state(delta)

		State.LEAP:
			_process_leap_state(delta)

		State.LANDING:
			_process_landing_state(delta)

		State.RELEASE_COIN:
			_process_release_coin_state(delta)

		State.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_apply_texture(tex_idle)
			_state_timer -= delta
			if _state_timer <= 0.0:
				if _queued_coin_release:
					_queued_coin_release = false
					_start_coin_release(_pending_coin_idx, _pending_coin_target)
				else:
					current_state = State.PATROL
					var p_min: float = BASE_PATROL_TIME_MIN / (3.0 if is_enraged else 1.0)
					var p_max: float = BASE_PATROL_TIME_MAX / (3.0 if is_enraged else 1.0)
					_state_timer = randf_range(p_min, p_max)

		State.TRANSFORMATION:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.PATROL
				_state_timer = 0.5

	move_and_slide()

## Safe platform patrol with strict edge limits
func _process_patrol_state(delta: float) -> void:
	var st = STATIONS.get(current_station_id, STATIONS["RightGround"])
	var min_x: float = st["min_x"]
	var max_x: float = st["max_x"]

	# Turn around before reaching the edge
	if global_position.x <= min_x:
		_patrol_dir = 1.0
	elif global_position.x >= max_x:
		_patrol_dir = -1.0

	velocity.x = _patrol_dir * move_speed * 0.75
	sprite.flip_h = _patrol_dir < 0.0
	_apply_texture(tex_walk)

	_state_timer -= delta
	if _state_timer <= 0.0:
		_transition_to_next_action()

## Decides whether to leap to another platform or continue patrol
func _transition_to_next_action() -> void:
	if _queued_coin_release:
		_queued_coin_release = false
		_start_coin_release(_pending_coin_idx, _pending_coin_target)
		return

	var next_station: String = _choose_next_station()
	if next_station != "" and next_station != current_station_id:
		_start_telegraph(next_station)
	else:
		current_state = State.PATROL
		var p_min: float = BASE_PATROL_TIME_MIN / (3.0 if is_enraged else 1.0)
		var p_max: float = BASE_PATROL_TIME_MAX / (3.0 if is_enraged else 1.0)
		_state_timer = randf_range(p_min, p_max)

## Selects the smartest connected station based on player position
func _choose_next_station() -> String:
	var st = STATIONS.get(current_station_id, STATIONS["RightGround"])
	var conns: Array = st["connections"]
	if conns.is_empty():
		return current_station_id

	var p_pos: Vector2 = target_player.global_position if (target_player and is_instance_valid(target_player)) else Vector2(100.0, 430.0)

	var best_station: String = ""
	var best_dist: float = 99999.0

	# Filter out immediate back-and-forth oscillation if alternatives exist
	var candidate_conns: Array = []
	for c in conns:
		if c != last_station_id or conns.size() == 1:
			candidate_conns.append(c)
	if candidate_conns.is_empty():
		candidate_conns = conns

	for c in candidate_conns:
		var c_pos: Vector2 = STATIONS[c]["pos"]
		var d: float = c_pos.distance_to(p_pos)
		if d < best_dist:
			best_dist = d
			best_station = c

	return best_station

## Readable telegraph phase warning the player of upcoming leap
func _start_telegraph(dest_id: String) -> void:
	target_station_id = dest_id
	_target_land_pos = STATIONS[dest_id]["pos"]
	current_state = State.TELEGRAPH
	_state_timer = telegraph_duration
	velocity = Vector2.ZERO

	# Face destination platform
	var dx: float = _target_land_pos.x - global_position.x
	if absf(dx) > 5.0:
		sprite.flip_h = dx < 0.0

	_apply_texture(tex_jump)
	sprite.scale = Vector2(1.05, 0.85) # Crouch / coil pose

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("warning")

	leap_telegraphed.emit(dest_id, _target_land_pos)

func _process_telegraph_state(delta: float) -> void:
	velocity.x = 0.0
	_state_timer -= delta

	# Warning flash (faster frequency during rage)
	var freq: float = 35.0 if is_enraged else 20.0
	var pulse: float = sin(_state_timer * freq) * 0.25 + 0.75
	if is_enraged:
		sprite.modulate = Color(2.4, pulse * 0.4, pulse * 0.3, 1.0)
	else:
		sprite.modulate = Color(1.0, pulse, pulse, 1.0)

	if _state_timer <= 0.0:
		sprite.scale = Vector2.ONE
		_apply_rage_visuals()
		_launch_leap()

## Helper to compute clean, natural jump arc height based on platform stations
func _get_arc_height(s_from: String, s_to: String) -> float:
	if "Altar" in s_from or "Altar" in s_to:
		return 45.0
	if ("Perch" in s_from and "Bridge" in s_to) or ("Bridge" in s_from and "Perch" in s_to):
		return 40.0
	if ("Step" in s_from and "Ground" in s_to) or ("Ground" in s_from and "Step" in s_to):
		return 28.0
	return 35.0

## Exact kinematic leap execution with physical trajectory
func _launch_leap() -> void:
	current_state = State.LEAP
	_apply_texture(tex_jump)

	var p1: Vector2 = global_position
	var p2: Vector2 = _target_land_pos

	var arc_h: float = _get_arc_height(current_station_id, target_station_id)

	var y_apex: float = minf(p1.y, p2.y) - arc_h
	var rise: float = maxf(8.0, p1.y - y_apex)
	var fall: float = maxf(8.0, p2.y - y_apex)

	var vy: float = -sqrt(2.0 * gravity * rise)
	var t_up: float = -vy / gravity
	var t_down: float = sqrt(2.0 * fall / gravity)
	_jump_flight_time = t_up + t_down
	_jump_elapsed = 0.0

	var vx: float = (p2.x - p1.x) / _jump_flight_time
	_target_jump_vx = vx
	velocity = Vector2(vx, vy)
	sprite.flip_h = vx < 0.0

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("jump")

	leap_started.emit(target_station_id, _target_land_pos)

func _process_leap_state(delta: float) -> void:
	_jump_elapsed += delta
	velocity.y += gravity * delta

	# Smooth horizontal air stability
	velocity.x = move_toward(velocity.x, _target_jump_vx, 800.0 * delta)

	# Truly physical landing detection:
	# When falling downward onto platform floor
	var is_falling: bool = velocity.y >= 0.0
	var is_grounded: bool = is_on_floor()
	var near_target_y: bool = global_position.y >= (_target_land_pos.y - 12.0)
	var flight_timed_out: bool = _jump_elapsed >= (_jump_flight_time + 0.15)

	if is_falling and is_grounded and (near_target_y or _jump_elapsed >= _jump_flight_time * 0.65):
		_complete_physical_landing()
	elif flight_timed_out and is_grounded:
		_complete_physical_landing()
	elif flight_timed_out and global_position.y >= _target_land_pos.y:
		_complete_physical_landing()

func _complete_physical_landing() -> void:
	last_station_id = current_station_id
	current_station_id = target_station_id

	# Smooth physical deceleration on platform - NO TELEPORTATION SNAP
	velocity.x = 0.0
	if velocity.y > 0.0:
		velocity.y = 0.0

	current_state = State.LANDING
	_state_timer = landing_recovery_duration
	_apply_texture(tex_idle)

	# Impact squash & recover
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.08)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.12)

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("land")

	leap_landed.emit(current_station_id, global_position)

func _process_landing_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
	velocity.y += gravity * delta
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _queued_coin_release:
			_queued_coin_release = false
			_start_coin_release(_pending_coin_idx, _pending_coin_target)
		else:
			current_state = State.PATROL
			var p_min: float = BASE_PATROL_TIME_MIN / (3.0 if is_enraged else 1.0)
			var p_max: float = BASE_PATROL_TIME_MAX / (3.0 if is_enraged else 1.0)
			_state_timer = randf_range(p_min, p_max)

## 5.5-Second Coin Release Cycle
func trigger_coin_release(coin_idx: int, target_land_pos: Vector2) -> void:
	if is_defeated:
		return

	_pending_coin_idx = coin_idx
	_pending_coin_target = target_land_pos

	# If currently airborne in a leap, queue release to execute immediately upon landing
	if current_state == State.LEAP:
		_queued_coin_release = true
		return

	_start_coin_release(coin_idx, target_land_pos)

func _start_coin_release(coin_idx: int, target_land_pos: Vector2) -> void:
	current_state = State.RELEASE_COIN
	_state_timer = 0.8
	_pending_coin_idx = coin_idx
	_coin_has_spawned_for_cycle = false
	velocity = Vector2.ZERO

	# Face the target coin platform
	var dx: float = target_land_pos.x - global_position.x
	if absf(dx) > 5.0:
		sprite.flip_h = dx < 0.0

	_apply_texture(tex_roar)
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("warning")
	coin_release_started.emit(coin_idx)

func _process_release_coin_state(delta: float) -> void:
	velocity.x = 0.0
	_state_timer -= delta
	_apply_texture(tex_roar)

	# Spawn coin at 0.35s into roar
	if _state_timer <= 0.45 and not _coin_has_spawned_for_cycle:
		_coin_has_spawned_for_cycle = true
		coin_released.emit(get_snout_position(), _pending_coin_idx)

	if _state_timer <= 0.0:
		current_state = State.RECOVERY
		_state_timer = 0.5 / (2.0 if is_enraged else 1.0)

func get_snout_position() -> Vector2:
	var forward_x: float = -36.0 if sprite.flip_h else 36.0
	return global_position + Vector2(forward_x, -14.0)

func _check_player_contact() -> void:
	if is_defeated or not is_active:
		return
	if target_player and is_instance_valid(target_player):
		if target_player.has_method("die"):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < 46.0 or (hazard_area and hazard_area.overlaps_body(target_player)):
				target_player.die()

func _on_hazard_body_entered(body: Node2D) -> void:
	if is_defeated or not is_active:
		return
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("die"):
			body.die()

func _check_bounds() -> void:
	# Clamp horizontal position inside arena
	global_position.x = clampf(global_position.x, 50.0, 910.0)

	# Emergency safety: if dragon ever falls below ground tier (e.g. y > 465), recover to safe station
	if global_position.y > 465.0:
		var safe_station = "RightGround" if global_position.x > 480.0 else "LeftGround"
		global_position = STATIONS[safe_station]["pos"]
		current_station_id = safe_station
		velocity = Vector2.ZERO
		current_state = State.PATROL
		_state_timer = 1.0

## Triggers the dedicated Dragon Rage transformation (at 9/10 coins collected)
func enter_rage_mode() -> void:
	if is_enraged or is_defeated:
		return
	is_enraged = true

	# Exactly 3x baseline horizontal movement and attack cadence (non-compounding)
	move_speed = BASE_MOVE_SPEED * 3.0
	telegraph_duration = BASE_TELEGRAPH_TIME / 3.0
	landing_recovery_duration = BASE_LANDING_RECOVERY / 3.0

	_apply_rage_visuals()

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("warning")
		AudioManager.play_sfx("laser")

	# Transformation animation (0.45s)
	if current_state != State.LEAP:
		current_state = State.TRANSFORMATION
		_state_timer = 0.45
		velocity = Vector2.ZERO
		_apply_texture(tex_roar)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.2)
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.25)

	dragon_enraged.emit()

func _apply_rage_visuals() -> void:
	if not is_enraged:
		sprite.modulate = Color.WHITE
		return
	# Predominantly red, fiery infernal glow
	sprite.modulate = Color(2.4, 0.35, 0.25, 1.0)
	if embers_particles:
		embers_particles.amount = 40
		embers_particles.speed_scale = 2.0

## Scripted Defeat Sequence: Dragon roars, flips upside down, and plunges into lava pit
func defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	is_active = false
	current_state = State.DEFEATED
	velocity = Vector2.ZERO

	# Disable all collisions so dragon does not harm player or get blocked by platforms during cutscene
	if hazard_shape:
		hazard_shape.disabled = true
		hazard_shape.set_deferred("disabled", true)
	if body_shape:
		body_shape.disabled = true
		body_shape.set_deferred("disabled", true)
	if embers_particles:
		embers_particles.emitting = false
	if defeat_particles:
		defeat_particles.emitting = true

	_apply_texture(tex_roar)

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("laser")

	# Scripted Defeat Sequence:
	# 1. Shakes and flashes golden-crimson in defeat (0.35s)
	# 2. Flips upside down (rotation PI) (0.35s)
	# 3. Plunges straight down into the lava chasm (1.0s)
	# 4. Submerges beneath lava and emits dragon_defeated
	var tw := create_tween()
	# Dramatic shake
	tw.tween_property(sprite, "modulate", Color(3.0, 2.0, 0.5, 1.0), 0.15)
	tw.tween_property(sprite, "position:x", 6.0, 0.05)
	tw.tween_property(sprite, "position:x", -6.0, 0.05)
	tw.tween_property(sprite, "position:x", 0.0, 0.05)
	tw.tween_property(sprite, "modulate", Color(2.5, 0.3, 0.3, 1.0), 0.1)

	# Flip upside down
	tw.tween_property(sprite, "rotation", PI, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Plunge down into the lava pit
	tw.parallel().tween_property(self, "global_position:y", 580.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)

	# Disappear beneath lava
	tw.tween_callback(func():
		visible = false
		dragon_defeated.emit()
	)

func reset_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	is_defeated = false
	is_active = true
	is_enraged = false
	move_speed = BASE_MOVE_SPEED
	telegraph_duration = BASE_TELEGRAPH_TIME
	landing_recovery_duration = BASE_LANDING_RECOVERY
	current_station_id = "RightGround"
	target_station_id = ""
	last_station_id = ""
	current_state = State.PATROL
	visible = true
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	sprite.position = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.flip_h = false
	_apply_texture(tex_idle)
	_state_timer = 1.2
	_patrol_dir = -1.0
	_coin_has_spawned_for_cycle = false
	_queued_coin_release = false

	if body_shape:
		body_shape.set_deferred("disabled", false)
	if hazard_shape:
		hazard_shape.set_deferred("disabled", false)
	if embers_particles:
		embers_particles.amount = 16
		embers_particles.speed_scale = 1.0
		embers_particles.emitting = true
	if defeat_particles:
		defeat_particles.emitting = false

func _apply_texture(tex: Texture2D) -> void:
	if sprite and tex and sprite.texture != tex:
		sprite.texture = tex
