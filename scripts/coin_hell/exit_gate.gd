extends Area2D

## Exit Gate for Coin Hell. Stays locked until all coins are collected.
## TRICK 4 — THE EXIT BETRAYAL: When the player first approaches the unlocked exit,
## it hops away with a funny "SIKE!" betrayal before permanently opening with
## "OKAY FINE, YOU WIN!" to complete the level.

signal level_completed
signal exit_betrayed

@export var betrayal_hop_distance: float = 110.0

var _is_open: bool = false
var _has_betrayed: bool = false
var _completion_triggered: bool = false
var _initial_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var status_label: Label = $StatusLabel
@onready var toast_label: Label = $ToastLabel

var locked_texture: Texture2D = preload("res://assets/sprites/exit_locked.png")
var open_texture: Texture2D = preload("res://assets/sprites/exit_open.png")

func _ready() -> void:
	_initial_pos = global_position
	body_entered.connect(_on_body_entered)
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.coins_reset.connect(reset)
	_update_visuals()
	toast_label.visible = false

func _process(_delta: float) -> void:
	if _is_open and not _has_betrayed and not _completion_triggered:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player_node: Node2D = players[0]
			# If player gets close to the gate, trigger the comedic betrayal hop
			if global_position.distance_to(player_node.global_position) < 85.0:
				trigger_exit_betrayal()

func _on_coin_collected(current: int, total: int) -> void:
	if current >= total and not _is_open:
		unlock_gate()

func unlock_gate() -> void:
	_is_open = true
	_update_visuals()
	AudioManager.play_sfx("unlock")
	# Small bounce tween when opening
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

func trigger_exit_betrayal() -> void:
	if _has_betrayed or not _is_open:
		return
	_has_betrayed = true
	exit_betrayed.emit()
	AudioManager.play_sfx("warning")
	show_toast("SIKE! NOT SO FAST! 😈")
	status_label.text = "OKAY FINE, YOU WIN!"
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	
	# Funny cartoony bounce-away tween
	var tween := create_tween()
	tween.tween_property(self, "global_position:y", _initial_pos.y - 28.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "global_position:x", _initial_pos.x + betrayal_hop_distance, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", _initial_pos.y, 0.13).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		AudioManager.play_sfx("unlock")
	)

func _update_visuals() -> void:
	if _is_open:
		sprite.texture = open_texture
		if _has_betrayed:
			status_label.text = "OKAY FINE, YOU WIN!"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		else:
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
		show_toast("You still need %d coin%s!" % [remaining, "" if remaining == 1 else "s"])
		AudioManager.play_sfx("warning")
	else:
		if not _has_betrayed:
			trigger_exit_betrayal()
			return
		
		if not _completion_triggered:
			_completion_triggered = true
			level_completed.emit()
			GameManager.trigger_level_complete()

func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): toast_label.visible = false)

func reset() -> void:
	_is_open = false
	_has_betrayed = false
	_completion_triggered = false
	global_position = _initial_pos
	toast_label.visible = false
	_update_visuals()
