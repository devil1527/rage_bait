class_name MovingPlatform
extends AnimatableBody2D

## MovingPlatform: Industrial mechanical platform for Coin Hell Level 11.
## Moves predictably along a configured vector path (e.g. horizontal or vertical).
## Synchronized to physics so CharacterBody2D player rides smoothly.
## Features distinct industrial visual styling and clean reset on level retry.

@export var move_direction: Vector2 = Vector2.RIGHT
@export var move_distance: float = 120.0
@export var move_speed: float = 80.0
@export var pause_at_ends: float = 0.5
@export var platform_size: Vector2 = Vector2(70.0, 20.0)

var _initial_pos: Vector2
var _travelled: float = 0.0
var _direction_sign: float = 1.0
var _pause_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: NinePatchRect = $NinePatchRect

func _ready() -> void:
	_initial_pos = position
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	_setup_geometry()
	GameManager.coins_reset.connect(reset)

func _setup_geometry() -> void:
	if collision_shape:
		var rect := RectangleShape2D.new()
		rect.size = platform_size
		collision_shape.shape = rect

	if visual_rect:
		visual_rect.offset_left = -platform_size.x * 0.5
		visual_rect.offset_right = platform_size.x * 0.5
		visual_rect.offset_top = -platform_size.y * 0.5
		visual_rect.offset_bottom = platform_size.y * 0.5

func _physics_process(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		return

	var dir_norm := move_direction.normalized()
	var step: float = move_speed * delta
	_travelled += step
	position += dir_norm * (_direction_sign * step)

	if _travelled >= move_distance:
		_direction_sign *= -1.0
		_travelled = 0.0
		_pause_timer = pause_at_ends

func reset() -> void:
	position = _initial_pos
	_travelled = 0.0
	_direction_sign = 1.0
	_pause_timer = 0.0
