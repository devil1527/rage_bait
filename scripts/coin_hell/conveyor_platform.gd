class_name ConveyorPlatform
extends AnimatableBody2D

## Factory Conveyor Platform for World 3: Rage Factory
## Uses Godot 4 constant_linear_velocity to push grounded CharacterBody2D players predictably.
## Supports optional warned direction reversal with visible LED warning beacons and SFX.
## Cleanly resets state, speed, timers, and visuals on level retry.

signal reversal_warning_started
signal direction_reversed

@export var belt_speed: float = 100.0
@export var can_reverse: bool = false
@export var reversal_time: float = 5.5
@export var warning_duration: float = 1.2
@export var reversed_speed: float = -110.0
@export var platform_size: Vector2 = Vector2(140.0, 24.0)

var _elapsed_time: float = 0.0
var _current_speed: float = 0.0
var _is_reversing_warning: bool = false
var _has_reversed: bool = false
var _warning_sound_played: bool = false
var _tread_offset: float = 0.0

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	sync_to_physics = false
	GameManager.coins_reset.connect(reset)
	_setup_collision()
	reset()

func _setup_collision() -> void:
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = platform_size
		collision_shape.shape = rect_shape
		add_child(collision_shape)
	elif collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = platform_size

	collision_layer = 2 # Terrain / platform layer
	collision_mask = 0

func _physics_process(delta: float) -> void:
	_elapsed_time += delta

	# Handle reversal sequence
	if can_reverse and not _has_reversed:
		var warn_trigger := reversal_time - warning_duration
		if _elapsed_time >= warn_trigger and not _is_reversing_warning:
			_is_reversing_warning = true
			reversal_warning_started.emit()
			if not _warning_sound_played:
				_warning_sound_played = true
				AudioManager.play_sfx("warning")

		if _elapsed_time >= reversal_time:
			_has_reversed = true
			_is_reversing_warning = false
			_current_speed = reversed_speed
			constant_linear_velocity = Vector2(_current_speed, 0.0)
			direction_reversed.emit()

	# Accumulate tread visual animation offset
	_tread_offset = fmod(_tread_offset + (_current_speed * delta), 16.0)
	queue_redraw()

func _draw() -> void:
	var half_w := platform_size.x * 0.5
	var half_h := platform_size.y * 0.5
	var rect := Rect2(-half_w, -half_h, platform_size.x, platform_size.y)

	# 1. Dark Industrial Chassis Background
	draw_rect(rect, Color(0.12, 0.14, 0.18, 1.0))

	# 2. Outer Steel Border
	draw_rect(rect, Color(0.28, 0.32, 0.40, 1.0), false, 2.0)

	# 3. Top Belt Surface
	var belt_h := 8.0
	var belt_rect := Rect2(-half_w + 2.0, -half_h + 2.0, platform_size.x - 4.0, belt_h)
	draw_rect(belt_rect, Color(0.06, 0.07, 0.09, 1.0))

	# 4. Animated Moving Tread Notches
	var tread_spacing := 16.0
	var tread_count := int(platform_size.x / tread_spacing) + 2
	var tread_start_x := -half_w + _tread_offset
	while tread_start_x > -half_w:
		tread_start_x -= tread_spacing

	for i in range(tread_count):
		var tx := tread_start_x + (i * tread_spacing)
		if tx >= -half_w + 4.0 and tx <= half_w - 6.0:
			var tread_color: Color
			if _is_reversing_warning:
				# Flashing warning yellow/orange
				tread_color = Color(1.0, 0.75, 0.1, 0.9) if fmod(_elapsed_time * 8.0, 1.0) < 0.5 else Color(0.4, 0.3, 0.05, 0.8)
			else:
				# Normal industrial amber tread notch
				tread_color = Color(0.85, 0.65, 0.15, 0.8) if _current_speed > 0 else Color(0.2, 0.7, 0.9, 0.8)
			draw_line(Vector2(tx, -half_h + 3.0), Vector2(tx + 4.0, -half_h + belt_h + 1.0), tread_color, 2.0)

	# 5. Side Hazard Stripes / Edge Markers
	var left_edge := Rect2(-half_w, -half_h, 8.0, platform_size.y)
	var right_edge := Rect2(half_w - 8.0, -half_h, 8.0, platform_size.y)
	draw_rect(left_edge, Color(0.20, 0.22, 0.28, 1.0))
	draw_rect(right_edge, Color(0.20, 0.22, 0.28, 1.0))

	# 6. Directional Status LED Beacons
	var led_color: Color
	if _is_reversing_warning:
		# Rapid flashing emergency beacon
		var flash := fmod(_elapsed_time * 10.0, 1.0) < 0.5
		led_color = Color(1.0, 0.2, 0.1, 1.0) if flash else Color(1.0, 0.85, 0.1, 1.0)
	elif _current_speed > 0:
		led_color = Color(0.2, 1.0, 0.5, 0.9) # Green / Right
	else:
		led_color = Color(0.2, 0.8, 1.0, 0.9) # Cyan / Left

	draw_circle(Vector2(-half_w + 5.0, half_h - 6.0), 3.0, led_color)
	draw_circle(Vector2(half_w - 5.0, half_h - 6.0), 3.0, led_color)

func reset() -> void:
	_elapsed_time = 0.0
	_is_reversing_warning = false
	_has_reversed = false
	_warning_sound_played = false
	_current_speed = belt_speed
	constant_linear_velocity = Vector2(_current_speed, 0.0)
	_tread_offset = 0.0
	queue_redraw()
