class_name FallingPlatform
extends StaticBody2D

## TRICK A — THE BETRAYING PLATFORM
## Looks like an ordinary platform, but starts shaking and flashing
## when stepped on, then drops into the pit after a short delay (0.50s).
## Communicates purely through animation and sound — NO spoiling warning text.
## Resets cleanly on retry.

signal triggered_fall

@export var shake_duration: float = 0.50
@export var fall_speed: float = 700.0

var _initial_pos: Vector2
var _triggered: bool = false
var _falling: bool = false
var _shake_timer: float = 0.0

@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var step_area: Area2D = $StepArea

var _initial_visual_pos: Vector2

func _ready() -> void:
	_initial_pos = global_position
	if visual_rect:
		_initial_visual_pos = visual_rect.position
	if step_area:
		step_area.body_entered.connect(_on_step_area_body_entered)
	GameManager.coins_reset.connect(reset)

func _on_step_area_body_entered(body: Node2D) -> void:
	if not _triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger()

func trigger() -> void:
	if _triggered:
		return
	_triggered = true
	_shake_timer = shake_duration
	AudioManager.play_sfx("warning")
	triggered_fall.emit()

func _physics_process(delta: float) -> void:
	if _triggered and not _falling:
		_shake_timer -= delta
		# Violent shake animation with subtle warning flash
		if visual_rect:
			visual_rect.position.x = _initial_visual_pos.x + sin(_shake_timer * 60.0) * 4.5
			if int(_shake_timer * 20.0) % 2 == 0:
				modulate = Color(1.0, 0.65, 0.25, 1.0)
			else:
				modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		if _shake_timer <= 0.0:
			_falling = true
			if visual_rect:
				visual_rect.position = _initial_visual_pos
			collision_shape.disabled = true

	elif _falling:
		global_position.y += fall_speed * delta
		if global_position.y > _initial_pos.y + 60.0:
			modulate.a = maxf(0.0, modulate.a - delta * 3.5)

func reset() -> void:
	_triggered = false
	_falling = false
	_shake_timer = 0.0
	global_position = _initial_pos
	modulate = Color.WHITE
	if visual_rect:
		visual_rect.position = _initial_visual_pos
	collision_shape.disabled = false
