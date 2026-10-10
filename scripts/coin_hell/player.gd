extends CharacterBody2D

## Player controller for Coin Hell platforming.
## Features acceleration, deceleration, coyote time, and jump buffering.

signal player_died

@export var move_speed: float = 240.0
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -470.0
@export var gravity: float = 1150.0

# Coyote time & jump buffer
@export var coyote_time_duration: float = 0.12
@export var jump_buffer_duration: float = 0.12

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _is_alive: bool = true
var _input_disabled: bool = false

# Virtual touch input flags
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var touch_jump_just_pressed: bool = false
var touch_jump_just_released: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not _is_alive or _input_disabled:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	# Handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	else:
		_coyote_timer = coyote_time_duration
		if not _was_on_floor and velocity.y >= 0:
			AudioManager.play_sfx("land")

	_was_on_floor = is_on_floor()

	# Handle jump buffer timer
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	# Read input direction (keyboard or on-screen touch)
	var move_dir: float = 0.0
	if Input.is_action_pressed("move_left") or touch_left:
		move_dir -= 1.0
	if Input.is_action_pressed("move_right") or touch_right:
		move_dir += 1.0

	# Flip sprite facing
	if move_dir < 0.0:
		sprite.flip_h = true
	elif move_dir > 0.0:
		sprite.flip_h = false

	# Horizontal acceleration and friction
	if move_dir != 0.0:
		velocity.x = move_toward(velocity.x, move_dir * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Jump trigger check
	if Input.is_action_just_pressed("jump") or touch_jump_just_pressed:
		_jump_buffer_timer = jump_buffer_duration
		touch_jump_just_pressed = false

	# Execute jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		AudioManager.play_sfx("jump")

	# Variable jump height cut on early release
	if (Input.is_action_just_released("jump") or touch_jump_just_released) and velocity.y < -150.0:
		velocity.y = -150.0
	touch_jump_just_released = false

	move_and_slide()

func die() -> void:
	if not _is_alive:
		return
	_is_alive = false
	_input_disabled = true
	touch_left = false
	touch_right = false
	touch_jump = false
	touch_jump_just_pressed = false
	touch_jump_just_released = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	velocity = Vector2.ZERO
	# Small death hop
	velocity.y = -200.0
	player_died.emit()
	GameManager.trigger_player_death()

func disable_input() -> void:
	_input_disabled = true
	touch_left = false
	touch_right = false
	touch_jump = false
	touch_jump_just_pressed = false
	touch_jump_just_released = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	velocity.x = 0.0

func reset_to(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_is_alive = true
	_input_disabled = false
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	touch_left = false
	touch_right = false
	touch_jump = false
	touch_jump_just_pressed = false
	touch_jump_just_released = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	if sprite:
		sprite.flip_h = false
