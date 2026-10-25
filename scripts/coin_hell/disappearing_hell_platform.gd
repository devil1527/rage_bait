class_name DisappearingHellPlatform
extends StaticBody2D

## World 4 Disappearing Hell Platform.
## Appears as solid black obsidian stone with crimson runes.
## Shakes and crackles when touched (warning duration 0.75s), then collapses
## into the lava chasm and disables collision.
## Resets cleanly on retry and revive.

signal platform_triggered
signal platform_collapsed

@export var shake_duration: float = 0.50
@export var fall_speed: float = 750.0
@export var platform_size: Vector2 = Vector2(65.0, 20.0)

var _initial_pos: Vector2
var _triggered: bool = false
var _falling: bool = false
var _shake_timer: float = 0.0
var _initial_visual_pos: Vector2

@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var step_area: Area2D = $StepArea

func _ready() -> void:
	collision_layer = 2 # Terrain layer
	collision_mask = 0
	_initial_pos = global_position
	if visual_rect:
		_initial_visual_pos = visual_rect.position
		visual_rect.offset_left = -platform_size.x * 0.5
		visual_rect.offset_top = -platform_size.y * 0.5
		visual_rect.offset_right = platform_size.x * 0.5
		visual_rect.offset_bottom = platform_size.y * 0.5
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = platform_size
	if step_area:
		step_area.body_entered.connect(_on_step_area_body_entered)
		var step_col = step_area.get_node_or_null("CollisionShape2D")
		if step_col and step_col.shape is RectangleShape2D:
			(step_col.shape as RectangleShape2D).size = Vector2(platform_size.x - 6.0, 10.0)

	GameManager.coins_reset.connect(reset)
	GameManager.player_revived.connect(_on_player_revived)

func _on_player_revived(_pos: Vector2) -> void:
	reset()

func _on_step_area_body_entered(body: Node2D) -> void:
	if not _triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger()

func trigger() -> void:
	if _triggered:
		return
	_triggered = true
	_shake_timer = shake_duration
	AudioManager.play_sfx("warning")
	platform_triggered.emit()

func _physics_process(delta: float) -> void:
	if _triggered and not _falling:
		_shake_timer -= delta
		if visual_rect:
			visual_rect.position.x = _initial_visual_pos.x + sin(_shake_timer * 65.0) * 4.0
			# Flicker crimson warning
			if int(_shake_timer * 22.0) % 2 == 0:
				modulate = Color(1.0, 0.45, 0.45, 1.0)
			else:
				modulate = Color(1.0, 1.0, 1.0, 1.0)

		if _shake_timer <= 0.0:
			_falling = true
			if visual_rect:
				visual_rect.position = _initial_visual_pos
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
			platform_collapsed.emit()

	elif _falling:
		global_position.y += fall_speed * delta
		if global_position.y > _initial_pos.y + 50.0:
			modulate.a = maxf(0.0, modulate.a - delta * 3.5)

func reset() -> void:
	_triggered = false
	_falling = false
	_shake_timer = 0.0
	global_position = _initial_pos
	modulate = Color.WHITE
	if visual_rect:
		visual_rect.position = _initial_visual_pos
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
