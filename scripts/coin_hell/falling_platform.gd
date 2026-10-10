class_name FallingPlatform
extends StaticBody2D

## TRICK 1 — THE BETRAYING PLATFORM
## Looks like a normal platform, but starts shaking with a visual warning
## and "CRUMBLING!" toast when stepped on, then drops into the pit after 0.55s.
## Gives the player fair time to jump away, resets cleanly on retry.

signal triggered_fall

@export var shake_duration: float = 0.55
@export var fall_speed: float = 700.0

var _initial_pos: Vector2
var _triggered: bool = false
var _falling: bool = false
var _shake_timer: float = 0.0

@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var step_area: Area2D = $StepArea

var _initial_visual_pos: Vector2
var _warning_label: Label

func _ready() -> void:
	_initial_pos = global_position
	if visual_rect:
		_initial_visual_pos = visual_rect.position
	if step_area:
		step_area.body_entered.connect(_on_step_area_body_entered)
	GameManager.coins_reset.connect(reset)
	_setup_warning_label()

func _setup_warning_label() -> void:
	_warning_label = Label.new()
	_warning_label.text = "⚠️ CRUMBLING! ⚠️"
	_warning_label.add_theme_font_size_override("font_size", 14)
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
	_warning_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 1.0))
	_warning_label.add_theme_constant_override("outline_size", 4)
	_warning_label.position = Vector2(-54, -36)
	_warning_label.visible = false
	add_child(_warning_label)

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
	if _warning_label:
		_warning_label.visible = true

func _physics_process(delta: float) -> void:
	if _triggered and not _falling:
		_shake_timer -= delta
		# Violent shake animation
		if visual_rect:
			visual_rect.position.x = _initial_visual_pos.x + sin(_shake_timer * 60.0) * 5.0
			# Flash warning neon tint
			if int(_shake_timer * 20.0) % 2 == 0:
				modulate = Color(1.0, 0.5, 0.1, 1.0)
			else:
				modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		if _shake_timer <= 0.0:
			_falling = true
			if visual_rect:
				visual_rect.position = _initial_visual_pos
			collision_shape.disabled = true
			if _warning_label:
				_warning_label.visible = false

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
	if _warning_label:
		_warning_label.visible = false
