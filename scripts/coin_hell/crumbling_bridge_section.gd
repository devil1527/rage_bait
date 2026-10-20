class_name CrumblingBridgeSection
extends StaticBody2D

## TRAP 1 — CRUMBLING BRIDGE
## Represents an individual section of a ruined crumbling bridge.
## When the player lands on or steps onto the section, it begins shaking and cracking,
## then collapses after a consistent delay. Optionally triggers adjacent sections sequentially.
## Disables collision completely upon collapse so no invisible surfaces remain.
## Resets cleanly on level retry.

signal section_triggered
signal section_collapsed

@export var collapse_delay: float = 0.45
@export var fall_speed: float = 750.0
@export var next_section_path: NodePath = NodePath("")
@export var next_section_cascade_delay: float = 0.15

var _initial_pos: Vector2
var _initial_visual_pos: Vector2
var _is_triggered: bool = false
var _is_falling: bool = false
var _timer: float = 0.0

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual_rect: NinePatchRect = get_node_or_null("NinePatchRect")
@onready var step_area: Area2D = get_node_or_null("StepArea")

func _ready() -> void:
	_initial_pos = global_position
	if visual_rect:
		_initial_visual_pos = visual_rect.position
	if step_area:
		step_area.body_entered.connect(_on_step_entered)
	GameManager.coins_reset.connect(reset)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(func(_pos): reset())

func _on_step_entered(body: Node2D) -> void:
	if not _is_triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger_collapse()

func trigger_collapse() -> void:
	if _is_triggered:
		return
	_is_triggered = true
	_timer = collapse_delay
	AudioManager.play_sfx("warning")
	section_triggered.emit()
	
	if next_section_path != NodePath(""):
		var next_node = get_node_or_null(next_section_path)
		if next_node and next_node.has_method("cascade_trigger"):
			next_node.cascade_trigger(next_section_cascade_delay)

func cascade_trigger(delay: float) -> void:
	if _is_triggered:
		return
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func():
		if not _is_triggered:
			trigger_collapse()
	)

func _physics_process(delta: float) -> void:
	if _is_triggered and not _is_falling:
		_timer -= delta
		# Violent shake & fissure glow
		if visual_rect:
			visual_rect.position.x = _initial_visual_pos.x + sin(_timer * 65.0) * 4.0
			if int(_timer * 20.0) % 2 == 0:
				modulate = Color(1.0, 0.7, 0.4, 1.0)
			else:
				modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		if _timer <= 0.0:
			_is_falling = true
			if visual_rect:
				visual_rect.position = _initial_visual_pos
			# Immediate collision removal to prevent invisible collision surfaces
			if collision_shape:
				collision_shape.disabled = true
			section_collapsed.emit()

	elif _is_falling:
		global_position.y += fall_speed * delta
		if global_position.y > _initial_pos.y + 50.0:
			modulate.a = maxf(0.0, modulate.a - delta * 4.0)

func reset() -> void:
	_is_triggered = false
	_is_falling = false
	_timer = 0.0
	global_position = _initial_pos
	modulate = Color.WHITE
	if visual_rect:
		visual_rect.position = _initial_visual_pos
	if collision_shape:
		collision_shape.disabled = false
