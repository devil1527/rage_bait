class_name BulletBetrayalDesertWorm
extends Node2D

## Subterranean Desert Sandworm hazard for Bullet Betrayal (World 2, Level 7).
## Lives beneath the sand surface, telegraphs emergence via a shaking sand mound
## and grit particles, bursts onto the surface to crawl within its dune territory,
## and dives back underground at varied intervals.
## Instant-kills the player on contact ONLY when surfaced (never while underground).
## Never spawns directly on top of the player and never gets permanently stuck.

signal emerged(pos: Vector2)
signal submerged
signal submerged_at(pos: Vector2)
signal player_killed_by_worm

enum WormState {
	UNDERGROUND,
	WARNING,
	EMERGING,
	CRAWLING,
	SUBMERGING
}

@export var territory_min_x: float = 520.0
@export var territory_max_x: float = 840.0
@export var surface_y: float = 400.0
@export var use_node_y_as_surface: bool = true
@export var crawl_speed: float = 84.0
@export var underground_time_min: float = 1.6
@export var underground_time_max: float = 3.4
@export var warning_duration: float = 0.78
@export var emerge_duration: float = 0.28
@export var crawl_time_min: float = 1.8
@export var crawl_time_max: float = 3.2
@export var submerge_duration: float = 0.30
@export var min_player_spawn_clearance: float = 72.0
@export var initial_delay: float = -1.0
@export var unpredictable_intervals: bool = false
@export var crawl_distance_min: float = 0.0
@export var crawl_distance_max: float = 0.0
@export var ambush_ahead_of_player: bool = false
@export var require_player_in_zone: bool = false
@export var trigger_range_x: float = 300.0
@export var ambush_lead_min: float = 95.0
@export var ambush_lead_max: float = 165.0
@export var unpredictable_crawl_turns: bool = false

var state: WormState = WormState.UNDERGROUND
var facing_direction: int = 1 # 1 = Right, -1 = Left
var last_submerge_position: Vector2 = Vector2.ZERO

var _state_timer: float = 1.5
var _anim_timer: float = 0.0
var _frame_idx: int = 1
var _warning_elapsed: float = 0.0
var _active_warning_duration: float = 0.78
var _emerge_progress: float = 0.0
var _last_emerge_x: float = -9999.0
var _crawl_distance_traveled: float = 0.0
var _crawl_distance_limit: float = 0.0
var _turn_check_timer: float = 0.0

const BODY_REST_Y: float = 23.0      # Inside BodyClip (-34..0), center at -11 above surface
const BODY_HIDDEN_Y: float = 45.0    # Clipped cleanly below surface line

@onready var sand_mound: Sprite2D = $SandMound
@onready var sand_particles: CPUParticles2D = get_node_or_null("SandParticles")
@onready var body_clip: Control = $BodyClip
@onready var worm_sprite: Sprite2D = $BodyClip/WormSprite
@onready var kill_zone: Area2D = $KillZone
@onready var kill_col: CollisionShape2D = $KillZone/CollisionShape2D

var _tex_crawl_1: Texture2D
var _tex_crawl_2: Texture2D


func _ready() -> void:
	add_to_group("desert_worms")
	add_to_group("hazards")

	if use_node_y_as_surface:
		surface_y = global_position.y
	else:
		global_position.y = surface_y

	if territory_max_x < territory_min_x + 48.0:
		territory_min_x = global_position.x - 100.0
		territory_max_x = global_position.x + 100.0

	_tex_crawl_1 = load("res://assets/sprites/bb_desert_worm_crawl_1.png")
	_tex_crawl_2 = load("res://assets/sprites/bb_desert_worm_crawl_2.png")

	if kill_zone:
		kill_zone.collision_layer = 4
		kill_zone.collision_mask = 1
		if not kill_zone.body_entered.is_connected(_on_kill_zone_body_entered):
			kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	var start_wait: float = initial_delay if initial_delay >= 0.0 else randf_range(0.5, underground_time_max)
	_enter_underground(start_wait)


func _physics_process(delta: float) -> void:
	# Always lock vertical anchor to intended desert floor
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
	if require_player_in_zone:
		var p := _get_active_player()
		if not p or ("is_alive" in p and not p.is_alive):
			return
		var territory_dist_x: float = 0.0
		if p.global_position.x < territory_min_x:
			territory_dist_x = territory_min_x - p.global_position.x
		elif p.global_position.x > territory_max_x:
			territory_dist_x = p.global_position.x - territory_max_x
		var dy: float = absf(p.global_position.y - (surface_y - 16.0))
		if territory_dist_x > trigger_range_x or dy > 180.0:
			_state_timer = minf(_state_timer, maxf(0.16, initial_delay if initial_delay >= 0.0 else 0.25))
			return

	_state_timer -= delta
	if _state_timer > 0.0:
		return

	var target_x: float = _pick_safe_emergence_x()
	if target_x < -9000.0:
		# Player currently occupies every valid point; wait briefly instead of spawning on them
		_state_timer = 0.32
		return

	_enter_warning(target_x)


func _process_warning(delta: float) -> void:
	_warning_elapsed += delta
	_state_timer -= delta

	# Quiver sand mound as visual rumble cue (faster pulse on tighter warnings)
	if sand_mound:
		var shake_freq: float = 46.0 * (0.78 / clampf(_active_warning_duration, 0.34, 1.0))
		sand_mound.position.x = sin(_warning_elapsed * shake_freq) * 2.5
		sand_mound.position.y = -7.5 + absf(cos(_warning_elapsed * 28.0)) * 1.2

	if _state_timer <= 0.0:
		# Final fairness check: never burst directly onto a player who ran atop the mound
		if _is_player_on_spot(global_position.x, 38.0):
			_enter_underground(0.45)
			return
		_enter_emerging()


func _process_emerging(delta: float) -> void:
	_emerge_progress = minf(1.0, _emerge_progress + delta / maxf(0.05, emerge_duration))
	if worm_sprite:
		worm_sprite.position.y = lerpf(BODY_HIDDEN_Y, BODY_REST_Y, _emerge_progress)

	# Activate hitbox only once visibly breaking through the sand
	if _emerge_progress >= 0.45:
		_set_hitbox_enabled(true)
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		_enter_crawling()


func _process_crawling(delta: float) -> void:
	_state_timer -= delta

	var left_bound: float = territory_min_x + 22.0
	var right_bound: float = territory_max_x - 22.0
	var step_x: float = facing_direction * crawl_speed * delta
	global_position.x += step_x
	_crawl_distance_traveled += absf(step_x)

	if global_position.x <= left_bound:
		global_position.x = left_bound
		facing_direction = 1
		_update_facing()
	elif global_position.x >= right_bound:
		global_position.x = right_bound
		facing_direction = -1
		_update_facing()
	elif unpredictable_crawl_turns:
		_turn_check_timer -= delta
		if _turn_check_timer <= 0.0:
			_turn_check_timer = randf_range(0.85, 1.55)
			if global_position.x > left_bound + 28.0 and global_position.x < right_bound - 28.0 and randf() < 0.65:
				facing_direction *= -1
				_update_facing()

	# Crawl frame animation & subtle undulation
	_anim_timer += delta
	if _anim_timer >= 0.14:
		_anim_timer = 0.0
		_frame_idx = 2 if _frame_idx == 1 else 1
		if worm_sprite:
			worm_sprite.texture = _tex_crawl_2 if _frame_idx == 2 else _tex_crawl_1
	if worm_sprite:
		var squash: float = sin(Time.get_ticks_msec() * 0.014) * 0.05
		worm_sprite.scale = Vector2(1.0 + squash, 1.0 - squash)

	_check_overlapping_player()

	if _state_timer <= 0.0 or (_crawl_distance_limit > 0.0 and _crawl_distance_traveled >= _crawl_distance_limit):
		_enter_submerging()


func _process_submerging(delta: float) -> void:
	_emerge_progress = minf(1.0, _emerge_progress + delta / maxf(0.05, submerge_duration))
	if worm_sprite:
		worm_sprite.position.y = lerpf(BODY_REST_Y, BODY_HIDDEN_Y, _emerge_progress)

	if _emerge_progress >= 0.45:
		_set_hitbox_enabled(false)
	else:
		_check_overlapping_player()

	if _emerge_progress >= 1.0:
		var submerge_pos := Vector2(global_position.x, surface_y)
		last_submerge_position = submerge_pos
		submerged.emit()
		submerged_at.emit(submerge_pos)
		_enter_underground(_next_underground_duration())


func _enter_underground(duration: float) -> void:
	state = WormState.UNDERGROUND
	_state_timer = maxf(0.25, duration)
	_set_hitbox_enabled(false)
	if sand_mound:
		sand_mound.visible = false
		sand_mound.position = Vector2(0, -8)
	if sand_particles:
		sand_particles.emitting = false
	if worm_sprite:
		worm_sprite.visible = false
		worm_sprite.position.y = BODY_HIDDEN_Y
		worm_sprite.scale = Vector2.ONE


func _enter_warning(emerge_x: float) -> void:
	state = WormState.WARNING
	_last_emerge_x = emerge_x
	global_position = Vector2(clampf(emerge_x, territory_min_x + 22.0, territory_max_x - 22.0), surface_y)
	_warning_elapsed = 0.0
	_active_warning_duration = clampf(warning_duration * randf_range(0.90, 1.15), 0.34, 1.10)
	_state_timer = _active_warning_duration
	_set_hitbox_enabled(false)
	if worm_sprite:
		worm_sprite.visible = false
		worm_sprite.position.y = BODY_HIDDEN_Y
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -8)
	if sand_particles:
		sand_particles.emitting = true


func _enter_emerging() -> void:
	state = WormState.EMERGING
	_emerge_progress = 0.0
	_set_hitbox_enabled(false)

	var p := _get_active_player()
	if p:
		facing_direction = 1 if p.global_position.x >= global_position.x else -1
	else:
		facing_direction = 1 if randf() > 0.5 else -1
	_update_facing()

	if worm_sprite:
		worm_sprite.visible = true
		worm_sprite.texture = _tex_crawl_1
		worm_sprite.position.y = BODY_HIDDEN_Y
		worm_sprite.scale = Vector2.ONE
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -8)
	if sand_particles:
		sand_particles.emitting = true
	emerged.emit(global_position)


func _enter_crawling() -> void:
	state = WormState.CRAWLING
	_state_timer = randf_range(crawl_time_min, crawl_time_max)
	_crawl_distance_traveled = 0.0
	if crawl_distance_max > 0.0:
		var d_min: float = maxf(32.0, crawl_distance_min)
		var d_max: float = maxf(d_min + 10.0, crawl_distance_max)
		_crawl_distance_limit = randf_range(d_min, d_max)
	else:
		_crawl_distance_limit = 0.0
	_turn_check_timer = randf_range(0.65, 1.35) if unpredictable_crawl_turns else 0.0
	_anim_timer = 0.0
	_set_hitbox_enabled(true)
	if worm_sprite:
		worm_sprite.visible = true
		worm_sprite.position.y = BODY_REST_Y
	if sand_mound:
		sand_mound.visible = false
	if sand_particles:
		sand_particles.emitting = false


func _enter_submerging() -> void:
	state = WormState.SUBMERGING
	_emerge_progress = 0.0
	if worm_sprite:
		worm_sprite.scale = Vector2.ONE
	if sand_mound:
		sand_mound.visible = true
		sand_mound.position = Vector2(0, -8)
	if sand_particles:
		sand_particles.emitting = true


func _update_facing() -> void:
	if worm_sprite:
		worm_sprite.flip_h = (facing_direction < 0)


func _set_hitbox_enabled(enabled: bool) -> void:
	if kill_zone:
		kill_zone.monitoring = enabled
		kill_zone.monitorable = enabled
	if kill_col:
		kill_col.disabled = not enabled


func _next_underground_duration() -> float:
	if not unpredictable_intervals:
		return randf_range(underground_time_min, underground_time_max)
	var span_low: float = lerpf(underground_time_min, underground_time_max, 0.35)
	var span_high: float = lerpf(underground_time_min, underground_time_max, 0.72)
	var roll: float = randf()
	if roll < 0.38:
		return randf_range(underground_time_min, span_low)
	elif roll < 0.72:
		return randf_range(span_low, span_high)
	return randf_range(span_high, underground_time_max)


func _pick_safe_emergence_x() -> float:
	var min_x: float = territory_min_x + 24.0
	var max_x: float = territory_max_x - 24.0
	if max_x <= min_x:
		var mid: float = (territory_min_x + territory_max_x) * 0.5
		return -9999.0 if _is_player_on_spot(mid, min_player_spawn_clearance) else mid

	if ambush_ahead_of_player:
		var p := _get_active_player()
		if p and (not ("is_alive" in p) or p.is_alive):
			var route_dir: int = 1
			if "velocity" in p and p.velocity.x < -12.0:
				route_dir = -1
			elif "facing_direction" in p and p.facing_direction != 0:
				route_dir = 1 if p.facing_direction > 0 else -1
			var lead_min: float = maxf(min_player_spawn_clearance + 16.0, ambush_lead_min)
			var lead_max: float = maxf(lead_min + 18.0, ambush_lead_max)
			var ambush_candidates: Array[float] = []
			for _j in range(10):
				var ahead_x: float = p.global_position.x + route_dir * randf_range(lead_min, lead_max)
				if ahead_x >= min_x and ahead_x <= max_x and not _is_player_on_spot(ahead_x, min_player_spawn_clearance):
					ambush_candidates.append(ahead_x)
			if not ambush_candidates.is_empty():
				return ambush_candidates[randi() % ambush_candidates.size()]

	var candidates: Array[float] = []
	for _i in range(14):
		var cand: float = randf_range(min_x, max_x)
		if not _is_player_on_spot(cand, min_player_spawn_clearance):
			candidates.append(cand)

	if not candidates.is_empty():
		# Avoid spawning at the exact same spot twice if alternatives exist
		if candidates.size() > 1 and _last_emerge_x > -9000.0:
			var varied: Array[float] = []
			for c in candidates:
				if absf(c - _last_emerge_x) >= 32.0:
					varied.append(c)
			if not varied.is_empty():
				return varied[randi() % varied.size()]
		return candidates[randi() % candidates.size()]

	# Deterministic sweep across territory in case random rolls missed a safe pocket
	var step: float = 20.0
	var x: float = min_x
	while x <= max_x:
		if not _is_player_on_spot(x, min_player_spawn_clearance):
			candidates.append(x)
		x += step
	if not candidates.is_empty():
		return candidates[randi() % candidates.size()]
	return -9999.0


func _is_player_on_spot(x_pos: float, clearance: float) -> bool:
	var p := _get_active_player()
	if not p:
		return false
	if "is_alive" in p and not p.is_alive:
		return false
	# Consider clearance primarily when player is near or above this sand level
	var dy: float = absf(p.global_position.y - (surface_y - 16.0))
	if dy > 140.0:
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
	var level_root: Node = get_parent().get_parent() if get_parent() else null
	var best: Node2D = null
	var best_dist: float = INF
	for node in tree.get_nodes_in_group("player"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var candidate := node as Node2D
		if level_root and level_root.is_ancestor_of(candidate):
			return candidate
		var d: float = absf(candidate.global_position.x - global_position.x)
		if d < best_dist:
			best_dist = d
			best = candidate
	return best


## Helper queries & controlled overrides for safe-position validation & unit tests
func is_emerged() -> bool:
	if state == WormState.CRAWLING:
		return true
	if state == WormState.EMERGING or state == WormState.SUBMERGING:
		return kill_zone != null and kill_zone.monitoring
	return false


func is_underground() -> bool:
	return state == WormState.UNDERGROUND


func force_emerge_at(x_pos: float, dir: int = 1) -> void:
	var clamped_x: float = clampf(x_pos, territory_min_x + 22.0, territory_max_x - 22.0)
	global_position = Vector2(clamped_x, surface_y)
	facing_direction = 1 if dir >= 0 else -1
	_update_facing()
	_enter_crawling()


func force_submerge(wait_duration: float = 1.8) -> void:
	_enter_underground(wait_duration)
