class_name MovingWall
extends AnimatableBody2D

## TRAP 4 — MOVING WALL
## A ruined stone crusher monolith that moves horizontally across the player's path.
## Provides real physics collision (AnimatableBody2D) to block movement and push the player.
## Once triggered, it glides smoothly at a consistent frame-rate independent speed.
## The player can jump over it (height 60px < player 96px jump) or time their movement past it.
## Resets position and state cleanly on level retry.

signal wall_activated

@export var move_distance: float = 130.0
@export var move_speed: float = 95.0
@export var patrol: bool = true
@export var pause_at_ends: float = 0.6
@export var trigger_area_path: NodePath = NodePath("")

var _initial_pos: Vector2
var _is_active: bool = false
var _direction: float = -1.0 # Moves left towards player
var _travelled: float = 0.0
var _pause_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	sync_to_physics = false
	_initial_pos = position
	GameManager.coins_reset.connect(reset)
	
	if trigger_area_path != NodePath(""):
		var area = get_node_or_null(trigger_area_path)
		if area is Area2D:
			area.body_entered.connect(_on_trigger_body_entered)

func _on_trigger_body_entered(body: Node2D) -> void:
	if not _is_active and (body.is_in_group("player") or body.name == "Player"):
		activate()

func activate() -> void:
	if _is_active:
		return
	_is_active = true
	_direction = -1.0
	_travelled = 0.0
	_pause_timer = 0.0
	AudioManager.play_sfx("warning")
	wall_activated.emit()

func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	if _pause_timer > 0.0:
		_pause_timer -= delta
		return

	var step: float = move_speed * delta
	_travelled += step
	position.x += _direction * step

	if _travelled >= move_distance:
		if patrol:
			_direction *= -1.0
			_travelled = 0.0
			_pause_timer = pause_at_ends
		else:
			_is_active = false

func reset() -> void:
	_is_active = false
	_direction = -1.0
	_travelled = 0.0
	_pause_timer = 0.0
	position = _initial_pos
