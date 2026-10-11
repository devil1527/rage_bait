class_name FakeSafePlatform
extends StaticBody2D

## TRICK B — THE FAKE SAFE LANDING
## A platform that appears completely safe and ordinary at a glance.
## Contains concealed pop-up spikes with NO visible red warnings or countdowns beforehand.
## When the player crosses the trigger point, the spikes emerge immediately with a
## fast, consistent pop-up animation and active collision.
## Resets cleanly on retry.

signal trap_triggered

var _initial_pos: Vector2
var _triggered: bool = false
var _active_spikes: bool = false

@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var spikes_area: Area2D = $SpikesArea
@onready var spikes_sprite: Sprite2D = $SpikesArea/Sprite2D
@onready var spikes_collision: CollisionShape2D = $SpikesArea/CollisionShape2D

func _ready() -> void:
	_initial_pos = global_position
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	if spikes_area:
		spikes_area.body_entered.connect(_on_spikes_body_entered)
	GameManager.coins_reset.connect(reset)
	_setup_initial_spikes_state()

func _setup_initial_spikes_state() -> void:
	_triggered = false
	_active_spikes = false
	if spikes_sprite:
		spikes_sprite.visible = false
		spikes_sprite.position.y = 12.0  # Fully concealed inside platform
		spikes_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0) # Standard hazard red once emerged
	if spikes_collision:
		spikes_collision.disabled = true

func _on_trigger_body_entered(body: Node2D) -> void:
	if not _triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger_trap()

func trigger_trap() -> void:
	if _triggered:
		return
	_triggered = true
	_active_spikes = true
	trap_triggered.emit()
	AudioManager.play_sfx("warning")
	
	# Immediate fast emergence animation (no pre-warning, no countdown)
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = 10.0
		var tween := create_tween()
		tween.tween_property(spikes_sprite, "position:y", -14.0, 0.05)
	
	if spikes_collision:
		spikes_collision.disabled = false
	
	# Check any body standing on the trap at emergence
	if spikes_area:
		for body in spikes_area.get_overlapping_bodies():
			_kill_player(body)

func _on_spikes_body_entered(body: Node2D) -> void:
	if _active_spikes:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func reset() -> void:
	_setup_initial_spikes_state()
