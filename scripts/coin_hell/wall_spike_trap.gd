class_name WallSpikeTrap
extends Area2D

## TRAP 4 EXTENSION — MOVING WALL SPIKE TRAP
## Concealed floor spikes triggered when the player crosses/leaps over the moving wall.
## Appears completely seamless and safe before activation — no warning text or countdown.
## Rapidly emerges when triggered, challenging the player's expected landing route.
## Surviving requires reacting to land on the safe elevated ruin block or leaping over the hazard.
## Resets cleanly on level retry.

signal spikes_emerged

@export var trigger_area_path: NodePath = NodePath("")

var _is_triggered: bool = false
var _is_active: bool = false
var _initial_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_initial_pos = global_position
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	GameManager.coins_reset.connect(reset)
	
	if trigger_area_path != NodePath(""):
		var trigger = get_node_or_null(trigger_area_path)
		if trigger is Area2D:
			trigger.body_entered.connect(_on_trigger_entered)
			
	_setup_initial_state()

func _setup_initial_state() -> void:
	_is_triggered = false
	_is_active = false
	if sprite:
		sprite.visible = false
		sprite.position.y = 12.0 # Concealed below floor
	if collision_shape:
		collision_shape.disabled = true
		collision_shape.position.y = 12.0

func _on_trigger_entered(body: Node2D) -> void:
	if not _is_triggered and (body.is_in_group("player") or body.name == "Player"):
		activate_trap()

func activate_trap() -> void:
	if _is_triggered:
		return
	_is_triggered = true
	AudioManager.play_sfx("warning")
	
	# Rapid emergence animation
	if sprite:
		sprite.visible = true
		sprite.position.y = 10.0
		var tween := create_tween()
		tween.tween_property(sprite, "position:y", -10.0, 0.06)
		tween.tween_callback(func():
			_is_active = true
			if collision_shape:
				collision_shape.set_deferred("disabled", false)
				collision_shape.position.y = -10.0
			spikes_emerged.emit()
			# Check any player already in the emerging hitbox
			for b in get_overlapping_bodies():
				_kill_player(b)
		)

func _on_body_entered(body: Node2D) -> void:
	if _is_active:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func reset() -> void:
	_setup_initial_state()
	global_position = _initial_pos
