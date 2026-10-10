extends Area2D

## Coin entity with retro bobbing animation and optional gentle surprise hop for the final coin.

@export var is_surprise_coin: bool = false

var _collected: bool = false
var _initial_pos: Vector2
var _time_passed: float = 0.0
var _has_surprised: bool = false
var _surprise_target_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_initial_pos = global_position
	body_entered.connect(_on_body_entered)
	GameManager.coins_reset.connect(reset)

func _process(delta: float) -> void:
	if _collected:
		return

	_time_passed += delta
	# Floating bobbing animation
	var bob_offset: float = sin(_time_passed * 5.0) * 3.0
	
	if _has_surprised and global_position.distance_to(_surprise_target_pos) > 1.0:
		global_position = global_position.move_toward(_surprise_target_pos, delta * 180.0)
		sprite.position.y = bob_offset
	else:
		sprite.position.y = bob_offset

	# Gentle surprise mechanic: hops away once when player gets close
	if is_surprise_coin and not _has_surprised and not _collected:
		var players: Array = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player_node: Node2D = players[0]
			if global_position.distance_to(player_node.global_position) < 75.0:
				_trigger_surprise_hop()

func _trigger_surprise_hop() -> void:
	_has_surprised = true
	AudioManager.play_sfx("warning")
	# Hop 50px further right and 20px up onto a safe spot
	_surprise_target_pos = _initial_pos + Vector2(60, -20)
	# Quick tween scale pop
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player") or body.name == "Player":
		collect()

func collect() -> void:
	if _collected:
		return
	_collected = true
	collision_shape.set_deferred("disabled", true)
	
	# Play collection sparkle tween then hide
	var tween := create_tween()
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y - 24.0, 0.2)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	
	GameManager.collect_coin()

func reset() -> void:
	_collected = false
	_has_surprised = false
	global_position = _initial_pos
	visible = true
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE
	sprite.modulate.a = 1.0
	collision_shape.set_deferred("disabled", false)
