extends Area2D

## Exit Gate for Coin Hell. Stays locked until all 10 coins are collected.
## When unlocked, the stationary gate opens and allows the player to complete Level 1.

signal level_completed

@export var hidden_initially: bool = false

var _is_open: bool = false
var _completion_triggered: bool = false
var _initial_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var status_label: Label = $StatusLabel
@onready var toast_label: Label = $ToastLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var locked_texture: Texture2D = preload("res://assets/sprites/exit_locked.png")
var open_texture: Texture2D = preload("res://assets/sprites/exit_open.png")

func _ready() -> void:
	_initial_pos = global_position
	body_entered.connect(_on_body_entered)
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.coins_reset.connect(reset)
	_setup_labels()
	if hidden_initially:
		visible = false
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
	else:
		_update_visuals()
	if toast_label:
		toast_label.visible = false

func reveal() -> void:
	visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	unlock_gate()

func _setup_labels() -> void:
	if status_label:
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_outline_color", Color.BLACK)
		status_label.add_theme_constant_override("outline_size", 4)
	if toast_label:
		toast_label.add_theme_font_size_override("font_size", 14)
		toast_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		toast_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 1.0))
		toast_label.add_theme_constant_override("outline_size", 4)

func _on_coin_collected(current: int, total: int) -> void:
	if current >= total and not _is_open:
		unlock_gate()

func unlock_gate() -> void:
	_is_open = true
	_update_visuals()
	AudioManager.play_sfx("unlock")
	# Small bounce pulse when opening
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)

func _update_visuals() -> void:
	if _is_open:
		sprite.texture = open_texture
		status_label.text = "EXIT OPEN!"
		status_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	else:
		sprite.texture = locked_texture
		status_label.text = "COINS REQUIRED"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	if not _is_open:
		var remaining: int = GameManager.total_coins_required - GameManager.current_coins
		show_toast("Need %d more coin%s!" % [remaining, "" if remaining == 1 else "s"])
		AudioManager.play_sfx("warning")
	else:
		if not _completion_triggered:
			_completion_triggered = true
			AudioManager.play_sfx("unlock")
			level_completed.emit()
			GameManager.trigger_level_complete()

func show_toast(msg: String) -> void:
	if not toast_label:
		return
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): toast_label.visible = false)

func reset() -> void:
	_is_open = false
	_completion_triggered = false
	global_position = _initial_pos
	if toast_label:
		toast_label.visible = false
	if hidden_initially:
		visible = false
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
	else:
		_update_visuals()
