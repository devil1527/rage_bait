class_name BulletBetrayalPlayer
extends CharacterBody2D

## Player commando controller for Bullet Betrayal.
## Supports responsive horizontal locomotion, jump buffering, coyote time,
## variable jump height, simultaneous run-and-gun shooting, and ammo management.

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
@export var max_health: int = 3
@export var initial_ammo: int = 10
@export var max_ammo: int = 30
@export var fire_cooldown: float = 0.20

# State variables
var current_health: int = 3
var current_ammo: int = 10
var facing_direction: int = 1 # 1 = Right, -1 = Left
var is_alive: bool = true
var is_dead: bool:
	get: return not is_alive
var is_invulnerable: bool = false
var input_disabled: bool = false

# Internal timers
var _fire_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _anim_timer: float = 0.0
var _run_frame: int = 1
var _is_shooting_anim: bool = false
var _shoot_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle_pos: Marker2D = $MuzzlePos
@onready var hurtbox_col: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var muzzle_flash: ColorRect = $MuzzleFlash

var _tex_idle: Texture2D
var _tex_run1: Texture2D
var _tex_run2: Texture2D
var _tex_jump: Texture2D

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	current_ammo = initial_ammo
	
	_tex_idle = load("res://assets/sprites/bb_soldier_idle.png")
	_tex_run1 = load("res://assets/sprites/bb_soldier_run_1.png")
	_tex_run2 = load("res://assets/sprites/bb_soldier_run_2.png")
	_tex_jump = load("res://assets/sprites/bb_soldier_jump.png")
	
	if muzzle_flash:
		muzzle_flash.visible = false
		
	_update_facing()
	# Deferred initial signal emission so HUD can connect
	call_deferred("_emit_initial_stats")

func _emit_initial_stats() -> void:
	health_updated.emit(current_health, max_health)
	ammo_updated.emit(current_ammo, max_ammo)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Timers
	_fire_timer = maxf(0.0, _fire_timer - delta)
	_shoot_anim_timer = maxf(0.0, _shoot_anim_timer - delta)
	if _shoot_anim_timer <= 0.0:
		_is_shooting_anim = false

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	else:
		_coyote_timer = 0.10 # 100ms coyote time
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
	if Input.is_action_pressed("move_left"):
		move_input -= 1.0
	if Input.is_action_pressed("move_right"):
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
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = 0.12 # 120ms buffer

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_execute_jump()

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.52

	# Shoot input (can fire while moving, running, jumping)
	if Input.is_action_just_pressed("shoot") or (Input.is_action_pressed("shoot") and _fire_timer <= 0.0):
		if _fire_timer <= 0.0:
			_attempt_shoot()

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
		_is_shooting_anim = true
		_shoot_anim_timer = 0.12
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
	tween.tween_callback(func(): muzzle_flash.visible = false)

func _update_facing() -> void:
	if sprite:
		# Sprite faces right by default
		sprite.flip_h = (facing_direction < 0)
	if muzzle_pos:
		muzzle_pos.position.x = 20.0 * facing_direction
	if muzzle_flash:
		muzzle_flash.position.x = 22.0 * facing_direction if facing_direction > 0 else -28.0

func _update_animation(delta: float) -> void:
	if not sprite:
		return

	if not is_on_floor():
		sprite.texture = _tex_jump
	elif absf(velocity.x) > 15.0:
		_anim_timer += delta
		if _anim_timer >= 0.14:
			_anim_timer = 0.0
			_run_frame = 2 if _run_frame == 1 else 1
			sprite.texture = _tex_run2 if _run_frame == 2 else _tex_run1
	else:
		sprite.texture = _tex_idle

func add_ammo(amount: int) -> void:
	current_ammo = clampi(current_ammo + amount, 0, max_ammo)
	ammo_updated.emit(current_ammo, max_ammo)

func take_damage(amount: int = 1) -> void:
	if not is_alive or is_invulnerable:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_updated.emit(current_health, max_health)
	AudioManager.play_sfx("player_hit")

	if current_health <= 0:
		die()
	else:
		_start_invulnerability(1.2)
		# Slight recoil knockback
		velocity.x = -facing_direction * 140.0
		velocity.y = -180.0

func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	var tween := create_tween().set_loops(int(duration / 0.12))
	tween.tween_property(sprite, "modulate:a", 0.3, 0.06)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.06)
	
	var end_timer := get_tree().create_timer(duration)
	end_timer.timeout.connect(func():
		is_invulnerable = false
		if sprite:
			sprite.modulate.a = 1.0
	)

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
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.6), 0.1)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 8.0, 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)

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
		sprite.texture = _tex_idle
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", false)
	_emit_initial_stats()
