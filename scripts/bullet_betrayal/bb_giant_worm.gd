class_name BulletBetrayalGiantWorm
extends Node2D

## Giant Desert Sandworm Hunting Boss for Bullet Betrayal (World 2, Stage 10).
## Actively hunts the player using varied emergence strategies:
##   - SIDE_AMBUSH: emerges on flanks/edges and charges across toward player
##   - GROUND_AMBUSH: surfaces near player's ground zone with pause-then-lunge bursts
##   - TRACKING_ATTACK: emerges near player's recent movement trail and chases dynamically
##   - PREDICTIVE_ATTACK: anticipates player velocity to cut off escape direction
##   - REPEATED_STRIKE: brief hit-and-run patrol followed by fast re-ambush elsewhere
##   - BAR_STRIKE: vertical sand breach reaching up through overhead hanging bar routes
## Whenever completing a natural retreat underground, emits submerged / submerged_at
## so Stage 10 drops a huge timed boss mine at the exact disappearance point.

signal emerged(pos: Vector2)
signal submerged
signal submerged_at(pos: Vector2)
signal retreat_cancelled
signal warning_started(pos: Vector2)
signal player_killed_by_worm

enum WormState {
	UNDERGROUND,
	WARNING,
	EMERGING,
	CRAWLING,
	SUBMERGING,
	STOPPED
}

enum MovementPattern {
	SIDE_AMBUSH = 0,
	GROUND_AMBUSH = 1,
	TRACKING_ATTACK = 2,
	PREDICTIVE_ATTACK = 3,
	REPEATED_STRIKE = 4,
	BAR_STRIKE = 5
}

@export var territory_min_x: float = 64.0
@export var territory_max_x: float = 1216.0
@export var surface_y: float = 410.0
@export var use_node_y_as_surface: bool = true

@export var base_speed_min: float = 180.0
@export var base_speed_max: float = 230.0
@export var min_player_emerge_clearance: float = 90.0
@export var initial_delay: float = 0.72

var state: WormState = WormState.UNDERGROUND
var active_pattern: MovementPattern = MovementPattern.GROUND_AMBUSH
var planned_pattern: MovementPattern = MovementPattern.SIDE_AMBUSH
var difficulty_phase: int = 0 # 0 = Opening, 1 = Middle, 2 = Final
var current_speed: float = 195.0
var facing_direction: int = 1 # 1 = Right, -1 = Left
var last_emerge_position: Vector2 = Vector2.ZERO
var last_submerge_position: Vector2 = Vector2.ZERO
var direction_change_count: int = 0
var emerge_count: int = 0
var submerge_count: int = 0
var bar_strike_count: int = 0

var _state_timer: float = 0.72
var _active_warning_duration: float = 0.72
var _warning_elapsed: float = 0.0
var _emerge_progress: float = 0.0
var _anim_timer: float = 0.0
var _frame_idx: int = 1
var _last_emerge_x: float = -9999.0
var _turn_timer: float = 1.0
var _pause_burst_timer: float = 0.0
var _did_pause_burst: bool = false
var _burst_active_timer: float = 0.0
var _leap_active: bool = false
var _leap_elapsed: float = 0.0
var _leap_duration: float = 0.88
var _leap_peak_height: float = 166.0
var _current_arc_y: float = 0.0
var _is_stopped: bool = false
var _pattern_history: Array[int] = []
var _emerge_zone_history: Array[int] = [] # 0=left, 1=mid, 2=right
var _player_history: Array[Vector2] = []
var _history_sample_timer: float = 0.0
var _bar_linger_timer: float = 0.0
var _queued_next_pattern: int = -1
var _rapid_next_underground: bool = false

# Rest & hidden Y inside BodyClip (offset_top = -250, offset_bottom = 0)
const HEAD_REST_Y: float = 225.0
const HEAD_HIDDEN_Y: float = 284.0
const TORSO_REST_Y: float = 228.0
const TORSO_HIDDEN_Y: float = 286.0
const TAIL_REST_Y: float = 232.0
const TAIL_HIDDEN_Y: float = 288.0

@onready var bar_strike_beam: ColorRect = get_node_or_null("BarStrikeBeam")
@onready var sand_mound: Sprite2D = $SandMound
@onready var sand_particles: CPUParticles2D = $SandParticles
@onready var warning_fissure: ColorRect = $WarningFissure
@onready var warning_label: Label = $WarningLabel
@onready var body_clip: Control = $BodyClip
@onready var tail_sprite: Sprite2D = $BodyClip/TailSegment
@onready var torso_sprite: Sprite2D = $BodyClip/TorsoSegment
@onready var head_sprite: Sprite2D = $BodyClip/HeadSprite
@onready var eye_glow: ColorRect = $BodyClip/HeadSprite/EyeGlow
@onready var kill_zone: Area2D = $KillZone
@onready var kill_col: CollisionShape2D = $KillZone/CollisionShape2D

var _tex_crawl_1: Texture2D
var _tex_crawl_2: Texture2D


func _ready() -> void:
	add_to_group("desert_worms")
	add_to_group("giant_worm")
	add_to_group("hazards")

	if use_node_y_as_surface:
		surface_y = global_position.y
	else:
		global_position.y = surface_y

	_tex_crawl_1 = load("res://assets/sprites/bb_desert_worm_crawl_1.png")
	_tex_crawl_2 = load("res://assets/sprites/bb_desert_worm_crawl_2.png")

	if kill_zone:
		kill_zone.collision_layer = 4
		kill_zone.collision_mask = 1
		if not kill_zone.body_entered.is_connected(_on_kill_zone_body_entered):
			kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	_enter_underground(maxf(0.25, initial_delay))


func set_difficulty_phase(phase: int) -> void:
	difficulty_phase = clampi(phase, 0, 2)


func queue_next_pattern(pattern: int) -> void:
	_queued_next_pattern = pattern


func _physics_process(delta: float) -> void:
	if _is_stopped or state == WormState.STOPPED:
		return

	global_position.y = surface_y
	_sample_player_telemetry(delta)

	match state:
		WormState.UNDERGROUND:
			_process_underground(delta)
		WormState.WARNING:
			_process_warning(delta)
		WormState.EMERGING:
			_process_emerging(delta)
		WormState.CRAWLING:
			_process_crawling(delta)
		WormState.SUBMERGING:
			_process_submerging(delta)


func _sample_player_telemetry(delta: float) -> void:
	var p := _get_active_player()
	if not p or ("is_alive" in p and not p.is_alive):
		_bar_linger_timer = 0.0
		return

	_history_sample_timer += delta
	if _history_sample_timer >= 0.15:
		_history_sample_timer = 0.0
		_player_history.append(p.global_position)
		if _player_history.size() > 14:
			_player_history.pop_front()

	if ("is_hanging" in p and p.is_hanging) or p.global_position.y < 328.0:
		_bar_linger_timer += delta
	else:
		_bar_linger_timer = maxf(0.0, _bar_linger_timer - delta * 1.5)


func _process_underground(delta: float) -> void:
	_state_timer -= delta
	if _state_timer > 0.0:
		return

	var chosen_pattern: int = _choose_hunting_pattern()
	var target_x: float = _pick_emerge_x_for_pattern(chosen_pattern)
	if target_x < -9000.0:
		_state_timer = 0.22
		return

	planned_pattern = chosen_pattern as MovementPattern
	_enter_warning(target_x, planned_pattern)


func _process_warning(delta: float) -> void:
	_warning_elapsed += delta
	_state_timer -= delta

	var pulse: float = 0.55 + 0.45 * absf(sin(_warning_elapsed * 16.0))
	if sand_mound:
		sand_mound.position.x = sin(_warning_elapsed * 44.0) * 4.8
		sand_mound.position.y = -15.0 + absf(cos(_warning_elapsed * 28.0)) * 2.5
	if warning_fissure:
		warning_fissure.color.a = pulse * 0.88
	if warning_label:
		warning_label.modulate.a = 0.5 + 0.5 * pulse
	if bar_strike_beam:
		bar_strike_beam.visible = (planned_pattern == MovementPattern.BAR_STRIKE)
		if bar_strike_beam.visible:
			bar_strike_beam.color.a = lerpf(0.16, 0.48, pulse)

	if _state_timer <= 0.0:
		# Fair guard: never burst directly beneath a standing floor player without shifting safely
		var p := _get_active_player()
		var p_on_ground: bool = p != null and p.global_position.y >= 350.0 and (not ("is_hanging" in p) or not bool(p.is_hanging))
		if p_on_ground and _is_player_near_x(global_position.x, 52.0):
			var alt_x: float = _pick_safe_fallback_x(global_position.x)
			if alt_x > -9000.0:
				_enter_warning(alt_x, planned_pattern)
				return
			_enter_underground(0.45)
			return
		_enter_emerging()


func _process_emerging(delta: float) -> void:
	var dur: float = 0.20 if active_pattern == MovementPattern.BAR_STRIKE else 0.24
	_emerge_progress = minf(1.0, _emerge_progress + delta / dur)
	_current_arc_y = 0.0
	if active_pattern == MovementPattern.BAR_STRIKE:
		_current_arc_y = lerpf(0.0, -34.0, _emerge_progress)

	_apply_segment_y_offsets(lerpf(HEAD_HIDDEN_Y, HEAD_REST_Y + _current_arc_y, _emerge_progress),
		lerpf(TORSO_HIDDEN_Y, TORSO_REST_Y + _current_arc_y * 0.9, _emerge_progress),
		lerpf(TAIL_HIDDEN_Y, TAIL_REST_Y + _current_arc_y * 0.75, _emerge_progress))
	_update_segment_positions(0.0)

	if _emerge_progress >= 0.42:
		_set_hitbox_enabled(true)
		_update_kill_col_offset()
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		_enter_crawling()


func _process_crawling(delta: float) -> void:
	_state_timer -= delta
	var left_bound: float = territory_min_x + 48.0
	var right_bound: float = territory_max_x - 48.0

	# Active vertical leap through overhead bars during BAR_STRIKE
	if _leap_active:
		_leap_elapsed += delta
		var t: float = clampf(_leap_elapsed / maxf(0.1, _leap_duration), 0.0, 1.0)
		_current_arc_y = -_leap_peak_height * sin(t * PI)
		if t >= 1.0:
			_leap_active = false
			_current_arc_y = 0.0
			if sand_particles:
				sand_particles.emitting = true
			if bar_strike_beam:
				bar_strike_beam.visible = false
	else:
		_current_arc_y = move_toward(_current_arc_y, 0.0, 420.0 * delta)

	# Pause-then-dash telegraph for ambush/tracking aggression
	if _pause_burst_timer > 0.0:
		_pause_burst_timer -= delta
		if _pause_burst_timer <= 0.0:
			_burst_active_timer = 0.72
			var p := _get_active_player()
			if p and absf(p.global_position.x - global_position.x) > 12.0:
				var aim_dir: int = 1 if p.global_position.x >= global_position.x else -1
				if aim_dir != facing_direction:
					facing_direction = aim_dir
					direction_change_count += 1
					_update_facing()
		_update_kill_col_offset()
		_check_overlapping_player()
		_animate_crawl(delta * 0.6)
		return

	if _burst_active_timer > 0.0:
		_burst_active_timer = maxf(0.0, _burst_active_timer - delta)

	var eff_speed: float = current_speed * (1.30 if _burst_active_timer > 0.0 else 1.0)
	if _leap_active:
		eff_speed = current_speed * 0.62 # Tighter horizontal drift during vertical breach arc

	global_position.x += facing_direction * eff_speed * delta

	if global_position.x <= left_bound:
		global_position.x = left_bound
		facing_direction = 1
		direction_change_count += 1
		_update_facing()
	elif global_position.x >= right_bound:
		global_position.x = right_bound
		facing_direction = -1
		direction_change_count += 1
		_update_facing()
	elif not _leap_active:
		_process_mid_crawl_hunting(delta, left_bound, right_bound)

	_update_kill_col_offset()
	_animate_crawl(delta)
	_check_overlapping_player()

	if _state_timer <= 0.0 and not _leap_active:
		_enter_submerging()


func _process_mid_crawl_hunting(delta: float, left_bound: float, right_bound: float) -> void:
	var p := _get_active_player()
	if not p or ("is_alive" in p and not p.is_alive):
		return

	# Pause-burst trigger midway through ground or predictive charges
	if not _did_pause_burst and (active_pattern == MovementPattern.GROUND_AMBUSH or active_pattern == MovementPattern.TRACKING_ATTACK):
		if _state_timer <= 1.45 and _state_timer >= 0.85 and randf() < 0.75:
			_did_pause_burst = true
			_pause_burst_timer = 0.22
			return

	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = randf_range(0.62, 1.05) if difficulty_phase >= 1 else randf_range(0.85, 1.35)
		var dx: float = p.global_position.x - global_position.x
		var desired_dir: int = 1 if dx >= 0.0 else -1
		if desired_dir != facing_direction and absf(dx) > 70.0:
			if global_position.x > left_bound + 35.0 and global_position.x < right_bound - 35.0:
				facing_direction = desired_dir
				direction_change_count += 1
				_update_facing()


func _process_submerging(delta: float) -> void:
	var dur: float = 0.26 if difficulty_phase >= 2 else 0.32
	_emerge_progress = minf(1.0, _emerge_progress + delta / dur)
	_current_arc_y = move_toward(_current_arc_y, 0.0, 500.0 * delta)

	_apply_segment_y_offsets(lerpf(HEAD_REST_Y, HEAD_HIDDEN_Y, _emerge_progress),
		lerpf(TORSO_REST_Y, TORSO_HIDDEN_Y, _emerge_progress),
		lerpf(TAIL_REST_Y, TAIL_HIDDEN_Y, _emerge_progress))
	_update_segment_positions(0.0)

	if _emerge_progress >= 0.45:
		_set_hitbox_enabled(false)
	else:
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		var submerge_pos := Vector2(clampf(global_position.x, territory_min_x + 32.0, territory_max_x - 32.0), surface_y)
		last_submerge_position = submerge_pos
		submerge_count += 1
		submerged.emit()
		submerged_at.emit(submerge_pos)
		_enter_underground(_next_underground_delay())


func _next_underground_delay() -> float:
	if _rapid_next_underground:
		_rapid_next_underground = false
		return randf_range(0.42, 0.68)
	match difficulty_phase:
		0:
			return randf_range(1.00, 1.60)
		1:
			return randf_range(0.70, 1.25)
		_:
			return randf_range(0.45, 0.90)


func _animate_crawl(delta: float) -> void:
	_anim_timer += delta
	var cycle_speed: float = 0.095 if (_burst_active_timer > 0.0 or difficulty_phase >= 2) else 0.13
	if _anim_timer >= cycle_speed:
		_anim_timer = 0.0
		_frame_idx = 2 if _frame_idx == 1 else 1
		var tex: Texture2D = _tex_crawl_2 if _frame_idx == 2 else _tex_crawl_1
		if head_sprite:
			head_sprite.texture = tex
		if torso_sprite:
			torso_sprite.texture = _tex_crawl_1 if _frame_idx == 2 else _tex_crawl_2
		if tail_sprite:
			tail_sprite.texture = tex

	_apply_segment_y_offsets(HEAD_REST_Y + _current_arc_y,
		TORSO_REST_Y + _current_arc_y * 0.88,
		TAIL_REST_Y + _current_arc_y * 0.72)
	_update_segment_positions(Time.get_ticks_msec() * 0.014)


func _apply_segment_y_offsets(hy: float, ty: float, tly: float) -> void:
	if head_sprite:
		head_sprite.position.y = hy
	if torso_sprite:
		torso_sprite.position.y = ty
	if tail_sprite:
		tail_sprite.position.y = tly


func _update_segment_positions(wave_t: float) -> void:
	var dir: float = float(facing_direction)
	if head_sprite:
		head_sprite.position.x = 160.0 + dir * 18.0
		var head_squash: float = sin(wave_t) * 0.08
		head_sprite.scale = Vector2(2.6 * (1.0 + head_squash), 2.4 * (1.0 - head_squash * 0.8))
	if torso_sprite:
		torso_sprite.position.x = 160.0 - dir * 24.0
		var torso_squash: float = cos(wave_t - 0.9) * 0.07
		torso_sprite.scale = Vector2(2.2 * (1.0 + torso_squash), 2.1 * (1.0 - torso_squash * 0.7))
	if tail_sprite:
		tail_sprite.position.x = 160.0 - dir * 58.0
		var tail_squash: float = sin(wave_t - 1.8) * 0.06
		tail_sprite.scale = Vector2(1.75 * (1.0 + tail_squash), 1.75 * (1.0 - tail_squash * 0.7))
	if eye_glow:
		eye_glow.position.x = 11.0 if facing_direction > 0 else -15.0


func _update_kill_col_offset() -> void:
	if kill_col:
		kill_col.position.x = -float(facing_direction) * 12.0
		kill_col.position.y = -18.0 + _current_arc_y


func _enter_underground(duration: float) -> void:
	if _is_stopped:
		return
	state = WormState.UNDERGROUND
	_state_timer = maxf(0.22, duration)
	_leap_active = false
	_current_arc_y = 0.0
	_set_hitbox_enabled(false)
	_update_kill_col_offset()
	if bar_strike_beam:
		bar_strike_beam.visible = false
	if sand_mound:
		sand_mound.visible = false
		sand_mound.position = Vector2(0, -15)
	if sand_particles:
		sand_particles.emitting = false
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	for seg in [head_sprite, torso_sprite, tail_sprite]:
		if seg:
			seg.visible = false
	_apply_segment_y_offsets(HEAD_HIDDEN_Y, TORSO_HIDDEN_Y, TAIL_HIDDEN_Y)


func _enter_warning(emerge_x: float, pattern: MovementPattern = MovementPattern.GROUND_AMBUSH) -> void:
	if _is_stopped:
		return
	state = WormState.WARNING
	planned_pattern = pattern
	var clamped_x: float = clampf(emerge_x, territory_min_x + 48.0, territory_max_x - 48.0)
	_last_emerge_x = clamped_x
	_record_emerge_zone(clamped_x)
	global_position = Vector2(clamped_x, surface_y)
	_warning_elapsed = 0.0

	var base_warn: float = 0.78 if difficulty_phase == 0 else (0.64 if difficulty_phase == 1 else 0.54)
	if pattern == MovementPattern.BAR_STRIKE:
		base_warn = maxf(base_warn, 0.74)
	_active_warning_duration = clampf(base_warn * randf_range(0.94, 1.08), 0.50, 0.90)
	_state_timer = _active_warning_duration
	_set_hitbox_enabled(false)
	for seg in [head_sprite, torso_sprite, tail_sprite]:
		if seg:
			seg.visible = false
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -15)
	if sand_particles:
		sand_particles.emitting = true
	if warning_fissure:
		warning_fissure.visible = true
	if warning_label:
		warning_label.visible = true
		warning_label.text = "⚠ BAR LEAP INCOMING!" if pattern == MovementPattern.BAR_STRIKE else "⚠ BOSS EMERGING"
	if bar_strike_beam:
		bar_strike_beam.visible = (pattern == MovementPattern.BAR_STRIKE)
	warning_started.emit(global_position)


func _enter_emerging() -> void:
	if _is_stopped:
		return
	state = WormState.EMERGING
	active_pattern = planned_pattern
	_emerge_progress = 0.0
	emerge_count += 1
	last_emerge_position = global_position
	_set_hitbox_enabled(false)

	var p := _get_active_player()
	if p:
		facing_direction = 1 if p.global_position.x >= global_position.x else -1
	else:
		facing_direction = 1 if global_position.x < (territory_min_x + territory_max_x) * 0.5 else -1

	_configure_pattern_params(active_pattern)
	_update_facing()

	if head_sprite:
		head_sprite.visible = true
		head_sprite.texture = _tex_crawl_1
	if torso_sprite:
		torso_sprite.visible = true
		torso_sprite.texture = _tex_crawl_2
	if tail_sprite:
		tail_sprite.visible = true
		tail_sprite.texture = _tex_crawl_1
	_apply_segment_y_offsets(HEAD_HIDDEN_Y, TORSO_HIDDEN_Y, TAIL_HIDDEN_Y)
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	if sand_mound:
		sand_mound.visible = true
	if sand_particles:
		sand_particles.emitting = true

	if active_pattern == MovementPattern.BAR_STRIKE:
		bar_strike_count += 1
		if bar_strike_beam:
			bar_strike_beam.visible = true

	AudioManager.play_sfx("explosion")
	emerged.emit(global_position)


func _enter_crawling() -> void:
	if _is_stopped:
		return
	state = WormState.CRAWLING
	_did_pause_burst = false
	_pause_burst_timer = 0.0
	_burst_active_timer = 0.0
	_turn_timer = randf_range(0.55, 0.95)
	_anim_timer = 0.0
	_set_hitbox_enabled(true)

	if active_pattern == MovementPattern.BAR_STRIKE:
		_leap_active = true
		_leap_elapsed = 0.0
		_leap_duration = 0.86
		_state_timer = 1.65 if difficulty_phase >= 2 else 1.95
	else:
		_leap_active = false
		_current_arc_y = 0.0
		if active_pattern == MovementPattern.REPEATED_STRIKE:
			_state_timer = randf_range(1.25, 1.70)
			_rapid_next_underground = true
		else:
			var c_min: float = 2.1 if difficulty_phase == 0 else (1.9 if difficulty_phase == 1 else 1.7)
			var c_max: float = 3.1 if difficulty_phase == 0 else (2.9 if difficulty_phase == 1 else 2.6)
			_state_timer = randf_range(c_min, c_max)

	_update_kill_col_offset()
	if head_sprite:
		head_sprite.visible = true
	if torso_sprite:
		torso_sprite.visible = true
	if tail_sprite:
		tail_sprite.visible = true
	_apply_segment_y_offsets(HEAD_REST_Y + _current_arc_y,
		TORSO_REST_Y + _current_arc_y * 0.88,
		TAIL_REST_Y + _current_arc_y * 0.72)

	if sand_mound:
		sand_mound.visible = false
	if sand_particles:
		sand_particles.emitting = false
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	if bar_strike_beam and active_pattern != MovementPattern.BAR_STRIKE:
		bar_strike_beam.visible = false
	_update_segment_positions(0.0)


func _enter_submerging() -> void:
	if _is_stopped:
		return
	state = WormState.SUBMERGING
	_emerge_progress = 0.0
	_leap_active = false
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -15)
	if sand_particles:
		sand_particles.emitting = true
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	if bar_strike_beam:
		bar_strike_beam.visible = false


func _configure_pattern_params(pattern: MovementPattern) -> void:
	_pattern_history.append(int(pattern))
	if _pattern_history.size() > 6:
		_pattern_history.pop_front()

	var phase_mult: float = 1.0 if difficulty_phase == 0 else (1.14 if difficulty_phase == 1 else 1.26)
	var base: float = randf_range(base_speed_min, base_speed_max) * phase_mult

	match pattern:
		MovementPattern.SIDE_AMBUSH, MovementPattern.PREDICTIVE_ATTACK:
			current_speed = base * 1.15
			_tint_segments(Color(1.18, 0.66, 0.50, 1.0), Color(1.08, 0.62, 0.48, 1.0))
		MovementPattern.REPEATED_STRIKE, MovementPattern.BAR_STRIKE:
			current_speed = base * 1.20
			_tint_segments(Color(1.26, 0.58, 0.46, 1.0), Color(1.16, 0.55, 0.44, 1.0))
		_:
			current_speed = base
			_tint_segments(Color(1.08, 0.78, 0.62, 1.0), Color(1.02, 0.74, 0.58, 1.0))


func _tint_segments(head_col: Color, torso_col: Color) -> void:
	if head_sprite:
		head_sprite.modulate = head_col
	if torso_sprite:
		torso_sprite.modulate = torso_col


func _choose_hunting_pattern() -> int:
	if _queued_next_pattern >= 0:
		var forced: int = _queued_next_pattern
		_queued_next_pattern = -1
		return forced

	var p := _get_active_player()
	var bars := _get_hanging_bars()

	# If player lingers on hanging bars or above bar altitude, strongly prioritize a readable Bar Strike!
	if not bars.is_empty() and (_bar_linger_timer >= 0.85 or (p and "is_hanging" in p and p.is_hanging and randf() < 0.72)):
		if _pattern_history.is_empty() or _pattern_history.back() != int(MovementPattern.BAR_STRIKE):
			return int(MovementPattern.BAR_STRIKE)

	var pool: Array[int] = [
		int(MovementPattern.SIDE_AMBUSH),
		int(MovementPattern.GROUND_AMBUSH),
		int(MovementPattern.TRACKING_ATTACK),
		int(MovementPattern.PREDICTIVE_ATTACK)
	]
	if difficulty_phase >= 1 or not bars.is_empty():
		pool.append(int(MovementPattern.REPEATED_STRIKE))
		if not bars.is_empty():
			pool.append(int(MovementPattern.BAR_STRIKE))
	if difficulty_phase >= 2:
		pool.append(int(MovementPattern.PREDICTIVE_ATTACK))
		pool.append(int(MovementPattern.TRACKING_ATTACK))

	# Remove immediately preceding pattern to prevent stale repetition
	if not _pattern_history.is_empty():
		var prev_p: int = _pattern_history.back()
		var filtered: Array[int] = []
		for item in pool:
			if item != prev_p:
				filtered.append(item)
		if not filtered.is_empty():
			pool = filtered

	return pool[randi() % pool.size()]


func _pick_emerge_x_for_pattern(pattern_int: int) -> float:
	var min_x: float = territory_min_x + 48.0
	var max_x: float = territory_max_x - 48.0
	var p := _get_active_player()
	var px: float = p.global_position.x if p else 640.0
	var p_vel_x: float = p.velocity.x if p else 0.0
	var p_dir: int = (1 if p_vel_x > 10.0 else (-1 if p_vel_x < -10.0 else (p.facing_direction if (p and "facing_direction" in p) else 1)))

	match pattern_int:
		MovementPattern.BAR_STRIKE:
			var target_bar: Node2D = _pick_target_bar_for_strike(p)
			if target_bar:
				var bx_min: float = float(target_bar.call("get_min_x")) + 24.0 if target_bar.has_method("get_min_x") else target_bar.global_position.x - 80.0
				var bx_max: float = float(target_bar.call("get_max_x")) - 24.0 if target_bar.has_method("get_max_x") else target_bar.global_position.x + 80.0
				if p and (("is_hanging" in p and p.is_hanging) or p.global_position.y < 330.0) and px >= bx_min - 20.0 and px <= bx_max + 20.0:
					return clampf(px + randf_range(-28.0, 28.0), bx_min, bx_max)
				return clampf(randf_range(bx_min, bx_max), min_x, max_x)

		MovementPattern.PREDICTIVE_ATTACK:
			var lead: float = clampf(absf(p_vel_x) * 0.72 + 150.0, 125.0, 245.0)
			var pred_x: float = clampf(px + float(p_dir) * lead, min_x, max_x)
			if _is_valid_ground_emerge(pred_x, min_player_emerge_clearance):
				return pred_x
			var opp_x: float = clampf(px - float(p_dir) * lead, min_x, max_x)
			if _is_valid_ground_emerge(opp_x, min_player_emerge_clearance):
				return opp_x

		MovementPattern.TRACKING_ATTACK:
			if not _player_history.is_empty():
				var recent: Vector2 = _player_history[maxi(0, _player_history.size() - 4)]
				var cand_t: float = clampf(recent.x + (1.0 if randf() > 0.5 else -1.0) * randf_range(96.0, 145.0), min_x, max_x)
				if _is_valid_ground_emerge(cand_t, min_player_emerge_clearance):
					return cand_t

		MovementPattern.SIDE_AMBUSH:
			var left_flank: float = randf_range(min_x, min_x + 150.0)
			var right_flank: float = randf_range(max_x - 150.0, max_x)
			var flank_x: float = right_flank if px < (min_x + max_x) * 0.5 else left_flank
			if _is_valid_ground_emerge(flank_x, min_player_emerge_clearance) and absf(flank_x - _last_emerge_x) >= 120.0:
				return flank_x

		MovementPattern.GROUND_AMBUSH:
			for _j in range(10):
				var side: float = -1.0 if randf() < 0.5 else 1.0
				var cand_g: float = clampf(px + side * randf_range(min_player_emerge_clearance + 16.0, 225.0), min_x, max_x)
				if _is_valid_ground_emerge(cand_g, min_player_emerge_clearance) and absf(cand_g - _last_emerge_x) >= 100.0:
					return cand_g

	return _pick_varied_fallback_x()


func _pick_varied_fallback_x() -> float:
	var min_x: float = territory_min_x + 48.0
	var max_x: float = territory_max_x - 48.0
	var span: float = max_x - min_x
	var preferred_zone: int = 0
	if not _emerge_zone_history.is_empty():
		var last_z: int = _emerge_zone_history.back()
		var options := [0, 1, 2]
		options.erase(last_z)
		preferred_zone = options[randi() % options.size()]

	var z_min: float = min_x + (span * float(preferred_zone) / 3.0)
	var z_max: float = min_x + (span * float(preferred_zone + 1) / 3.0)
	var candidates: Array[float] = []
	for _i in range(14):
		var c: float = randf_range(z_min, z_max)
		if _is_valid_ground_emerge(c, min_player_emerge_clearance):
			candidates.append(c)
	if not candidates.is_empty():
		return candidates[randi() % candidates.size()]

	return _pick_safe_fallback_x(_last_emerge_x)


func _pick_safe_fallback_x(avoid_x: float) -> float:
	var min_x: float = territory_min_x + 48.0
	var max_x: float = territory_max_x - 48.0
	var best: Array[float] = []
	var x: float = min_x
	while x <= max_x:
		if _is_valid_ground_emerge(x, min_player_emerge_clearance) and absf(x - avoid_x) >= 85.0:
			best.append(x)
		x += 44.0
	if best.is_empty():
		x = min_x
		while x <= max_x:
			if _is_valid_ground_emerge(x, 64.0):
				best.append(x)
			x += 44.0
	if best.is_empty():
		return -9999.0
	return best[randi() % best.size()]


func _is_valid_ground_emerge(x_pos: float, clearance: float) -> bool:
	var p := _get_active_player()
	if not p or ("is_alive" in p and not p.is_alive):
		return true
	if p.global_position.y < 335.0:
		return true
	return absf(p.global_position.x - x_pos) >= clearance


func _record_emerge_zone(x_pos: float) -> void:
	var t: float = (x_pos - territory_min_x) / maxf(1.0, territory_max_x - territory_min_x)
	var z: int = 0 if t < 0.34 else (2 if t > 0.66 else 1)
	_emerge_zone_history.append(z)
	if _emerge_zone_history.size() > 6:
		_emerge_zone_history.pop_front()


func _pick_target_bar_for_strike(p: Node2D) -> Node2D:
	var bars := _get_hanging_bars()
	if bars.is_empty():
		return null
	if p:
		if "current_hanging_bar" in p and is_instance_valid(p.current_hanging_bar):
			return p.current_hanging_bar as Node2D
		var closest: Node2D = null
		var best_dx: float = INF
		for b in bars:
			var d: float = absf(b.global_position.x - p.global_position.x)
			if d < best_dx:
				best_dx = d
				closest = b
		if closest:
			return closest
	return bars[randi() % bars.size()]


func _get_hanging_bars() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if not tree:
		return result
	var level_root := get_parent()
	for node in tree.get_nodes_in_group("hanging_bars"):
		if is_instance_valid(node) and node is Node2D:
			if level_root == null or level_root.is_ancestor_of(node):
				result.append(node as Node2D)
	return result


func _update_facing() -> void:
	var flip: bool = (facing_direction < 0)
	if head_sprite:
		head_sprite.flip_h = flip
	if torso_sprite:
		torso_sprite.flip_h = flip
	if tail_sprite:
		tail_sprite.flip_h = flip
	_update_kill_col_offset()


func _set_hitbox_enabled(enabled: bool) -> void:
	if kill_zone:
		kill_zone.monitoring = enabled
		kill_zone.monitorable = enabled
	if kill_col:
		kill_col.disabled = not enabled


func _is_player_near_x(x_pos: float, clearance: float) -> bool:
	var p := _get_active_player()
	if not p or ("is_alive" in p and not p.is_alive):
		return false
	return absf(p.global_position.x - x_pos) < clearance


func _check_overlapping_player() -> void:
	if not kill_zone or not kill_zone.monitoring:
		return
	for body in kill_zone.get_overlapping_bodies():
		_on_kill_zone_body_entered(body)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if not is_emerged():
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if "is_alive" in body and not body.is_alive:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("take_damage"):
			body.take_damage(1)
			player_killed_by_worm.emit()


func _get_active_player() -> Node2D:
	var tree := get_tree()
	if not tree:
		return null
	var level_root: Node = get_parent()
	for node in tree.get_nodes_in_group("player"):
		if is_instance_valid(node) and node is Node2D:
			if level_root and level_root.is_ancestor_of(node):
				return node as Node2D
			return node as Node2D
	return null


func is_emerged() -> bool:
	if _is_stopped or state == WormState.STOPPED:
		return false
	if state == WormState.CRAWLING:
		return true
	if state == WormState.EMERGING or state == WormState.SUBMERGING:
		return kill_zone != null and kill_zone.monitoring
	return false


func is_underground() -> bool:
	return state == WormState.UNDERGROUND


func request_soonest_dive(max_remaining_crawl: float = 0.25) -> void:
	if _is_stopped:
		return
	if state == WormState.CRAWLING and not _leap_active and _state_timer > max_remaining_crawl:
		_state_timer = max_remaining_crawl


func stop_encounter() -> void:
	_is_stopped = true
	state = WormState.STOPPED
	_leap_active = false
	_current_arc_y = 0.0
	_set_hitbox_enabled(false)
	if bar_strike_beam:
		bar_strike_beam.visible = false
	if sand_mound:
		sand_mound.visible = false
	if sand_particles:
		sand_particles.emitting = false
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	for seg in [head_sprite, torso_sprite, tail_sprite]:
		if seg:
			seg.visible = false


func force_emerge_at(x_pos: float, dir: int = 1, pattern: int = -1) -> void:
	_is_stopped = false
	var clamped_x: float = clampf(x_pos, territory_min_x + 48.0, territory_max_x - 48.0)
	global_position = Vector2(clamped_x, surface_y)
	facing_direction = 1 if dir >= 0 else -1
	if pattern >= 0 and pattern <= MovementPattern.BAR_STRIKE:
		active_pattern = pattern as MovementPattern
		planned_pattern = active_pattern
	else:
		active_pattern = MovementPattern.GROUND_AMBUSH
		planned_pattern = active_pattern
	_configure_pattern_params(active_pattern)
	emerge_count += 1
	last_emerge_position = global_position
	_update_facing()
	_enter_crawling()


func force_submerge(wait_duration: float = 1.2, cancelled: bool = false) -> void:
	if cancelled:
		_enter_underground(wait_duration)
		retreat_cancelled.emit()
		return
	var submerge_pos := Vector2(clampf(global_position.x, territory_min_x + 32.0, territory_max_x - 32.0), surface_y)
	last_submerge_position = submerge_pos
	submerge_count += 1
	submerged.emit()
	submerged_at.emit(submerge_pos)
	_enter_underground(wait_duration)
