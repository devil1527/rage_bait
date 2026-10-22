class_name HellRune
extends Node2D

## Trap 1: Hell Rune — World 4: Final Hell signature trap.
## Embedded in platform surfaces. When the player enters its activation zone,
## displays an immediate, intense warning flash and crackle (0.28s),
## erupting into an aggressive, lethal hellfire column (0.65s) on hazard layer 4.
## Tuned to punish blind sprinting while rewarding skillful jumping or braking.
## Resets cleanly on retry and revive.

enum State { DORMANT, WARNING, ACTIVE, COOLDOWN }

signal state_changed(new_state: State)
signal rune_triggered

@export var warning_duration: float = 0.28
@export var active_duration: float = 0.65
@export var cooldown_duration: float = 1.0

# Activation zone tuning: allows lead distance so the flame erupts in front of sprinting players
@export var trigger_size: Vector2 = Vector2(64.0, 24.0)
@export var trigger_offset: Vector2 = Vector2(-18.0, -5.0)

var current_state: State = State.DORMANT
var _state_timer: float = 0.0

@onready var rune_plate: Sprite2D = $RunePlate
@onready var flame_burst: Sprite2D = $FlameBurst
@onready var step_area: Area2D = $StepArea
@onready var step_shape: CollisionShape2D = $StepArea/CollisionShape2D
@onready var hazard_area: Area2D = $HazardArea
@onready var hazard_shape: CollisionShape2D = $HazardArea/CollisionShape2D
@onready var warning_particles: CPUParticles2D = get_node_or_null("WarningParticles")

func _ready() -> void:
	_setup_trigger_shape()

	if step_area:
		step_area.body_entered.connect(_on_step_area_body_entered)
	if hazard_area:
		hazard_area.body_entered.connect(_on_hazard_area_body_entered)

	GameManager.coins_reset.connect(reset)
	GameManager.player_revived.connect(_on_player_revived)

	_apply_state(State.DORMANT)

func _setup_trigger_shape() -> void:
	if step_shape and step_shape.shape is RectangleShape2D:
		(step_shape.shape as RectangleShape2D).size = trigger_size
		step_shape.position = trigger_offset

func _on_player_revived(_pos: Vector2) -> void:
	reset()

func _on_step_area_body_entered(body: Node2D) -> void:
	if current_state == State.DORMANT and (body.is_in_group("player") or body.name == "Player"):
		trigger()

func _on_hazard_area_body_entered(body: Node2D) -> void:
	if current_state == State.ACTIVE and (body.is_in_group("player") or body.name == "Player"):
		if body.has_method("die"):
			body.die()

func trigger() -> void:
	if current_state != State.DORMANT:
		return
	rune_triggered.emit()
	AudioManager.play_sfx("warning")
	_apply_state(State.WARNING)

func _physics_process(delta: float) -> void:
	if current_state == State.DORMANT:
		return

	_state_timer -= delta

	if current_state == State.WARNING:
		# Rapid warning oscillation
		if rune_plate:
			var pulse := sin((warning_duration - _state_timer) * 45.0)
			rune_plate.modulate = Color(1.0, 0.25 + pulse * 0.25, 0.15, 1.0)
		if _state_timer <= 0.0:
			_apply_state(State.ACTIVE)

	elif current_state == State.ACTIVE:
		# Roaring flame oscillation
		if flame_burst:
			flame_burst.scale.x = 1.15 + sin((active_duration - _state_timer) * 35.0) * 0.15
			flame_burst.scale.y = 1.35 + sin((active_duration - _state_timer) * 28.0) * 0.25
		# Continuous overlap check to guarantee instant death
		if hazard_area:
			for body in hazard_area.get_overlapping_bodies():
				if (body.is_in_group("player") or body.name == "Player") and body.has_method("die"):
					body.die()
					break
		if _state_timer <= 0.0:
			_apply_state(State.COOLDOWN)

	elif current_state == State.COOLDOWN:
		if _state_timer <= 0.0:
			_apply_state(State.DORMANT)

func _apply_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(current_state)

	match new_state:
		State.DORMANT:
			_state_timer = 0.0
			if rune_plate:
				rune_plate.modulate = Color(0.85, 0.45, 0.5, 0.8)
			if flame_burst:
				flame_burst.visible = false
			if hazard_shape:
				hazard_shape.disabled = true
				hazard_shape.set_deferred("disabled", true)
			if step_shape:
				step_shape.disabled = false
				step_shape.set_deferred("disabled", false)
			if warning_particles:
				warning_particles.emitting = false
			# If player is already standing in the trigger, start immediately
			if step_area:
				for body in step_area.get_overlapping_bodies():
					if body.is_in_group("player") or body.name == "Player":
						trigger()
						break

		State.WARNING:
			_state_timer = warning_duration
			if flame_burst:
				flame_burst.visible = false
			if hazard_shape:
				hazard_shape.disabled = true
				hazard_shape.set_deferred("disabled", true)
			if warning_particles:
				warning_particles.emitting = true

		State.ACTIVE:
			_state_timer = active_duration
			AudioManager.play_sfx("laser")
			if rune_plate:
				rune_plate.modulate = Color(1.0, 0.95, 0.85, 1.0)
			if flame_burst:
				flame_burst.visible = true
				flame_burst.scale = Vector2(1.25, 1.45)
			if hazard_shape:
				hazard_shape.disabled = false
				hazard_shape.set_deferred("disabled", false)
			if warning_particles:
				warning_particles.emitting = false
			# Instantaneous check on eruption frame
			if hazard_area:
				for body in hazard_area.get_overlapping_bodies():
					if (body.is_in_group("player") or body.name == "Player") and body.has_method("die"):
						body.die()
						break

		State.COOLDOWN:
			_state_timer = cooldown_duration
			if rune_plate:
				rune_plate.modulate = Color(0.35, 0.22, 0.25, 0.6)
			if flame_burst:
				flame_burst.visible = false
			if hazard_shape:
				hazard_shape.disabled = true
				hazard_shape.set_deferred("disabled", true)
			if warning_particles:
				warning_particles.emitting = false

func reset() -> void:
	_apply_state(State.DORMANT)
