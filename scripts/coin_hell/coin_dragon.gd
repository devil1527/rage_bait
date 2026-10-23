class_name CoinDragon
extends CharacterBody2D

## World 4 Climactic Final Boss: THE COIN DRAGON
## A massive, golden infernal coin-beast commanding the sanctum of Stage 20 ("The Final Betrayal").
## Features:
## - Distinctive silhouette: coin-shaped embossed torso, obsidian horns, fiery eyes, claws, and spiked tail.
## - Active traversal AI: patrols platforms, pursues the player with grounded strides and leaping arcs.
## - Instant-kill hazard collision: contact with the dragon immediately slays the player.
## - Predictable 6-second coin release routine: halts, roars, and launches collectible coins across the arena.
## - Dramatic defeat sequence upon entrance into the unlocked Infernal Exit Gate.

enum State { IDLE, PURSUE, LEAP, RELEASE_COIN, RECOVERY, DEFEATED }

signal coin_release_started(index: int)
signal coin_released(spawn_pos: Vector2, index: int)
signal dragon_defeated

@export var move_speed: float = 160.0
@export var jump_velocity: float = -440.0
@export var gravity: float = 1150.0

var current_state: State = State.IDLE
var is_active: bool = false
var is_defeated: bool = false
var target_player: CharacterBody2D = null

# Patrol waypoints across the arena platforms
var arena_waypoints: Array[Vector2] = [
	Vector2(140.0, 440.0), # LeftGround
	Vector2(190.0, 365.0), # LeftStep
	Vector2(130.0, 290.0), # LeftMid
	Vector2(320.0, 240.0), # MidLeftPerch
	Vector2(480.0, 175.0), # CentralAltar
	Vector2(480.0, 420.0), # CenterBridge
	Vector2(640.0, 240.0), # MidRightPerch
	Vector2(830.0, 290.0), # RightMid
	Vector2(770.0, 365.0), # RightStep
	Vector2(820.0, 440.0)  # RightGround
]

var _current_waypoint_idx: int = 5
var _leap_cooldown: float = 0.0
var _state_timer: float = 0.0
var _pending_coin_idx: int = -1
var _coin_has_spawned_for_cycle: bool = false
var _initial_spawn_pos: Vector2 = Vector2.ZERO

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
	_initial_spawn_pos = global_position
	if hazard_area:
		hazard_area.body_entered.connect(_on_hazard_body_entered)
	_apply_texture(tex_idle)

func activate(player_ref: CharacterBody2D) -> void:
	target_player = player_ref
	is_active = true
	is_defeated = false
	current_state = State.PURSUE
	if hazard_shape:
		hazard_shape.set_deferred("disabled", false)
	if embers_particles:
		embers_particles.emitting = true

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

	_leap_cooldown = maxf(0.0, _leap_cooldown - delta)

	# Continuous proximity / overlap check to prevent tunneling
	_check_player_contact()

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_apply_texture(tex_idle)

		State.PURSUE:
			_process_pursue_state(delta)

		State.LEAP:
			# Airborne leap
			_apply_texture(tex_jump)
			if is_on_floor() and velocity.y >= 0.0:
				current_state = State.PURSUE
				_leap_cooldown = 1.0

		State.RELEASE_COIN:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_state_timer -= delta
			_apply_texture(tex_roar)

			# Spawn coin at 0.4s into roar
			if _state_timer <= 0.4 and not _coin_has_spawned_for_cycle:
				_coin_has_spawned_for_cycle = true
				coin_released.emit(get_snout_position(), _pending_coin_idx)

			if _state_timer <= 0.0:
				current_state = State.RECOVERY
				_state_timer = 0.4

		State.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_apply_texture(tex_idle)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.PURSUE

	move_and_slide()

func _process_pursue_state(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		velocity.x = 0.0
		return

	var p_pos: Vector2 = target_player.global_position
	var my_pos: Vector2 = global_position
	var dx: float = p_pos.x - my_pos.x
	var dy: float = p_pos.y - my_pos.y

	# Face movement / target direction
	var move_dir: float = signf(dx) if absf(dx) > 20.0 else 0.0

	# Jump conditions:
	# 1. Player is significantly higher and dragon is grounded
	# 2. Or dragon reaches a gap and needs to cross toward player
	if is_on_floor() and _leap_cooldown <= 0.0:
		if dy < -45.0: # Player is above on higher platform
			_execute_leap(jump_velocity, move_dir * move_speed)
			return
		elif absf(dx) > 120.0 and absf(dy) < 60.0:
			# Leap across wide horizontal gap between platforms
			if (my_pos.x < 300.0 and dx > 0.0) or (my_pos.x > 660.0 and dx < 0.0):
				_execute_leap(jump_velocity * 0.9, move_dir * move_speed * 1.1)
				return

	# Ground traversal
	velocity.x = move_toward(velocity.x, move_dir * move_speed, 900.0 * delta)

	# Visual update
	if not is_on_floor():
		_apply_texture(tex_jump)
	elif absf(velocity.x) > 15.0:
		_apply_texture(tex_walk)
		sprite.flip_h = velocity.x < 0.0
	else:
		_apply_texture(tex_idle)
		if absf(dx) > 10.0:
			sprite.flip_h = dx < 0.0

func _execute_leap(vy: float, vx: float) -> void:
	current_state = State.LEAP
	velocity.y = vy
	if absf(vx) > 0.0:
		velocity.x = vx
		sprite.flip_h = vx < 0.0
	_leap_cooldown = 1.2
	AudioManager.play_sfx("jump")

func trigger_coin_release(coin_idx: int, target_land_pos: Vector2) -> void:
	if is_defeated:
		return
	current_state = State.RELEASE_COIN
	_state_timer = 0.8
	_pending_coin_idx = coin_idx
	_coin_has_spawned_for_cycle = false
	velocity.x = 0.0

	# Face the target platform
	var dx = target_land_pos.x - global_position.x
	if absf(dx) > 5.0:
		sprite.flip_h = dx < 0.0

	_apply_texture(tex_roar)
	AudioManager.play_sfx("warning")
	coin_release_started.emit(coin_idx)

func get_snout_position() -> Vector2:
	var forward_x: float = -32.0 if sprite.flip_h else 32.0
	return global_position + Vector2(forward_x, -12.0)

func _check_player_contact() -> void:
	if is_defeated or not is_active:
		return
	if target_player and is_instance_valid(target_player):
		if target_player.has_method("die"):
			var dist = global_position.distance_to(target_player.global_position)
			# Generous, reliable circular buffer plus area intersection
			if dist < 48.0 or (hazard_area and hazard_area.overlaps_body(target_player)):
				target_player.die()

func _on_hazard_body_entered(body: Node2D) -> void:
	if is_defeated or not is_active:
		return
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("die"):
			body.die()

func defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	is_active = false
	current_state = State.DEFEATED
	velocity = Vector2.ZERO

	if hazard_shape:
		hazard_shape.set_deferred("disabled", true)
	if embers_particles:
		embers_particles.emitting = false
	if defeat_particles:
		defeat_particles.emitting = true

	# Defeat animation: dramatic gold/crimson flashes and dissolve
	_apply_texture(tex_roar)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 1.8, 0.4, 1.0), 0.2)
	tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.5, 0.2, 0.3, 0.8), 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func():
		dragon_defeated.emit()
		visible = false
	)

func reset_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	is_defeated = false
	is_active = true
	current_state = State.PURSUE
	visible = true
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	sprite.flip_h = false
	_apply_texture(tex_idle)
	_leap_cooldown = 0.5
	_coin_has_spawned_for_cycle = false

	if hazard_shape:
		hazard_shape.set_deferred("disabled", false)
	if embers_particles:
		embers_particles.emitting = true
	if defeat_particles:
		defeat_particles.emitting = false

func _apply_texture(tex: Texture2D) -> void:
	if sprite and tex and sprite.texture != tex:
		sprite.texture = tex
