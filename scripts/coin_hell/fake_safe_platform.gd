class_name FakeSafePlatform
extends StaticBody2D

## TRICK 2 — THE FAKE SAFE LANDING
## A platform that appears safe at a glance, but features concealed pop-up spikes.
## When the player lands on it (or approaches), a 0.40s visual telegraph
## (peeking spikes + warning flash + "WATCH OUT!" popup + sound) gives the player time to leap away.
## If the player lingers, the spikes pop up fully and catch them.
## Resets cleanly on level retry.

signal trap_triggered

@export var telegraph_duration: float = 0.40

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

var _warning_label: Label

func _ready() -> void:
	_initial_pos = global_position
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	if spikes_area:
		spikes_area.body_entered.connect(_on_spikes_body_entered)
	GameManager.coins_reset.connect(reset)
	_setup_warning_label()
	_setup_initial_spikes_state()

func _setup_warning_label() -> void:
	_warning_label = Label.new()
	_warning_label.text = "⚠️ WATCH OUT! ⚠️"
	_warning_label.add_theme_font_size_override("font_size", 14)
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_warning_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 1.0))
	_warning_label.add_theme_constant_override("outline_size", 4)
	_warning_label.position = Vector2(-54, -36)
	_warning_label.visible = false
	add_child(_warning_label)

func _setup_initial_spikes_state() -> void:
	_triggered = false
	_active_spikes = false
	_timer = 0.0
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = 10.0  # Fully retracted inside platform
		spikes_sprite.modulate = Color(1.0, 0.4, 0.4, 0.3) # Subtle tell
	if spikes_collision:
		spikes_collision.disabled = true
	if _warning_label:
		_warning_label.visible = false

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
	
	if _warning_label:
		_warning_label.visible = true
	
	# Telegraph: spikes peek up halfway and glow bright yellow/orange
	if spikes_sprite:
		var tween := create_tween()
		tween.tween_property(spikes_sprite, "position:y", 0.0, 0.1)
		spikes_sprite.modulate = Color(1.0, 0.85, 0.1, 1.0)

func _physics_process(delta: float) -> void:
	if _triggered and not _active_spikes:
		_timer -= delta
		if _timer <= 0.0:
			# Pop up fully!
			_active_spikes = true
			if spikes_sprite:
				var tween := create_tween()
				tween.tween_property(spikes_sprite, "position:y", -14.0, 0.08)
				spikes_sprite.modulate = Color(1.0, 0.15, 0.15, 1.0) # Dangerous red
			if spikes_collision:
				spikes_collision.disabled = false
			AudioManager.play_sfx("warning")
			
			# Check any body already standing on it
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
