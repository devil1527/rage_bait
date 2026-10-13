class_name PhantomPlatform
extends StaticBody2D

## PhantomPlatform provides two distinct variants of spectral platforms
## for World 2: The Haunted Hall:
## 1. TIMED: Deterministic cycle between SOLID and PHANTOM with clear visual warning.
## 2. TRIGGERED: Reacts when player steps on it, displaying a clear warning cue,
##    then transitioning to PHANTOM, and recovering to SOLID after a predictable interval.
## Collision and visual states are strictly synchronized at all times.

enum PlatformType { TIMED, TRIGGERED }
enum PlatformState { SOLID, WARNING, PHANTOM }

signal state_changed(new_state: PlatformState)
signal platform_triggered

@export var platform_type: PlatformType = PlatformType.TIMED

# Timed variant parameters
@export var solid_duration: float = 2.2
@export var phantom_duration: float = 1.6
@export var warning_duration: float = 0.65
@export var cycle_offset: float = 0.0

# Triggered variant parameters
@export var trigger_delay: float = 0.75 # Warning duration before fading
@export var phantom_recovery_time: float = 2.2 # Time spent in phantom before recovering

# Dimensions
@export var width: float = 80.0
@export var height: float = 24.0

var current_state: PlatformState = PlatformState.SOLID

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var solid_visual: NinePatchRect = $SolidVisual
@onready var spectral_visual: NinePatchRect = $SpectralVisual
@onready var step_area: Area2D = $StepArea
@onready var step_shape: CollisionShape2D = $StepArea/CollisionShape2D
@onready var spectral_particles: CPUParticles2D = $SpectralParticles

var _elapsed_cycle: float = 0.0
var _triggered_timer: float = 0.0
var _is_triggered: bool = false
var _shake_tween: Tween = null
var _original_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_original_pos = position
	
	_update_dimensions()
	
	if step_area:
		step_area.body_entered.connect(_on_step_area_body_entered)
		
	GameManager.coins_reset.connect(reset)
	reset()

func _update_dimensions() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(width, height)
		
	if solid_visual:
		solid_visual.offset_left = -width / 2.0
		solid_visual.offset_top = -height / 2.0
		solid_visual.offset_right = width / 2.0
		solid_visual.offset_bottom = height / 2.0
		
	if spectral_visual:
		spectral_visual.offset_left = -width / 2.0
		spectral_visual.offset_top = -height / 2.0
		spectral_visual.offset_right = width / 2.0
		spectral_visual.offset_bottom = height / 2.0
		
	if step_shape and step_shape.shape is RectangleShape2D:
		step_shape.shape.size = Vector2(maxf(10.0, width - 6.0), 10.0)
		step_shape.position = Vector2(0.0, -height / 2.0 - 4.0)

func _physics_process(delta: float) -> void:
	match platform_type:
		PlatformType.TIMED:
			_process_timed_cycle(delta)
		PlatformType.TRIGGERED:
			_process_triggered_state(delta)

func _process_timed_cycle(delta: float) -> void:
	var total_period := solid_duration + phantom_duration
	if total_period <= 0.0:
		return
		
	_elapsed_cycle += delta
	var current_t := fmod(_elapsed_cycle + cycle_offset, total_period)
	
	if current_t < (solid_duration - warning_duration):
		_set_state(PlatformState.SOLID)
	elif current_t < solid_duration:
		_set_state(PlatformState.WARNING)
		# Subtle spectral pulse during warning phase
		var warning_pct := (current_t - (solid_duration - warning_duration)) / warning_duration
		solid_visual.modulate.a = 0.6 + 0.4 * sin(warning_pct * PI * 8.0)
		spectral_visual.modulate.a = 0.4 * sin(warning_pct * PI * 8.0)
	else:
		_set_state(PlatformState.PHANTOM)

func _process_triggered_state(delta: float) -> void:
	if current_state == PlatformState.WARNING:
		_triggered_timer += delta
		# Shake and flicker warning cue
		var shake_offset := sin(_triggered_timer * 35.0) * 1.5
		solid_visual.position.x = (-width / 2.0) + shake_offset
		solid_visual.modulate.a = 0.5 + 0.5 * sin(_triggered_timer * 20.0)
		spectral_visual.modulate.a = 0.5 * (1.0 - sin(_triggered_timer * 20.0))
		
		if _triggered_timer >= trigger_delay:
			_set_state(PlatformState.PHANTOM)
			_triggered_timer = 0.0
	elif current_state == PlatformState.PHANTOM:
		_triggered_timer += delta
		if _triggered_timer >= phantom_recovery_time:
			# Predictable recovery to solid
			_set_state(PlatformState.SOLID)
			_is_triggered = false
			_triggered_timer = 0.0

func _on_step_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if platform_type == PlatformType.TRIGGERED and current_state == PlatformState.SOLID and not _is_triggered:
		_is_triggered = true
		_triggered_timer = 0.0
		platform_triggered.emit()
		AudioManager.play_sfx("warning")
		_set_state(PlatformState.WARNING)

func _set_state(new_state: PlatformState) -> void:
	if current_state == new_state:
		return
		
	current_state = new_state
	state_changed.emit(new_state)
	
	match new_state:
		PlatformState.SOLID:
			collision_shape.disabled = false
			solid_visual.visible = true
			solid_visual.modulate = Color(1, 1, 1, 1)
			solid_visual.position.x = -width / 2.0
			spectral_visual.visible = false
			spectral_particles.emitting = false
			
		PlatformState.WARNING:
			# Stays solid during warning so player has fair time to jump off safely
			collision_shape.disabled = false
			solid_visual.visible = true
			spectral_visual.visible = true
			spectral_particles.emitting = true
			
		PlatformState.PHANTOM:
			# Collision disabled in strict synchronization with spectral appearance
			collision_shape.disabled = true
			solid_visual.visible = false
			solid_visual.position.x = -width / 2.0
			spectral_visual.visible = true
			spectral_visual.modulate = Color(0.8, 1.0, 1.0, 0.45)
			spectral_particles.emitting = true

func reset() -> void:
	_elapsed_cycle = 0.0
	_triggered_timer = 0.0
	_is_triggered = false
	position = _original_pos
	
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		
	if platform_type == PlatformType.TIMED:
		# Set initial state according to cycle offset
		var total_period := solid_duration + phantom_duration
		var current_t := fmod(cycle_offset, total_period)
		if current_t < (solid_duration - warning_duration):
			_set_state(PlatformState.SOLID)
		elif current_t < solid_duration:
			_set_state(PlatformState.WARNING)
		else:
			_set_state(PlatformState.PHANTOM)
	else:
		_set_state(PlatformState.SOLID)
