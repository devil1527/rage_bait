class_name InfernalEnergyGate
extends Node2D

## Trap 2: Infernal Energy Gate — World 4 supernatural laser barrier.
## Emits a pulsating crimson plasma beam between demonic obsidian pylons.
## Alternates between INACTIVE (safe crossing window 2.0s), WARNING pulse (0.70s),
## and ACTIVE lethal barrier (1.10s) on hazard layer 4.
## Visual state and collision state are strictly synchronized at all times.

enum GateState { INACTIVE, WARNING, ACTIVE }

signal state_changed(new_state: GateState)

@export var inactive_duration: float = 2.0
@export var warning_duration: float = 0.70
@export var active_duration: float = 1.10
@export var cycle_offset: float = 0.0
@export var beam_length: float = 140.0
@export var is_vertical: bool = true

var current_state: GateState = GateState.INACTIVE
var _elapsed: float = 0.0

@onready var pylon_start: Sprite2D = $PylonStart
@onready var pylon_end: Sprite2D = $PylonEnd
@onready var beam_visual: NinePatchRect = $BeamVisual
@onready var warning_line: Line2D = $WarningLine
@onready var hazard_area: Area2D = $HazardArea
@onready var hazard_shape: CollisionShape2D = $HazardArea/CollisionShape2D

func _ready() -> void:
	if hazard_area:
		hazard_area.body_entered.connect(_on_hazard_body_entered)

	GameManager.coins_reset.connect(reset)
	GameManager.player_revived.connect(_on_player_revived)

	_setup_geometry()
	_elapsed = cycle_offset
	_apply_state(GateState.INACTIVE)

func _setup_geometry() -> void:
	var dir := Vector2.DOWN if is_vertical else Vector2.RIGHT
	var end_pos := dir * beam_length

	if pylon_end:
		pylon_end.position = end_pos
		pylon_end.rotation = PI if is_vertical else -PI * 0.5

	if is_vertical:
		if pylon_start:
			pylon_start.rotation = 0.0
		if beam_visual:
			beam_visual.position = Vector2(-8.0, 12.0)
			beam_visual.size = Vector2(16.0, beam_length - 24.0)
		if hazard_shape:
			hazard_shape.position = Vector2(0.0, beam_length * 0.5)
			var rect := RectangleShape2D.new()
			rect.size = Vector2(12.0, beam_length - 16.0)
			hazard_shape.shape = rect
	else:
		if pylon_start:
			pylon_start.rotation = PI * 0.5
		if beam_visual:
			beam_visual.position = Vector2(12.0, -8.0)
			beam_visual.size = Vector2(beam_length - 24.0, 16.0)
		if hazard_shape:
			hazard_shape.position = Vector2(beam_length * 0.5, 0.0)
			var rect := RectangleShape2D.new()
			rect.size = Vector2(beam_length - 16.0, 12.0)
			hazard_shape.shape = rect

	if warning_line:
		warning_line.clear_points()
		warning_line.add_point(Vector2.ZERO)
		warning_line.add_point(end_pos)

func _on_player_revived(_pos: Vector2) -> void:
	reset()

func _on_hazard_body_entered(body: Node2D) -> void:
	if current_state == GateState.ACTIVE and (body.is_in_group("player") or body.name == "Player"):
		if body.has_method("die"):
			body.die()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var total_cycle := inactive_duration + warning_duration + active_duration
	var cycle_pos := fmod(_elapsed, total_cycle)

	var next_state: GateState
	if cycle_pos < inactive_duration:
		next_state = GateState.INACTIVE
	elif cycle_pos < (inactive_duration + warning_duration):
		next_state = GateState.WARNING
	else:
		next_state = GateState.ACTIVE

	if next_state != current_state:
		_apply_state(next_state)

	# Dynamic visual effects per state
	if current_state == GateState.WARNING:
		if warning_line:
			warning_line.modulate.a = 0.4 + sin(_elapsed * 25.0) * 0.4
	elif current_state == GateState.ACTIVE:
		if beam_visual:
			beam_visual.modulate = Color(1.0, 0.8 + sin(_elapsed * 35.0) * 0.2, 0.9, 1.0)

func _apply_state(new_state: GateState) -> void:
	current_state = new_state
	state_changed.emit(current_state)

	match new_state:
		GateState.INACTIVE:
			if beam_visual:
				beam_visual.visible = false
			if warning_line:
				warning_line.visible = false
			if hazard_shape:
				hazard_shape.disabled = true
				hazard_shape.set_deferred("disabled", true)
			if pylon_start:
				pylon_start.modulate = Color(0.7, 0.35, 0.4, 0.7)
			if pylon_end:
				pylon_end.modulate = Color(0.7, 0.35, 0.4, 0.7)

		GateState.WARNING:
			if beam_visual:
				beam_visual.visible = false
			if warning_line:
				warning_line.visible = true
				warning_line.default_color = Color(1.0, 0.25, 0.35, 0.8)
			if hazard_shape:
				hazard_shape.disabled = true
				hazard_shape.set_deferred("disabled", true) # Safe to cross during warning
			if pylon_start:
				pylon_start.modulate = Color(1.0, 0.7, 0.3, 1.0)
			if pylon_end:
				pylon_end.modulate = Color(1.0, 0.7, 0.3, 1.0)

		GateState.ACTIVE:
			AudioManager.play_sfx("laser")
			if warning_line:
				warning_line.visible = false
			if beam_visual:
				beam_visual.visible = true
			if hazard_shape:
				hazard_shape.disabled = false
				hazard_shape.set_deferred("disabled", false)
			if pylon_start:
				pylon_start.modulate = Color(1.0, 0.9, 0.95, 1.0)
			if pylon_end:
				pylon_end.modulate = Color(1.0, 0.9, 0.95, 1.0)

func reset() -> void:
	_elapsed = cycle_offset
	_apply_state(GateState.INACTIVE)
