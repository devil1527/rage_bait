class_name PlatformFireBurner
extends Node2D

## PlatformFireBurner: Motion-Triggered Infernal Platform Burner for Level 20
## State Cycle:
##   IDLE: Inactive base nozzle, safe to traverse.
##   TRIGGERED / WARNING: Player enters proximity; emitter glows amber/red, sparks hiss ($0.65s$).
##   BURST: Superheated flames erupt upward ($0.85s$, lethal hazard layer 4).
##   COOLDOWN: Flames retract, safe to walk on ($1.8s$).
##   RESET: Returns to IDLE once cooldown expires and trigger cleared.
## Cleanly resets on level retry, player death, and player revive.

signal burner_triggered
signal burner_warning_started
signal burner_burst_started
signal burner_burst_ended

enum State {
	IDLE,
	WARNING,
	BURST,
	COOLDOWN
}

@export var warning_duration: float = 0.65
@export var burst_duration: float = 0.85
@export var cooldown_duration: float = 1.8
@export var flame_height: float = 56.0
@export var trigger_width: float = 64.0
@export var trigger_height: float = 36.0

var current_state: State = State.IDLE
var _state_timer: float = 0.0
var _is_active: bool = true

@onready var emitter_sprite: Sprite2D = get_node_or_null("EmitterSprite")
@onready var flame_sprite: Sprite2D = get_node_or_null("FlameSprite")
@onready var trigger_area: Area2D = get_node_or_null("TriggerArea")
@onready var trigger_shape: CollisionShape2D = get_node_or_null("TriggerArea/CollisionShape2D")
@onready var hazard_area: Area2D = get_node_or_null("HazardArea")
@onready var hazard_shape: CollisionShape2D = get_node_or_null("HazardArea/CollisionShape2D")
@onready var spark_particles: CPUParticles2D = get_node_or_null("SparkParticles")

var _emitter_orig_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if emitter_sprite:
		_emitter_orig_pos = emitter_sprite.position

	GameManager.coins_reset.connect(reset)
	GameManager.player_died.connect(_on_player_died)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(func(_pos): reset())

	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 1
		trigger_area.body_entered.connect(_on_trigger_body_entered)

	if hazard_area:
		hazard_area.collision_layer = 4
		hazard_area.collision_mask = 1
		hazard_area.body_entered.connect(_on_hazard_body_entered)

	reset()

func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	match current_state:
		State.IDLE:
			# Check continuous overlap in case player stood inside trigger
			if trigger_area and trigger_area.has_overlapping_bodies():
				for b in trigger_area.get_overlapping_bodies():
					if b.is_in_group("player") or b.name == "Player":
						_trigger_warning()
						break

		State.WARNING:
			_state_timer -= delta
			# Amber tremor / flash
			if emitter_sprite:
				emitter_sprite.position.x = _emitter_orig_pos.x + sin(_state_timer * 45.0) * 1.5
				var pulse = sin(_state_timer * 25.0) * 0.3 + 0.7
				emitter_sprite.modulate = Color(1.8, pulse * 0.8, 0.2, 1.0)

			if _state_timer <= 0.0:
				_erupt_flame()

		State.BURST:
			_state_timer -= delta
			# Flame flicker
			if flame_sprite:
				var flick = sin(_state_timer * 50.0) * 0.08 + 1.0
				flame_sprite.scale.x = flick
				flame_sprite.modulate = Color(1.0, 0.9 + sin(_state_timer * 30.0) * 0.1, 0.8, 1.0)

			# Active lethality check
			if hazard_area:
				for b in hazard_area.get_overlapping_bodies():
					_kill_player(b)

			if _state_timer <= 0.0:
				_retract_flame()

		State.COOLDOWN:
			_state_timer -= delta
			if emitter_sprite:
				emitter_sprite.modulate = emitter_sprite.modulate.lerp(Color.WHITE, delta * 3.0)

			if _state_timer <= 0.0:
				current_state = State.IDLE
				if emitter_sprite:
					emitter_sprite.modulate = Color.WHITE

func _trigger_warning() -> void:
	if current_state != State.IDLE:
		return

	current_state = State.WARNING
	_state_timer = warning_duration
	burner_triggered.emit()
	burner_warning_started.emit()

	if spark_particles:
		spark_particles.emitting = true

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("warning")

func _erupt_flame() -> void:
	current_state = State.BURST
	_state_timer = burst_duration

	if emitter_sprite:
		emitter_sprite.position = _emitter_orig_pos
		emitter_sprite.modulate = Color(2.0, 1.2, 0.4, 1.0)

	if flame_sprite:
		flame_sprite.visible = true
		flame_sprite.scale = Vector2(1.0, flame_height / 128.0)
		flame_sprite.modulate.a = 1.0

	if hazard_shape:
		hazard_shape.disabled = false

	burner_burst_started.emit()

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("fire")

func _retract_flame() -> void:
	current_state = State.COOLDOWN
	_state_timer = cooldown_duration

	if flame_sprite:
		flame_sprite.visible = false
	if hazard_shape:
		hazard_shape.disabled = true
	if spark_particles:
		spark_particles.emitting = false
	if emitter_sprite:
		emitter_sprite.position = _emitter_orig_pos
		emitter_sprite.modulate = Color(0.7, 0.5, 0.5, 1.0)

	burner_burst_ended.emit()

func _on_trigger_body_entered(body: Node2D) -> void:
	if not _is_active:
		return
	if current_state == State.IDLE and (body.is_in_group("player") or body.name == "Player"):
		_trigger_warning()

func _on_hazard_body_entered(body: Node2D) -> void:
	if current_state == State.BURST:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("die"):
			body.die()

func _on_player_died() -> void:
	_is_active = false
	if hazard_shape:
		hazard_shape.set_deferred("disabled", true)
	if spark_particles:
		spark_particles.emitting = false

func reset() -> void:
	_is_active = true
	current_state = State.IDLE
	_state_timer = 0.0

	if emitter_sprite:
		emitter_sprite.position = _emitter_orig_pos
		emitter_sprite.modulate = Color.WHITE

	if flame_sprite:
		flame_sprite.visible = false
		flame_sprite.scale = Vector2(1.0, flame_height / 128.0)

	if hazard_shape:
		hazard_shape.disabled = true

	if spark_particles:
		spark_particles.emitting = false
