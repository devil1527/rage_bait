class_name BulletBetrayalExtractionBeacon
extends Area2D

## Mission extraction goal beacon for Bullet Betrayal World 1 Level 1.
## Remains locked until all 10 required enemies are eliminated.
## Provides distinct red locked state and green unlocked extraction state.

signal extraction_reached
signal locked_interacted

@export var required_enemies: int = 10

var is_unlocked: bool = false
var _activated: bool = false
var _tween_glow: Tween = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var beacon_glow: ColorRect = $BeaconGlow
@onready var lock_barrier: ColorRect = get_node_or_null("LockBarrier")
@onready var status_label: Label = get_node_or_null("StatusLabel")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_locked_visuals()

func _set_locked_visuals() -> void:
	is_unlocked = false
	_activated = false
	if beacon_glow:
		beacon_glow.color = Color(1.0, 0.2, 0.2, 0.95)
	if lock_barrier:
		lock_barrier.visible = true
		lock_barrier.color = Color(1.0, 0.15, 0.2, 0.45)
	if status_label:
		status_label.text = "LOCKED [0/10]"
		status_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	_start_beacon_pulse()

func update_target_progress(current_kills: int, required_kills: int = 10) -> void:
	if is_unlocked:
		return
	if status_label:
		status_label.text = "LOCKED [%d/%d]" % [current_kills, required_kills]
	if current_kills >= required_kills:
		unlock()

func unlock() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	AudioManager.play_sfx("victory")
	
	if beacon_glow:
		beacon_glow.color = Color(0.1, 1.0, 0.45, 1.0)
	if lock_barrier:
		var tw := create_tween()
		tw.tween_property(lock_barrier, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): lock_barrier.visible = false)
	if status_label:
		status_label.text = "EXTRACTION OPEN"
		status_label.modulate = Color(0.2, 1.0, 0.5, 1.0)

	_start_beacon_pulse()

func _start_beacon_pulse() -> void:
	if not beacon_glow:
		return
	if _tween_glow and _tween_glow.is_valid():
		_tween_glow.kill()
	_tween_glow = create_tween().set_loops()
	_tween_glow.tween_property(beacon_glow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	_tween_glow.tween_property(beacon_glow, "modulate:a", 0.25, 0.35).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if not is_unlocked:
			AudioManager.play_sfx("warning")
			locked_interacted.emit()
			if status_label:
				var tw := create_tween()
				tw.tween_property(status_label, "scale", Vector2(1.2, 1.2), 0.08)
				tw.tween_property(status_label, "scale", Vector2.ONE, 0.08)
			return

		_activated = true
		AudioManager.play_sfx("victory")
		extraction_reached.emit()

func reset() -> void:
	_activated = false
	is_unlocked = false
	if lock_barrier:
		lock_barrier.modulate.a = 1.0
	_set_locked_visuals()
