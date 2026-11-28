class_name BulletBetrayalPlayer
extends CharacterBody2D

## Player controller for Bullet Betrayal reusing the Coin Hell character.
## Adapted with firearm presentation, one-hit death mechanics, limited 10-round ammo,
## mobile touch controls, and authoritative revive support.

signal ammo_updated(current: int, max_amount: int)
signal health_updated(current: int, max_amount: int)
signal dry_fire
signal player_died

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet_betrayal/bb_bullet.tscn")

@export var move_speed: float = 230.0
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -460.0
@export var gravity: float = 1100.0
@export var max_health: int = 1
@export var initial_ammo: int = 10
@export var max_ammo: int = 30
@export var fire_cooldown: float = 0.20

# State variables
var current_health: int = 1
var current_ammo: int = 10
var facing_direction: int = 1 # 1 = Right, -1 = Left
var is_alive: bool = true
var is_dead: bool:
	get: return not is_alive
var is_invulnerable: bool = false
var input_disabled: bool = false
var is_on_ladder: bool = false
var ladder_climb_speed: float = 165.0
var _ladder_dismount_timer: float = 0.0
var is_hanging: bool = false
var current_hanging_bar: Node2D = null
var bar_traverse_speed: float = 205.0
var _overlapping_bars: Array[Node2D] = []
var _bar_regrab_timer: float = 0.0
var is_on_ice: bool = false
var _overlapping_ice_patches: Array[Node2D] = []

func _prune_invalid_ice_surfaces() -> void:
	for i in range(_overlapping_ice_patches.size() - 1, -1, -1):
		if not is_instance_valid(_overlapping_ice_patches[i]):
			_overlapping_ice_patches.remove_at(i)
	is_on_ice = not _overlapping_ice_patches.is_empty()

func is_actively_on_ice() -> bool:
	_prune_invalid_ice_surfaces()
	return is_on_ice and is_on_floor() and not is_hanging and not is_on_ladder

func register_ice_surface(surface: Node2D) -> void:
	_prune_invalid_ice_surfaces()
	if surface and is_instance_valid(surface) and not _overlapping_ice_patches.has(surface):
		_overlapping_ice_patches.append(surface)
	is_on_ice = not _overlapping_ice_patches.is_empty()

func has_ice_surface(surface: Node2D) -> bool:
	_prune_invalid_ice_surfaces()
	return surface != null and _overlapping_ice_patches.has(surface)

func unregister_ice_surface(surface: Node2D) -> void:
	_overlapping_ice_patches.erase(surface)
	_prune_invalid_ice_surfaces()

func clear_ice_surfaces() -> void:
	_overlapping_ice_patches.clear()
	is_on_ice = false

func set_on_ladder(on_ladder: bool) -> void:
	is_on_ladder = on_ladder
	if is_on_ladder:
		_coyote_timer = 0.14

func register_hanging_bar(bar: Node2D) -> void:
	if bar and not _overlapping_bars.has(bar):
		_overlapping_bars.append(bar)

func unregister_hanging_bar(bar: Node2D) -> void:
	_overlapping_bars.erase(bar)
	if bar == current_hanging_bar:
		release_hanging_bar(false, 0.14)

func try_grab_hanging_bar(bar: Node2D = null) -> bool:
	if not is_alive or input_disabled or is_hanging or is_on_ladder or _bar_regrab_timer > 0.0:
		return false
	var target: Node2D = bar
	if not target:
		for candidate in _overlapping_bars:
			if is_instance_valid(candidate):
				target = candidate
				break
	if not target or not is_instance_valid(target):
		return false
	is_hanging = true
	current_hanging_bar = target
	velocity.y = 0.0
	_coyote_timer = 0.0
	if target.has_method("get_hang_y"):
		global_position.y = float(target.call("get_hang_y"))
	if target.has_method("set_occupied"):
		target.call("set_occupied", true)
	return true

func release_hanging_bar(with_hop: bool = false, cooldown: float = 0.26) -> void:
	var prev_bar := current_hanging_bar
	is_hanging = false
	current_hanging_bar = null
	_bar_regrab_timer = maxf(_bar_regrab_timer, cooldown)
	if prev_bar and is_instance_valid(prev_bar) and prev_bar.has_method("set_occupied"):
		prev_bar.call("set_occupied", false)
	if with_hop:
		velocity.y = -360.0
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		AudioManager.play_sfx("jump")

# Virtual touch input flags (direct mobile touch binding)
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var touch_jump_just_pressed: bool = false
var touch_jump_just_released: bool = false
var touch_shoot: bool = false
var touch_shoot_just_pressed: bool = false

# Safe anchor & foothold tracking (Coin Hell architecture)
var _safe_anchors: Array[Vector2] = []
var _grounded_safety_timer: float = 0.0
var last_safe_position: Vector2 = Vector2.ZERO
var last_death_position: Vector2 = Vector2.ZERO
const MAX_SAFE_ANCHORS: int = 15
const MIN_ANCHOR_DISTANCE: float = 48.0

# Internal timers
var _fire_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invulnerability_timer: float = 0.0
var _run_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponSprite")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle_pos: Marker2D = $MuzzlePos
@onready var hurtbox_col: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var muzzle_flash: ColorRect = $MuzzleFlash

func _ready() -> void:
	add_to_group("player")
	if GameManager:
		GameManager.register_player(self)

	# Enhanced platforming stability on mobile touch
	floor_snap_length = 12.0
	floor_stop_on_slope = true

	current_health = max_health
	current_ammo = initial_ammo
	
	if muzzle_flash:
		muzzle_flash.visible = false
		
	_update_facing()
	call_deferred("_emit_initial_stats")
	_safe_anchors.clear()
	call_deferred("_record_initial_anchor")

func _emit_initial_stats() -> void:
	health_updated.emit(current_health, max_health)
	ammo_updated.emit(current_ammo, max_ammo)

func _physics_process(delta: float) -> void:
	# Invulnerability timer and flicker
	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false
			if sprite:
				sprite.modulate.a = 1.0
			if weapon_sprite:
				weapon_sprite.modulate.a = 1.0
		else:
			var alpha: float = 0.35 if int(_invulnerability_timer * 18.0) % 2 == 0 else 0.95
			if sprite:
				sprite.modulate.a = alpha
			if weapon_sprite:
				weapon_sprite.modulate.a = alpha

	if not is_alive:
		return

	# Timers
	_fire_timer = maxf(0.0, _fire_timer - delta)
	_bar_regrab_timer = maxf(0.0, _bar_regrab_timer - delta)

	if is_hanging and (not current_hanging_bar or not is_instance_valid(current_hanging_bar)):
		release_hanging_bar(false, 0.14)

	# Auto-grab overlapping overhead bar when airborne (unless deliberately dropping)
	if not is_hanging and not is_on_ladder and not is_on_floor() and _bar_regrab_timer <= 0.0 and not _overlapping_bars.is_empty():
		if not Input.is_action_pressed("ui_down") and not input_disabled:
			try_grab_hanging_bar()

	# Gravity
	if is_hanging:
		velocity.y = 0.0
		_coyote_timer = 0.0
		if current_hanging_bar and current_hanging_bar.has_method("get_hang_y"):
			global_position.y = float(current_hanging_bar.call("get_hang_y"))
	elif not is_on_floor():
		if is_on_ladder and _ladder_dismount_timer <= 0.0:
			# Gravity suspended while clinging to ladder rungs
			pass
		else:
			velocity.y += gravity * delta
			_coyote_timer = maxf(0.0, _coyote_timer - delta)
	else:
		_coyote_timer = 0.14 # 140ms coyote time
		velocity.y = 0.0

	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	_ladder_dismount_timer = maxf(0.0, _ladder_dismount_timer - delta)

	if not input_disabled:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()

	if is_hanging and current_hanging_bar and is_instance_valid(current_hanging_bar):
		if current_hanging_bar.has_method("get_min_x") and current_hanging_bar.has_method("get_max_x"):
			var min_x: float = float(current_hanging_bar.call("get_min_x"))
			var max_x: float = float(current_hanging_bar.call("get_max_x"))
			if global_position.x < min_x - 4.0 or global_position.x > max_x + 4.0:
				release_hanging_bar(false, 0.18)

	_check_and_record_safe_anchor(delta)
	_update_animation(delta)

func _handle_input(delta: float) -> void:
	# Horizontal locomotion
	var move_input := 0.0
	if Input.is_action_pressed("move_left") or touch_left:
		move_input -= 1.0
	if Input.is_action_pressed("move_right") or touch_right:
		move_input += 1.0

	if is_hanging:
		if move_input != 0.0:
			velocity.x = move_input * bar_traverse_speed
			var new_facing := int(sign(move_input))
			if new_facing != facing_direction and new_facing != 0:
				facing_direction = new_facing
				_update_facing()
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

		var want_release_down := Input.is_action_just_pressed("ui_down") or Input.is_action_pressed("ui_down")
		var want_jump_off := Input.is_action_just_pressed("jump") or touch_jump_just_pressed
		touch_jump_just_pressed = false
		touch_jump_just_released = false
		if want_release_down:
			release_hanging_bar(false, 0.28)
			velocity.y = 40.0
		elif want_jump_off:
			release_hanging_bar(true, 0.28)

		var is_shooting_hang := Input.is_action_just_pressed("shoot") or touch_shoot_just_pressed or Input.is_action_pressed("shoot") or touch_shoot
		touch_shoot_just_pressed = false
		if is_shooting_hang and _fire_timer <= 0.0:
			_attempt_shoot()
		return

	var on_ice_ground := is_actively_on_ice()
	var effective_accel := acceleration * 0.48 if on_ice_ground else acceleration
	var effective_friction := friction * 0.24 if on_ice_ground else friction

	if move_input != 0.0:
		velocity.x = move_toward(velocity.x, move_input * move_speed, effective_accel * delta)
		var new_facing := int(sign(move_input))
		if new_facing != facing_direction and new_facing != 0:
			facing_direction = new_facing
			_update_facing()
	else:
		velocity.x = move_toward(velocity.x, 0.0, effective_friction * delta)

	# Ladder vertical climbing
	if is_on_ladder and _ladder_dismount_timer <= 0.0:
		_coyote_timer = 0.14 # Maintain coyote time while on ladder
		var is_jump_trigger := Input.is_action_just_pressed("jump") or touch_jump_just_pressed
		var climb_up := (Input.is_action_pressed("jump") or touch_jump or Input.is_action_pressed("ui_up")) and not is_jump_trigger
		var climb_down := Input.is_action_pressed("ui_down")
		if climb_up:
			velocity.y = -ladder_climb_speed
		elif climb_down:
			velocity.y = ladder_climb_speed
		elif not is_on_floor():
			velocity.y = 0.0 # Cling firmly to rungs when idle

	# Jump input & buffering (ladder dismount or normal ground jump)
	if Input.is_action_just_pressed("jump") or touch_jump_just_pressed:
		_jump_buffer_timer = 0.12 # 120ms buffer
	touch_jump_just_pressed = false

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_execute_jump()

	# Variable jump height cut on early release (clamped to ensure clean mobile obstacle jumps)
	if (Input.is_action_just_released("jump") or touch_jump_just_released) and velocity.y < -160.0:
		velocity.y = -160.0
	touch_jump_just_released = false

	# Shoot input (can fire while moving, running, jumping)
	var is_shooting := Input.is_action_just_pressed("shoot") or touch_shoot_just_pressed or Input.is_action_pressed("shoot") or touch_shoot
	touch_shoot_just_pressed = false
	if is_shooting and _fire_timer <= 0.0:
		_attempt_shoot()

func reset_touch_inputs() -> void:
	touch_left = false
	touch_right = false
	touch_jump = false
	touch_jump_just_pressed = false
	touch_jump_just_released = false
	touch_shoot = false
	touch_shoot_just_pressed = false

func _execute_jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_ladder_dismount_timer = 0.28
	AudioManager.play_sfx("jump")

func _attempt_shoot() -> void:
	_fire_timer = fire_cooldown
	if current_ammo > 0:
		current_ammo -= 1
		ammo_updated.emit(current_ammo, max_ammo)
		_spawn_bullet()
		AudioManager.play_sfx("shoot")
		_show_muzzle_flash()
	else:
		# Dry fire (out of ammunition)
		AudioManager.play_sfx("dry_fire")
		dry_fire.emit()

func _spawn_bullet() -> void:
	if not BULLET_SCENE:
		return
	var bullet = BULLET_SCENE.instantiate()
	var spawn_pos: Vector2 = muzzle_pos.global_position if muzzle_pos else global_position
	get_parent().add_child(bullet)
	bullet.setup(Vector2(facing_direction, 0.0), spawn_pos)

func _show_muzzle_flash() -> void:
	if not muzzle_flash:
		return
	muzzle_flash.visible = true
	var tween := create_tween()
	tween.tween_interval(0.04)
	tween.tween_callback(func(): if muzzle_flash: muzzle_flash.visible = false)

func _update_facing() -> void:
	if sprite:
		sprite.flip_h = (facing_direction < 0)
	if weapon_sprite:
		weapon_sprite.position.x = 10.0 * facing_direction
		weapon_sprite.flip_h = (facing_direction < 0)
	if muzzle_pos:
		muzzle_pos.position.x = 18.0 * facing_direction
		muzzle_pos.position.y = 1.0
	if muzzle_flash:
		muzzle_flash.position.x = 18.0 if facing_direction > 0 else -26.0

func _update_animation(delta: float) -> void:
	if not sprite:
		return

	if not is_on_floor():
		sprite.scale = Vector2(0.95, 1.05)
	elif absf(velocity.x) > 15.0:
		_run_anim_timer += delta * 14.0
		var bob: float = sin(_run_anim_timer) * 0.06
		sprite.scale = Vector2(1.0 + bob, 1.0 - bob)
	else:
		_run_anim_timer = 0.0
		sprite.scale = Vector2.ONE

func add_ammo(amount: int) -> void:
	current_ammo = clampi(current_ammo + amount, 0, max_ammo)
	ammo_updated.emit(current_ammo, max_ammo)

## One-hit death system: any damage from bullets, fire, or hazards immediately kills the player
func take_damage(amount: int = 1) -> void:
	if not is_alive or is_invulnerable:
		return

	current_health = 0
	health_updated.emit(current_health, max_health)
	AudioManager.play_sfx("player_hit")
	die()

func die() -> void:
	if not is_alive:
		return
	release_hanging_bar(false, 0.0)
	clear_ice_surfaces()
	is_alive = false
	input_disabled = true
	velocity = Vector2.ZERO
	last_death_position = global_position
	_grounded_safety_timer = 0.0
	AudioManager.play_sfx("death")
	player_died.emit()

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", true)

	# Death visual animation
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.08)
	if weapon_sprite:
		tween.parallel().tween_property(weapon_sprite, "modulate:a", 0.0, 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.6), 0.1)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 8.0, 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)

## Authoritative revive method: restores 1 life and exactly 10 bullets
func revive(safe_position: Vector2 = Vector2.ZERO) -> void:
	release_hanging_bar(false, 0.0)
	clear_ice_surfaces()
	var target_pos: Vector2 = safe_position
	if target_pos == Vector2.ZERO:
		target_pos = get_safe_revive_position()
	if target_pos != Vector2.ZERO:
		global_position = target_pos
	is_alive = true
	input_disabled = false
	current_health = 1
	current_ammo = 10 # RESTORES EXACTLY 10 BULLETS PER COMBAT RULES
	velocity = Vector2.ZERO
	facing_direction = 1
	_update_facing()
	
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
		sprite.visible = true
	if weapon_sprite:
		weapon_sprite.modulate = Color.WHITE
		weapon_sprite.visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", false)

	reset_touch_inputs()
	apply_spawn_protection(1.5)
	health_updated.emit(current_health, max_health)
	ammo_updated.emit(current_ammo, max_ammo)

func apply_spawn_protection(duration: float = 1.5) -> void:
	is_invulnerable = true
	_invulnerability_timer = duration
	if sprite:
		sprite.visible = true
		sprite.modulate = Color.WHITE

func respawn(pos: Vector2) -> void:
	release_hanging_bar(false, 0.0)
	clear_ice_surfaces()
	global_position = pos
	is_alive = true
	input_disabled = false
	current_health = max_health
	current_ammo = initial_ammo
	velocity = Vector2.ZERO
	facing_direction = 1
	_update_facing()
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
		sprite.visible = true
	if weapon_sprite:
		weapon_sprite.modulate = Color.WHITE
		weapon_sprite.visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", false)
	reset_touch_inputs()
	_emit_initial_stats()


# =========================================================================
# SAFE-POSITION RESPAWN ARCHITECTURE (MATCHING COIN HELL BEHAVIOR)
# =========================================================================

func _record_initial_anchor() -> void:
	if is_position_safe_for_revive(global_position):
		record_safe_position(global_position)
	else:
		var ground_pos := Vector2(global_position.x, 394.0)
		if is_position_safe_for_revive(ground_pos):
			record_safe_position(ground_pos)

func _check_and_record_safe_anchor(delta: float) -> void:
	if not is_alive or input_disabled or is_invulnerable:
		_grounded_safety_timer = 0.0
		return

	# 1. Stably resting on floor (not airborne, bouncing, hanging or on ladder)
	if not is_on_floor() or absf(velocity.y) > 1.0 or is_on_ladder or is_hanging:
		_grounded_safety_timer = 0.0
		return

	# 2. Within legitimate level vertical bounds (Y between 50 and 430)
	if global_position.y > 430.0 or global_position.y < 50.0:
		_grounded_safety_timer = 0.0
		return

	# 3. Slide collision check: normal points upward (flat stable footing)
	var floor_is_flat := false
	for i in range(get_slide_collision_count()):
		var coll := get_slide_collision(i)
		if coll.get_normal().y < -0.7:
			floor_is_flat = true
			break

	if not floor_is_flat:
		_grounded_safety_timer = 0.0
		return

	# 4. Immediate hazard and enemy proximity clearance check
	if not _is_current_area_clear_of_hazards(global_position):
		_grounded_safety_timer = 0.0
		return

	# 5. Stability timer: must remain on safe ground continuously for >= 0.15s
	_grounded_safety_timer += delta
	if _grounded_safety_timer >= 0.15:
		_grounded_safety_timer = 0.0
		record_safe_position(global_position)

func record_safe_position(pos: Vector2) -> void:
	if pos.y > 430.0 or pos.y < 50.0:
		return
	if _safe_anchors.is_empty():
		_safe_anchors.append(pos)
		last_safe_position = pos
		return
	var last_pos: Vector2 = _safe_anchors.back()
	if pos.distance_to(last_pos) >= MIN_ANCHOR_DISTANCE:
		_safe_anchors.append(pos)
		last_safe_position = pos
		if _safe_anchors.size() > MAX_SAFE_ANCHORS:
			_safe_anchors.pop_front()

func _is_current_area_clear_of_hazards(pos: Vector2) -> bool:
	var tree := get_tree()
	if not tree:
		return true

	# Active un-triggered stationary landmines (safe threshold: 45px)
	var landmines := tree.get_nodes_in_group("landmines")
	for node in landmines:
		if is_instance_valid(node) and node is Node2D:
			var is_active := true
			if "_triggered" in node and node._triggered:
				is_active = false
			if is_active and node.global_position.distance_to(pos) < 45.0:
				return false

	# Active timed boss mines about to detonate (avoid reviving inside imminent blast)
	var boss_mines := tree.get_nodes_in_group("boss_mines")
	for node in boss_mines:
		if is_instance_valid(node) and node is Node2D:
			if node.has_method("is_fuse_active") and bool(node.call("is_fuse_active")):
				var rem: float = float(node.call("get_fuse_remaining")) if node.has_method("get_fuse_remaining") else 0.0
				var rad: float = float(node.get("blast_radius")) if "blast_radius" in node else 128.0
				if rem <= 2.6 and node.global_position.distance_to(pos) < rad + 12.0:
					return false

	# Active hunting mines (safe threshold: 65px)
	var hunting_mines := tree.get_nodes_in_group("hunting_mines")
	for node in hunting_mines:
		if is_instance_valid(node) and node is Node2D:
			var is_active := true
			if "_triggered" in node and node._triggered:
				is_active = false
			if is_active and node.global_position.distance_to(pos) < 65.0:
				return false

	# Active emerged desert sandworms (safe threshold: 65px)
	var worms := tree.get_nodes_in_group("desert_worms")
	for node in worms:
		if is_instance_valid(node) and node is Node2D:
			var is_active_worm := true
			if node.has_method("is_emerged"):
				is_active_worm = node.is_emerged()
			if is_active_worm and node.global_position.distance_to(pos) < 65.0:
				return false

	# Active / falling hanging icicles (horizontal drop-lane threshold: 38px)
	var icicles := tree.get_nodes_in_group("icicle_traps")
	for node in icicles:
		if is_instance_valid(node) and node is Node2D:
			var is_active_icicle := true
			if node.has_method("is_threat_active"):
				is_active_icicle = bool(node.call("is_threat_active"))
			if is_active_icicle and absf(node.global_position.x - pos.x) < 38.0 and node.global_position.y <= pos.y + 18.0:
				return false

	# Living enemy soldiers and explosive rushers (safe threshold: 50px)
	var enemies := tree.get_nodes_in_group("enemies")
	for node in enemies:
		if is_instance_valid(node) and node is Node2D:
			var is_alive_enemy := true
			if "is_dead" in node and node.is_dead:
				is_alive_enemy = false
			if is_alive_enemy and node.global_position.distance_to(pos) < 50.0:
				return false

	# Layer 4 Fire hazards
	if get_world_2d():
		var space := get_world_2d().direct_space_state
		var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if space and col and col.shape:
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = col.shape
			query.transform = Transform2D(0.0, pos + col.position)
			query.collision_mask = 4 # Hazard layer
			query.collide_with_areas = true
			query.collide_with_bodies = true
			var hits := space.intersect_shape(query, 1)
			if not hits.is_empty():
				return false

	return true

func is_position_safe_for_revive(pos: Vector2) -> bool:
	# Safeguard 1: Vertical and horizontal bounds check
	if pos.y > 430.0 or pos.y < 50.0:
		return false
	if pos.x < 50.0 or pos.x > 2860.0:
		return false

	var space := get_world_2d().direct_space_state if get_world_2d() else null
	if not space:
		return true

	var col_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col_shape or not col_shape.shape:
		return true

	# 1. Ground Support Raycast (40px downwards on solid terrain layer 2)
	var ray := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, 40), 2)
	var ground_hit: Dictionary = space.intersect_ray(ray)
	if ground_hit.is_empty():
		return false
	var ground_y: float = ground_hit.get("position", Vector2.ZERO).y
	if ground_y - pos.y < 10.0 or ground_y - pos.y > 28.0:
		return false

	# 2. Wall / Ceiling Clearance: verify body is not embedded in Layer 2 terrain
	var test_shape := RectangleShape2D.new()
	var base_shape := col_shape.shape as RectangleShape2D
	if base_shape:
		test_shape.size = base_shape.size - Vector2(2.0, 4.0)
	else:
		test_shape.size = Vector2(14.0, 24.0)

	var shape_query := PhysicsShapeQueryParameters2D.new()
	shape_query.shape = test_shape
	shape_query.transform = Transform2D(0.0, pos + col_shape.position - Vector2(0.0, 2.0))
	shape_query.collision_mask = 2 # Solid terrain
	shape_query.collide_with_areas = false
	shape_query.collide_with_bodies = true
	var wall_hits: Array[Dictionary] = space.intersect_shape(shape_query, 1)
	if not wall_hits.is_empty():
		return false

	# 3. Fire Hazard Check (Layer 4)
	shape_query.collision_mask = 4
	shape_query.collide_with_areas = true
	shape_query.collide_with_bodies = true
	var hazard_hits: Array[Dictionary] = space.intersect_shape(shape_query, 1)
	if not hazard_hits.is_empty():
		return false

	# 4. Hazard & Enemy Proximity Check
	return _is_current_area_clear_of_hazards(pos)

func get_safe_revive_position() -> Vector2:
	# Priority 1: Search backwards through safe anchor history (Coin Hell approach)
	for i in range(_safe_anchors.size() - 1, -1, -1):
		var candidate: Vector2 = _safe_anchors[i]
		if is_position_safe_for_revive(candidate):
			return candidate

	# Priority 2: Fallback to level SpawnPoint with full validation (Safeguard 3)
	var spawn_node: Node2D = null
	if get_parent():
		spawn_node = get_parent().get_node_or_null("SpawnPoint")

	if spawn_node:
		var spawn_pos: Vector2 = spawn_node.global_position
		if is_position_safe_for_revive(spawn_pos):
			return spawn_pos
		var ground_spawn := Vector2(spawn_pos.x, 394.0)
		if is_position_safe_for_revive(ground_spawn):
			return ground_spawn
		# Horizontal safe offsets along spawn runway
		for offset in [32.0, -32.0, 64.0, -64.0, 96.0]:
			var offset_pos := Vector2(spawn_pos.x + offset, 394.0)
			if is_position_safe_for_revive(offset_pos):
				return offset_pos

	# Fallback safe coordinate
	return Vector2(120.0, 394.0)
