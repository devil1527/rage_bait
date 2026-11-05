class_name BulletBetrayalExtractionBeacon
extends Area2D

## Mission extraction goal beacon for Bullet Betrayal World 1 Level 1.

signal extraction_reached

var _activated: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var beacon_glow: ColorRect = $BeaconGlow

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_beacon_pulse()

func _start_beacon_pulse() -> void:
	if not beacon_glow:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(beacon_glow, "modulate:a", 0.9, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(beacon_glow, "modulate:a", 0.2, 0.45).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		_activated = true
		AudioManager.play_sfx("victory")
		extraction_reached.emit()

func reset() -> void:
	_activated = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
