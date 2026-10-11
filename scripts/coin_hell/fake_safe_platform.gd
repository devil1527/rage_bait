class_name FakeSafePlatform
extends StaticBody2D

## TRICK B — THE FAKE SAFE LANDING
## A platform that appears safe at a glance, but contains concealed pop-up spikes.
## When stepped on, a subtle 0.35s visual telegraph (peeking spikes + sound)
## gives the player a brief reaction window to leap away.
## If the player lingers, the spikes snap up fully and impale them.
## Communicates purely through animation and sound — NO spoiling warning text.
## Resets cleanly on retry.

signal trap_triggered

@export var telegraph_duration: float = 0.35

var _initial_pos: Vector2
var _triggered: bool = false
var _active_spikes: bool = false
var _timer: float = 0.0

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
	_timer = 0.0
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = 10.0  # Fully retracted inside platform
		spikes_sprite.modulate = Color(1.0, 0.4, 0.4, 0.25) # Subtle suspicious tint
	if spikes_collision:
		spikes_collision.disabled = true

func _on_trigger_body_entered(body: Node2D) -> void:
	if not _triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger_trap()

func trigger_trap() -> void:
	if _triggered:
		return
	_triggered = true
	_timer = telegraph_duration
	trap_triggered.emit()
	AudioManager.play_sfx("warning")
	
	# Telegraph: spikes peek up slightly (halfway) with amber warning glow
	if spikes_sprite:
		var tween := create_tween()
		tween.tween_property(spikes_sprite, "position:y", 2.0, 0.08)
		spikes_sprite.modulate = Color(1.0, 0.8, 0.2, 1.0)

func _physics_process(delta: float) -> void:
	if _triggered and not _active_spikes:
		_timer -= delta
		if _timer <= 0.0:
			# Pop up fully!
			_active_spikes = true
			if spikes_sprite:
				var tween := create_tween()
				tween.tween_property(spikes_sprite, "position:y", -14.0, 0.06)
				spikes_sprite.modulate = Color(1.0, 0.15, 0.15, 1.0) # Danger red
			if spikes_collision:
				spikes_collision.disabled = false
			AudioManager.play_sfx("warning")
			
			# Check any body already standing on the spikes
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
