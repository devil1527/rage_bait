class_name SurpriseGhostChain
extends Node2D

## World 2 Boss Stage (Level 10) Signature Hazard: Surprise Ghost Chains
## Suddenly emerges from ceiling after a clear warning, swings through dangerous arc,
## then safely retracts into ceiling and disappears. Completely collision-free when dormant.

signal attack_finished

enum ChainState {
	DORMANT,
	WARNING,
	EMERGING,
	ATTACKING,
	RETRACTING
}

@export var chain_length: float = 145.0
@export var max_swing_angle: float = 46.0
@export var swing_speed: float = 2.4
@export var warning_duration: float = 0.8
@export var attack_duration: float = 2.0
@export var is_lethal: bool = true

var current_state: ChainState = ChainState.DORMANT
var _state_time: float = 0.0
var _swing_time: float = 0.0
var _current_deployed_length: float = 0.0

@onready var mount_sprite: Sprite2D = $MountSprite
@onready var warning_indicator: Node2D = $WarningIndicator
@onready var warning_sprite: Sprite2D = $WarningIndicator/WarningSprite
@onready var warning_particles: CPUParticles2D = $WarningIndicator/WarningParticles
@onready var pivot: Node2D = $Pivot
@onready var chain_line: Line2D = $Pivot/ChainLine
@onready var weight_sprite: Sprite2D = $Pivot/WeightSprite
@onready var spectral_particles: CPUParticles2D = $Pivot/SpectralParticles
@onready var hazard_area: Area2D = $Pivot/HazardArea
@onready var weight_collision: CollisionShape2D = $Pivot/HazardArea/WeightCollision
@onready var chain_collision: CollisionShape2D = $Pivot/HazardArea/ChainCollision

func _ready() -> void:
	if hazard_area:
		hazard_area.collision_layer = 4
		hazard_area.collision_mask = 1
		hazard_area.body_entered.connect(_on_hazard_body_entered)
		
	GameManager.coins_reset.connect(reset)
	_apply_dormant_state()

func _physics_process(delta: float) -> void:
	if current_state == ChainState.DORMANT:
		return
		
	_state_time += delta
	
	match current_state:
		ChainState.WARNING:
			# Pulse warning cue
			if warning_sprite:
				var pulse := 0.6 + 0.4 * sin(_state_time * 12.0)
				warning_sprite.modulate.a = pulse
			if _state_time >= warning_duration:
				_transition_to_emerging()
				
		ChainState.EMERGING:
			# Rapid descent from ceiling (0.28s)
			var t := clampf(_state_time / 0.28, 0.0, 1.0)
			_current_deployed_length = lerpf(10.0, chain_length, t)
			_update_chain_geometry(_current_deployed_length)
			pivot.rotation = 0.0
			if t >= 1.0:
				_transition_to_attacking()
				
		ChainState.ATTACKING:
			_swing_time += delta
			var angle_rad := deg_to_rad(max_swing_angle) * sin(_swing_time * swing_speed)
			pivot.rotation = angle_rad
			if _state_time >= attack_duration:
				_transition_to_retracting()
				
		ChainState.RETRACTING:
			# Retract back up into ceiling (0.32s)
			var t := clampf(_state_time / 0.32, 0.0, 1.0)
			_current_deployed_length = lerpf(chain_length, 0.0, t)
			_update_chain_geometry(_current_deployed_length)
			modulate.a = 1.0 - t
			if t >= 1.0:
				_apply_dormant_state()
				attack_finished.emit()

func trigger_attack(warn_time: float = -1.0, atk_time: float = -1.0) -> void:
	if current_state != ChainState.DORMANT:
		return
	if warn_time > 0.0:
		warning_duration = warn_time
	if atk_time > 0.0:
		attack_duration = atk_time
		
	current_state = ChainState.WARNING
	_state_time = 0.0
	_swing_time = 0.0
	
	visible = true
	modulate.a = 1.0
	if mount_sprite:
		mount_sprite.modulate.a = 1.0
	if warning_indicator:
		warning_indicator.visible = true
		if warning_particles:
			warning_particles.emitting = true
	if pivot:
		pivot.visible = false
	if hazard_area:
		hazard_area.monitoring = false
		hazard_area.monitorable = false
		weight_collision.set_deferred("disabled", true)
		chain_collision.set_deferred("disabled", true)

func _transition_to_emerging() -> void:
	current_state = ChainState.EMERGING
	_state_time = 0.0
	if warning_indicator:
		warning_indicator.visible = false
	if pivot:
		pivot.visible = true
	if spectral_particles:
		spectral_particles.emitting = true
	AudioManager.play_sfx("flame")

func _transition_to_attacking() -> void:
	current_state = ChainState.ATTACKING
	_state_time = 0.0
	_swing_time = 0.0
	_current_deployed_length = chain_length
	_update_chain_geometry(chain_length)
	
	if hazard_area and is_lethal:
		hazard_area.monitoring = true
		hazard_area.monitorable = true
		weight_collision.set_deferred("disabled", false)
		chain_collision.set_deferred("disabled", false)

func _transition_to_retracting() -> void:
	current_state = ChainState.RETRACTING
	_state_time = 0.0
	if hazard_area:
		hazard_area.monitoring = false
		hazard_area.monitorable = false
		weight_collision.set_deferred("disabled", true)
		chain_collision.set_deferred("disabled", true)

func _apply_dormant_state() -> void:
	current_state = ChainState.DORMANT
	_state_time = 0.0
	_swing_time = 0.0
	_current_deployed_length = 0.0
	visible = false
	modulate.a = 1.0
	
	if warning_indicator:
		warning_indicator.visible = false
		if warning_particles:
			warning_particles.emitting = false
	if pivot:
		pivot.visible = false
		pivot.rotation = 0.0
	if spectral_particles:
		spectral_particles.emitting = false
	if hazard_area:
		hazard_area.monitoring = false
		hazard_area.monitorable = false
		if weight_collision:
			weight_collision.set_deferred("disabled", true)
		if chain_collision:
			chain_collision.set_deferred("disabled", true)

func _update_chain_geometry(len: float) -> void:
	if not pivot:
		return
	if chain_line:
		chain_line.clear_points()
		chain_line.add_point(Vector2.ZERO)
		chain_line.add_point(Vector2(0.0, len))
	if weight_sprite:
		weight_sprite.position = Vector2(0.0, len)
	if spectral_particles:
		spectral_particles.position = Vector2(0.0, len)
	if weight_collision:
		weight_collision.position = Vector2(0.0, len)
	if chain_collision:
		var lethal_len := len * 0.45
		var center_y := len - (lethal_len / 2.0)
		chain_collision.position = Vector2(0.0, center_y)
		if chain_collision.shape is RectangleShape2D:
			(chain_collision.shape as RectangleShape2D).size = Vector2(10.0, maxf(1.0, lethal_len))

func _on_hazard_body_entered(body: Node2D) -> void:
	if current_state != ChainState.ATTACKING or not is_lethal:
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player"):
		GameManager.trigger_player_death()

func reset() -> void:
	_apply_dormant_state()

func is_active() -> bool:
	return current_state != ChainState.DORMANT
