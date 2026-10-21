class_name RollingBoulder
extends Area2D

## Industrial Rolling Boulder / Molten Slag Sphere for World 3: Rage Factory
## Predictable, fair hazard for Phase B: The Boulder Run.
## Cycles between DORMANT -> WARNING (rumble + amber flash) -> ROLLING -> RESETTING.
## Completely resets position, state, rotation, and timers on player death/retry.

enum State { DORMANT, WARNING, ROLLING, RESETTING }

signal boulder_warning_started
signal boulder_started_rolling
signal boulder_finished_roll

@export var roll_speed: float = 160.0
@export var roll_direction: float = -1.0 # -1.0 = rolls left, 1.0 = rolls right
@export var roll_distance: float = 480.0
@export var warning_duration: float = 0.75
@export var dormant_duration: float = 0.5
@export var cycle_delay: float = 1.2
@export var boulder_radius: float = 18.0
@export var auto_start: bool = true
@export var initial_offset: float = 0.0

var current_state: State = State.DORMANT
var _state_timer: float = 0.0
var _distance_rolled: float = 0.0
var _rotation_angle: float = 0.0
var _initial_pos: Vector2 = Vector2.ZERO
var _rumble_offset: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 4 # Hazard layer
	collision_mask = 1  # Player layer
	_initial_pos = position

	_setup_collision()
	body_entered.connect(_on_body_entered)

	GameManager.coins_reset.connect(reset)
	GameManager.player_revived.connect(_on_player_revived)

	reset()

func _on_player_revived(_pos: Vector2) -> void:
	reset()

func _setup_collision() -> void:
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = boulder_radius
		collision_shape.shape = circle
		add_child(collision_shape)
	elif collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = boulder_radius

func _physics_process(delta: float) -> void:
	_state_timer -= delta

	match current_state:
		State.DORMANT:
			if _state_timer <= 0.0:
				_start_warning()

		State.WARNING:
			# Subtle warning rumble
			_rumble_offset = Vector2(sin(_state_timer * 60.0) * 2.0, 0.0)
			if _state_timer <= 0.0:
				_start_rolling()
			queue_redraw()

		State.ROLLING:
			_rumble_offset = Vector2.ZERO
			var step := roll_speed * delta
			position.x += step * roll_direction
			_distance_rolled += step
			_rotation_angle += (step / boulder_radius) * roll_direction

			# Active lethality check
			for body in get_overlapping_bodies():
				_kill_player(body)

			if _distance_rolled >= roll_distance:
				_finish_rolling()
			queue_redraw()

		State.RESETTING:
			if _state_timer <= 0.0:
				_reset_to_start()
				_start_warning()

func _start_warning() -> void:
	current_state = State.WARNING
	_state_timer = warning_duration
	boulder_warning_started.emit()
	AudioManager.play_sfx("warning")
	queue_redraw()

func _start_rolling() -> void:
	current_state = State.ROLLING
	_distance_rolled = 0.0
	boulder_started_rolling.emit()
	queue_redraw()

func _finish_rolling() -> void:
	current_state = State.RESETTING
	_state_timer = cycle_delay
	boulder_finished_roll.emit()
	queue_redraw()

func _reset_to_start() -> void:
	position = _initial_pos
	_distance_rolled = 0.0
	_rotation_angle = 0.0
	_rumble_offset = Vector2.ZERO
	current_state = State.DORMANT
	_state_timer = dormant_duration

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.ROLLING or current_state == State.WARNING:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func _draw() -> void:
	var center := _rumble_offset
	var r := boulder_radius

	# 1. Molten Heat Aura
	if current_state == State.ROLLING:
		draw_circle(center, r + 4.0, Color(1.0, 0.45, 0.1, 0.25))
	elif current_state == State.WARNING:
		var flash := fmod(_state_timer * 12.0, 1.0) < 0.5
		var aura_col := Color(1.0, 0.6, 0.15, 0.5) if flash else Color(0.8, 0.2, 0.1, 0.3)
		draw_circle(center, r + 5.0, aura_col)

	# 2. Outer Steel Hull
	draw_circle(center, r, Color(0.14, 0.15, 0.20, 1.0))

	# 3. Inner Molten Core
	draw_circle(center, r - 3.0, Color(0.85, 0.35, 0.12, 1.0))
	draw_circle(center, r - 7.0, Color(1.0, 0.65, 0.15, 1.0))

	# 4. Rotating Iron Spoke Ribs & Rivets
	var num_spokes := 4
	for i in range(num_spokes):
		var ang := _rotation_angle + (i * PI / 2.0)
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(center - dir * (r - 2.0), center + dir * (r - 2.0), Color(0.25, 0.28, 0.35, 1.0), 3.0)
		# Outer rivet head
		var rivet_pos := center + dir * (r - 4.5)
		draw_circle(rivet_pos, 2.0, Color(0.85, 0.85, 0.90, 0.9))

	# 5. Core Heat Center
	draw_circle(center, 4.0, Color(1.0, 0.9, 0.4, 1.0))

	# 6. Metallic Rim Border
	draw_arc(center, r, 0.0, TAU, 32, Color(0.40, 0.45, 0.55, 1.0), 2.0)

func reset() -> void:
	position = _initial_pos
	_distance_rolled = 0.0
	_rotation_angle = 0.0
	_rumble_offset = Vector2.ZERO
	current_state = State.DORMANT
	_state_timer = dormant_duration + initial_offset
	queue_redraw()
