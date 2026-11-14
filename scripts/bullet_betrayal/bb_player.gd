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

# Virtual touch input flags (direct mobile touch binding)
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var touch_jump_just_pressed: bool = false
var touch_jump_just_released: bool = false
var touch_shoot: bool = false
var touch_shoot_just_pressed: bool = false

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

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	else:
		_coyote_timer = 0.14 # 140ms coyote time
		velocity.y = 0.0

	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	if not input_disabled:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation(delta)

func _handle_input(delta: float) -> void:
	# Horizontal locomotion
	var move_input := 0.0
	if Input.is_action_pressed("move_left") or touch_left:
		move_input -= 1.0
	if Input.is_action_pressed("move_right") or touch_right:
		move_input += 1.0

	if move_input != 0.0:
		velocity.x = move_toward(velocity.x, move_input * move_speed, acceleration * delta)
		var new_facing := int(sign(move_input))
		if new_facing != facing_direction and new_facing != 0:
			facing_direction = new_facing
			_update_facing()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Jump input & buffering
	if Input.is_action_just_pressed("jump") or touch_jump_just_pressed:
		_jump_buffer_timer = 0.12 # 120ms buffer
	touch_jump_just_pressed = false

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_execute_jump()

	# Variable jump height cut on early release
	if (Input.is_action_just_released("jump") or touch_jump_just_released) and velocity.y < 0.0:
		velocity.y *= 0.52
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
	is_alive = false
	input_disabled = true
	velocity = Vector2.ZERO
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
	if safe_position != Vector2.ZERO:
		global_position = safe_position
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
