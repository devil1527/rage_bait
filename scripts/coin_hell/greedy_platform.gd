class_name GreedyPlatform
extends StaticBody2D

## TRICK 3 — THE GREEDY COIN
## Platform that supports a tempting coin (Coin 6).
## When the coin is collected or the player steps onto it, the platform
## slides down with a comedic drop and bold "GREEDY! 😈" popup, startling the player
## while safely lowering them to a recovery height to hop onto Ground 2.

signal triggered_drop

@export var drop_distance: float = 46.0
@export var coin_node: Area2D

var _initial_pos: Vector2
var _has_dropped: bool = false
var _toast_label: Label

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var step_area: Area2D = $StepArea

func _ready() -> void:
	_initial_pos = global_position
	GameManager.coins_reset.connect(reset)
	_setup_toast_label()
	if step_area:
		step_area.body_entered.connect(_on_step_entered)

func _on_step_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		trigger_greedy_drop()

func _setup_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.text = "GREEDY! 😈"
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.1))
	_toast_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 1.0))
	_toast_label.add_theme_constant_override("outline_size", 5)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.position = Vector2(-44, -36)
	_toast_label.visible = false
	add_child(_toast_label)

func trigger_greedy_drop() -> void:
	if _has_dropped:
		return
	_has_dropped = true
	triggered_drop.emit()
	AudioManager.play_sfx("warning")
	
	# Show funny label pop
	if _toast_label:
		_toast_label.visible = true
		_toast_label.scale = Vector2(1.5, 1.5)
		var label_tween := create_tween()
		label_tween.tween_property(_toast_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Smooth fast slide down
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", _initial_pos.y + drop_distance, 0.22)

func reset() -> void:
	_has_dropped = false
	global_position = _initial_pos
	if _toast_label:
		_toast_label.visible = false
