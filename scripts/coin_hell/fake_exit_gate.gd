class_name FakeExitGate
extends Area2D

## FINAL SURPRISE — FAKE EXIT
## Initially looks like the legitimate level exit door.
## When all coins are collected and the player approaches to exit,
## the fake door triggers a deceptive sequence: it drops into the ground,
## playing a warning sound and revealing that it was a fake decoy.
## Simultaneously reveals the REAL exit door nearby with an achievable final jump.
## Resets cleanly on level retry.

signal fake_exit_triggered

@export var real_exit_path: NodePath = NodePath("")
@export var drop_speed: float = 400.0

var _is_coins_ready: bool = false
var _has_tricked: bool = false
var _is_dropping: bool = false
var _initial_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var status_label: Label = $StatusLabel
@onready var toast_label: Label = $ToastLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var locked_texture: Texture2D = preload("res://assets/sprites/exit_locked.png")
var open_texture: Texture2D = preload("res://assets/sprites/exit_open.png")
var fake_texture: Texture2D = preload("res://assets/sprites/exit_fake.png")

func _ready() -> void:
	_initial_pos = global_position
	body_entered.connect(_on_body_entered)
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.coins_reset.connect(reset)
	_setup_labels()
	_update_visuals()
	if toast_label:
		toast_label.visible = false

func _setup_labels() -> void:
	if status_label:
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_outline_color", Color.BLACK)
		status_label.add_theme_constant_override("outline_size", 4)
	if toast_label:
		toast_label.add_theme_font_size_override("font_size", 13)
		toast_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
		toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
		toast_label.add_theme_constant_override("outline_size", 4)

func _on_coin_collected(current: int, total: int) -> void:
	if current >= total:
		_is_coins_ready = true
		_update_visuals()

func _update_visuals() -> void:
	if _has_tricked:
		sprite.texture = fake_texture
		status_label.text = "FAKED!"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.4))
	elif _is_coins_ready:
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

	if not _is_coins_ready:
		var remaining: int = GameManager.total_coins_required - GameManager.current_coins
		show_toast("Need %d more coin%s!" % [remaining, "" if remaining == 1 else "s"])
		AudioManager.play_sfx("warning")
		return

	if not _has_tricked:
		trigger_deception()

func trigger_deception() -> void:
	if _has_tricked:
		return
	_has_tricked = true
	_is_dropping = true
	AudioManager.play_sfx("warning")
	fake_exit_triggered.emit()
	
	sprite.texture = fake_texture
	status_label.text = "FAKED!"
	status_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.4))
	show_toast("DECIEVED! LOOK BEHIND YOU!")

	# Reveal real exit
	if real_exit_path != NodePath(""):
		var real_gate = get_node_or_null(real_exit_path)
		if real_gate:
			if real_gate.has_method("reveal"):
				real_gate.reveal()
			else:
				real_gate.visible = true
				if real_gate.has_method("unlock_gate"):
					real_gate.unlock_gate()

func _physics_process(delta: float) -> void:
	if _is_dropping:
		global_position.y += drop_speed * delta
		modulate.a = maxf(0.0, modulate.a - delta * 2.5)
		if global_position.y > _initial_pos.y + 70.0:
			_is_dropping = false
			if collision_shape:
				collision_shape.set_deferred("disabled", true)

func show_toast(msg: String) -> void:
	if not toast_label:
		return
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): toast_label.visible = false)

func reset() -> void:
	_is_coins_ready = false
	_has_tricked = false
	_is_dropping = false
	global_position = _initial_pos
	modulate = Color.WHITE
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if toast_label:
		toast_label.visible = false
	_update_visuals()
