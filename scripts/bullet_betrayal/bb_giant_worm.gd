class_name BulletBetrayalGiantWorm
extends Node2D

## Giant Desert Sandworm Boss for Bullet Betrayal (World 2, Stage 10).
## Intimidating unkillable subterranean survival boss (~2.5x larger than regular worms).
## Alternates between subterranean stealth, readable emergence telegraphs,
## varied surface attack/patrol patterns, and burrowing underground to trigger
## armed enemy entries. Instant-kills the player on contact ONLY when surfaced.

signal emerged(pos: Vector2)
signal submerged
signal submerged_at(pos: Vector2)
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
	CHARGE_SWEEP = 0,
	STALK_REVERSE = 1,
	SURGE_DASH = 2
}

@export var territory_min_x: float = 64.0
@export var territory_max_x: float = 1216.0
@export var surface_y: float = 410.0
@export var use_node_y_as_surface: bool = true

@export var patrol_speed_min: float = 165.0
@export var patrol_speed_max: float = 205.0
@export var surge_speed_min: float = 210.0
@export var surge_speed_max: float = 242.0

@export var underground_time_min: float = 1.25
@export var underground_time_max: float = 2.45
@export var warning_duration: float = 0.85
@export var emerge_duration: float = 0.26
@export var crawl_time_min: float = 2.6
@export var crawl_time_max: float = 4.1
@export var submerge_duration: float = 0.34
@export var min_player_emerge_clearance: float = 112.0
@export var initial_delay: float = 0.90

var state: WormState = WormState.UNDERGROUND
var active_pattern: MovementPattern = MovementPattern.CHARGE_SWEEP
var current_speed: float = 180.0
var facing_direction: int = 1 # 1 = Right, -1 = Left
var last_emerge_position: Vector2 = Vector2.ZERO
var last_submerge_position: Vector2 = Vector2.ZERO
var direction_change_count: int = 0
var emerge_count: int = 0
var submerge_count: int = 0

var _state_timer: float = 0.90
var _active_warning_duration: float = 0.85
var _warning_elapsed: float = 0.0
var _emerge_progress: float = 0.0
var _anim_timer: float = 0.0
var _frame_idx: int = 1
var _last_emerge_x: float = -9999.0
var _turn_timer: float = 1.2
var _is_stopped: bool = false
var _pattern_history: Array[int] = []
var _turn_telegraph_timer: float = 0.0

const HEAD_REST_Y: float = 55.0
const HEAD_HIDDEN_Y: float = 114.0
const TORSO_REST_Y: float = 58.0
const TORSO_HIDDEN_Y: float = 116.0
const TAIL_REST_Y: float = 62.0
const TAIL_HIDDEN_Y: float = 118.0

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


func _physics_process(delta: float) -> void:
	if _is_stopped or state == WormState.STOPPED:
		return

	global_position.y = surface_y

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


func _process_underground(delta: float) -> void:
	_state_timer -= delta
	if _state_timer > 0.0:
		return

	var target_x: float = _pick_safe_emergence_x()
	if target_x < -9000.0:
		_state_timer = 0.28
		return

	_enter_warning(target_x)


func _process_warning(delta: float) -> void:
	_warning_elapsed += delta
	_state_timer -= delta

	var pulse: float = 0.55 + 0.45 * absf(sin(_warning_elapsed * 14.0))
	if sand_mound:
		sand_mound.position.x = sin(_warning_elapsed * 42.0) * 4.5
		sand_mound.position.y = -15.0 + absf(cos(_warning_elapsed * 26.0)) * 2.5
	if warning_fissure:
		warning_fissure.color.a = pulse * 0.85
	if warning_label:
		warning_label.modulate.a = 0.45 + 0.55 * pulse

	if _state_timer <= 0.0:
		# Final fairness check: if player stood directly over the mound, relocate safely
		if _is_player_near_x(global_position.x, 48.0):
			var alt_x: float = _pick_safe_emergence_x()
			if alt_x > -9000.0 and absf(alt_x - global_position.x) >= 60.0:
				_enter_warning(alt_x)
				return
			_enter_underground(0.55)
			return
		_enter_emerging()


func _process_emerging(delta: float) -> void:
	_emerge_progress = minf(1.0, _emerge_progress + delta / maxf(0.05, emerge_duration))
	_update_segment_positions(0.0)

	if head_sprite:
		head_sprite.position.y = lerpf(HEAD_HIDDEN_Y, HEAD_REST_Y, _emerge_progress)
	if torso_sprite:
		torso_sprite.position.y = lerpf(TORSO_HIDDEN_Y, TORSO_REST_Y, _emerge_progress)
	if tail_sprite:
		tail_sprite.position.y = lerpf(TAIL_HIDDEN_Y, TAIL_REST_Y, _emerge_progress)

	if _emerge_progress >= 0.45:
		_set_hitbox_enabled(true)
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		_enter_crawling()


func _process_crawling(delta: float) -> void:
	_state_timer -= delta

	var left_bound: float = territory_min_x + 48.0
	var right_bound: float = territory_max_x - 48.0

	# Brief pre-turn telegraph flash for STALK_REVERSE pattern
	if _turn_telegraph_timer > 0.0:
		_turn_telegraph_timer -= delta
		if _turn_telegraph_timer <= 0.0:
			facing_direction *= -1
			direction_change_count += 1
			_update_facing()
		_check_overlapping_player()
		_animate_crawl(delta * 0.5)
		return

	var step_x: float = facing_direction * current_speed * delta
	global_position.x += step_x

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
	elif active_pattern == MovementPattern.STALK_REVERSE:
		_turn_timer -= delta
		if _turn_timer <= 0.0:
			_turn_timer = randf_range(1.05, 1.75)
			if global_position.x > left_bound + 90.0 and global_position.x < right_bound - 90.0:
				var p := _get_active_player()
				var should_reverse := false
				if p and (p.global_position.x - global_position.x) * float(facing_direction) < -65.0:
					should_reverse = true
				elif randf() < 0.55:
					should_reverse = true
				if should_reverse:
					_turn_telegraph_timer = 0.16

	_animate_crawl(delta)
	_check_overlapping_player()

	if _state_timer <= 0.0:
		_enter_submerging()


func _process_submerging(delta: float) -> void:
	_emerge_progress = minf(1.0, _emerge_progress + delta / maxf(0.05, submerge_duration))
	_update_segment_positions(0.0)

	if head_sprite:
		head_sprite.position.y = lerpf(HEAD_REST_Y, HEAD_HIDDEN_Y, _emerge_progress)
	if torso_sprite:
		torso_sprite.position.y = lerpf(TORSO_REST_Y, TORSO_HIDDEN_Y, _emerge_progress)
	if tail_sprite:
		tail_sprite.position.y = lerpf(TAIL_REST_Y, TAIL_HIDDEN_Y, _emerge_progress)

	if _emerge_progress >= 0.45:
		_set_hitbox_enabled(false)
	else:
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		var submerge_pos := Vector2(global_position.x, surface_y)
		last_submerge_position = submerge_pos
		submerge_count += 1
		submerged.emit()
		submerged_at.emit(submerge_pos)
		_enter_underground(randf_range(underground_time_min, underground_time_max))


func _animate_crawl(delta: float) -> void:
	_anim_timer += delta
	var cycle_speed: float = 0.11 if active_pattern == MovementPattern.SURGE_DASH else 0.14
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

	var wave_t: float = Time.get_ticks_msec() * 0.012
	_update_segment_positions(wave_t)


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


func _enter_underground(duration: float) -> void:
	if _is_stopped:
		return
	state = WormState.UNDERGROUND
	_state_timer = maxf(0.25, duration)
	_set_hitbox_enabled(false)
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
	if head_sprite:
		head_sprite.position.y = HEAD_HIDDEN_Y
	if torso_sprite:
		torso_sprite.position.y = TORSO_HIDDEN_Y
	if tail_sprite:
		tail_sprite.position.y = TAIL_HIDDEN_Y


func _enter_warning(emerge_x: float) -> void:
	if _is_stopped:
		return
	state = WormState.WARNING
	var clamped_x: float = clampf(emerge_x, territory_min_x + 48.0, territory_max_x - 48.0)
	_last_emerge_x = clamped_x
	global_position = Vector2(clamped_x, surface_y)
	_warning_elapsed = 0.0
	_active_warning_duration = clampf(warning_duration * randf_range(0.92, 1.12), 0.65, 1.05)
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
	warning_started.emit(global_position)


func _enter_emerging() -> void:
	if _is_stopped:
		return
	state = WormState.EMERGING
	_emerge_progress = 0.0
	emerge_count += 1
	last_emerge_position = global_position
	_set_hitbox_enabled(false)

	var p := _get_active_player()
	if p:
		facing_direction = 1 if p.global_position.x >= global_position.x else -1
	else:
		facing_direction = 1 if global_position.x < (territory_min_x + territory_max_x) * 0.5 else -1

	_select_next_pattern()
	_update_facing()

	if head_sprite:
		head_sprite.visible = true
		head_sprite.texture = _tex_crawl_1
		head_sprite.position.y = HEAD_HIDDEN_Y
	if torso_sprite:
		torso_sprite.visible = true
		torso_sprite.texture = _tex_crawl_2
		torso_sprite.position.y = TORSO_HIDDEN_Y
	if tail_sprite:
		tail_sprite.visible = true
		tail_sprite.texture = _tex_crawl_1
		tail_sprite.position.y = TAIL_HIDDEN_Y
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	if sand_mound:
		sand_mound.visible = true
	if sand_particles:
		sand_particles.emitting = true

	AudioManager.play_sfx("explosion")
	emerged.emit(global_position)


func _enter_crawling() -> void:
	if _is_stopped:
		return
	state = WormState.CRAWLING
	_state_timer = randf_range(crawl_time_min, crawl_time_max)
	_turn_timer = randf_range(1.0, 1.65)
	_turn_telegraph_timer = 0.0
	_anim_timer = 0.0
	_set_hitbox_enabled(true)
	if head_sprite:
		head_sprite.visible = true
		head_sprite.position.y = HEAD_REST_Y
	if torso_sprite:
		torso_sprite.visible = true
		torso_sprite.position.y = TORSO_REST_Y
	if tail_sprite:
		tail_sprite.visible = true
		tail_sprite.position.y = TAIL_REST_Y
	if sand_mound:
		sand_mound.visible = false
	if sand_particles:
		sand_particles.emitting = false
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false
	_update_segment_positions(0.0)


func _enter_submerging() -> void:
	if _is_stopped:
		return
	state = WormState.SUBMERGING
	_emerge_progress = 0.0
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -15)
	if sand_particles:
		sand_particles.emitting = true
	if warning_fissure:
		warning_fissure.visible = false
	if warning_label:
		warning_label.visible = false


func _select_next_pattern() -> void:
	var options: Array[int] = [
		MovementPattern.CHARGE_SWEEP,
		MovementPattern.STALK_REVERSE,
		MovementPattern.SURGE_DASH
	]
	if not _pattern_history.is_empty():
		options.erase(_pattern_history.back())
	var chosen: int = options[randi() % options.size()]
	active_pattern = chosen as MovementPattern
	_pattern_history.append(chosen)
	if _pattern_history.size() > 6:
		_pattern_history.pop_front()

	match active_pattern:
		MovementPattern.SURGE_DASH:
			current_speed = randf_range(surge_speed_min, surge_speed_max)
			if head_sprite:
				head_sprite.modulate = Color(1.22, 0.62, 0.48, 1.0)
			if torso_sprite:
				torso_sprite.modulate = Color(1.15, 0.60, 0.46, 1.0)
		_:
			current_speed = randf_range(patrol_speed_min, patrol_speed_max)
			if head_sprite:
				head_sprite.modulate = Color(1.08, 0.78, 0.62, 1.0)
			if torso_sprite:
				torso_sprite.modulate = Color(1.02, 0.74, 0.58, 1.0)


func _update_facing() -> void:
	var flip: bool = (facing_direction < 0)
	if head_sprite:
		head_sprite.flip_h = flip
	if torso_sprite:
		torso_sprite.flip_h = flip
	if tail_sprite:
		tail_sprite.flip_h = flip
	if kill_col:
		kill_col.position.x = -float(facing_direction) * 12.0


func _set_hitbox_enabled(enabled: bool) -> void:
	if kill_zone:
		kill_zone.monitoring = enabled
		kill_zone.monitorable = enabled
	if kill_col:
		kill_col.disabled = not enabled


func _pick_safe_emergence_x() -> float:
	var min_x: float = territory_min_x + 56.0
	var max_x: float = territory_max_x - 56.0
	var candidates: Array[float] = []

	for _i in range(20):
		var cand: float = randf_range(min_x, max_x)
		if _is_player_near_x(cand, min_player_emerge_clearance):
			continue
		if _last_emerge_x > -9000.0 and absf(cand - _last_emerge_x) < 150.0:
			continue
		candidates.append(cand)

	if not candidates.is_empty():
		return candidates[randi() % candidates.size()]

	# Deterministic sweep fallback across the colosseum floor
	var x: float = min_x
	while x <= max_x:
		if not _is_player_near_x(x, min_player_emerge_clearance):
			candidates.append(x)
		x += 48.0

	if not candidates.is_empty():
		return candidates[randi() % candidates.size()]
	return -9999.0


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


## Coordination & verification helpers
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
	if state == WormState.CRAWLING and _state_timer > max_remaining_crawl:
		_state_timer = max_remaining_crawl


func stop_encounter() -> void:
	_is_stopped = true
	state = WormState.STOPPED
	_set_hitbox_enabled(false)
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
	if pattern >= 0 and pattern <= MovementPattern.SURGE_DASH:
		active_pattern = pattern as MovementPattern
		current_speed = randf_range(surge_speed_min, surge_speed_max) if active_pattern == MovementPattern.SURGE_DASH else randf_range(patrol_speed_min, patrol_speed_max)
	else:
		_select_next_pattern()
	emerge_count += 1
	last_emerge_position = global_position
	_update_facing()
	_enter_crawling()


func force_submerge(wait_duration: float = 1.6) -> void:
	var submerge_pos := Vector2(global_position.x, surface_y)
	last_submerge_position = submerge_pos
	submerge_count += 1
	submerged.emit()
	submerged_at.emit(submerge_pos)
	_enter_underground(wait_duration)
