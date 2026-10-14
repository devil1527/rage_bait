class_name SurvivalArenaPlatform
extends AnimatableBody2D

## World 2 Boss Stage (Level 10) Arena Platform.
## Implements one of five signature platform hazards:
## 1. SPIKES: Warning cue -> spikes emerge (lethal) -> retracts -> safe.
## 2. PHANTOM: Shimmer warning -> dissolves (intangible) -> recovers solid.
## 3. CRUMBLING: Shaking warning -> falls downward (no collision) -> recovers to position.
## 4. CHAINS: Warning rift -> surprise ghost chain descends & attacks -> retracts into ceiling.
## 5. COUNTDOWN: Urgent numerical countdown -> dissolves -> recovers solid.
## All hazards are completely synchronized between visuals and collision.

signal hazard_warned
signal hazard_activated
signal hazard_recovered

enum HazardType {
	SPIKES,
	PHANTOM,
	CRUMBLING,
	CHAINS,
	COUNTDOWN
}

enum PlatformState {
	SAFE,
	WARNING,
	HAZARDOUS,
	RECOVERING
}

@export var hazard_type: HazardType = HazardType.SPIKES
@export var platform_width: float = 160.0:
	set(val):
		platform_width = val
		if is_node_ready():
			_update_dimensions()
@export var platform_height: float = 24.0

@export var linked_surprise_chain: SurpriseGhostChain = null

var default_hazard_type: HazardType = HazardType.SPIKES
var current_state: PlatformState = PlatformState.SAFE
var _state_timer: float = 0.0
var _warning_duration: float = 0.8
var _active_duration: float = 1.8
var _original_position: Vector2

# Node references
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var solid_visual: NinePatchRect = $SolidVisual
@onready var spectral_visual: NinePatchRect = $SpectralVisual
@onready var warning_rect: NinePatchRect = $WarningRect
@onready var spikes_area: Area2D = $SpikesArea
@onready var spikes_sprite: Sprite2D = $SpikesArea/SpikesSprite
@onready var spikes_collision: CollisionShape2D = $SpikesArea/CollisionShape2D
@onready var countdown_label: Label = $CountdownBadge/Label
@onready var countdown_badge: Control = $CountdownBadge
@onready var particles: CPUParticles2D = $Particles

var _shake_tween: Tween = null
var _fall_tween: Tween = null

func _ready() -> void:
	default_hazard_type = hazard_type
	_original_position = position
	_update_dimensions()
	_apply_safe_state()
	
	if spikes_area:
		spikes_area.collision_layer = 4
		spikes_area.collision_mask = 1
		spikes_area.body_entered.connect(_on_spikes_body_entered)
		
	GameManager.coins_reset.connect(reset_hazard)

func _physics_process(delta: float) -> void:
	if current_state == PlatformState.SAFE:
		return
		
	_state_timer += delta
	
	match current_state:
		PlatformState.WARNING:
			_process_warning(delta)
			if _state_timer >= _warning_duration:
				_transition_to_hazardous()
				
		PlatformState.HAZARDOUS:
			_process_hazardous(delta)
			if _state_timer >= _active_duration:
				_transition_to_safe()

func _update_dimensions() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = Vector2(platform_width, platform_height)
	if solid_visual:
		solid_visual.offset_left = -platform_width / 2.0
		solid_visual.offset_right = platform_width / 2.0
		solid_visual.offset_top = -platform_height / 2.0
		solid_visual.offset_bottom = platform_height / 2.0
	if spectral_visual:
		spectral_visual.offset_left = -platform_width / 2.0
		spectral_visual.offset_right = platform_width / 2.0
		spectral_visual.offset_top = -platform_height / 2.0
		spectral_visual.offset_bottom = platform_height / 2.0
	if warning_rect:
		warning_rect.offset_left = -platform_width / 2.0
		warning_rect.offset_right = platform_width / 2.0
		warning_rect.offset_top = -platform_height / 2.0
		warning_rect.offset_bottom = platform_height / 2.0
	if spikes_collision and spikes_collision.shape is RectangleShape2D:
		(spikes_collision.shape as RectangleShape2D).size = Vector2(platform_width - 8.0, 14.0)

func trigger_hazard(warn_time: float = 0.8, active_time: float = 1.8, override_type: int = -1) -> void:
	if current_state != PlatformState.SAFE:
		return
	if override_type >= 0 and override_type <= HazardType.COUNTDOWN:
		hazard_type = override_type as HazardType
	_warning_duration = maxf(0.01, warn_time)
	_active_duration = maxf(0.01, active_time)
	_state_timer = 0.0
	current_state = PlatformState.WARNING
	hazard_warned.emit()
	
	# Start specific warning cues
	match hazard_type:
		HazardType.SPIKES:
			if warning_rect:
				warning_rect.visible = true
				warning_rect.modulate = Color(1.0, 0.25, 0.35, 0.8)
			if particles:
				particles.emitting = true
				
		HazardType.PHANTOM:
			if spectral_visual:
				spectral_visual.visible = true
			if particles:
				particles.emitting = true
				
		HazardType.CRUMBLING:
			if warning_rect:
				warning_rect.visible = true
				warning_rect.modulate = Color(1.0, 0.6, 0.2, 0.7)
			_start_rumble_shake()
			
		HazardType.CHAINS:
			if linked_surprise_chain:
				linked_surprise_chain.trigger_attack(_warning_duration, _active_duration)
			if warning_rect:
				warning_rect.visible = true
				warning_rect.modulate = Color(0.8, 0.2, 1.0, 0.7)
				
		HazardType.COUNTDOWN:
			if countdown_badge:
				countdown_badge.visible = true
			if warning_rect:
				warning_rect.visible = true
				warning_rect.modulate = Color(1.0, 0.8, 0.2, 0.7)

func _process_warning(_delta: float) -> void:
	match hazard_type:
		HazardType.SPIKES:
			if warning_rect:
				var pulse := 0.5 + 0.5 * sin(_state_timer * 14.0)
				warning_rect.modulate.a = pulse
		HazardType.PHANTOM:
			var alpha_pulse := 0.4 + 0.5 * sin(_state_timer * 16.0)
			solid_visual.modulate.a = alpha_pulse
		HazardType.COUNTDOWN:
			var remaining := maxf(0.0, _warning_duration - _state_timer)
			var count_val := ceili(remaining / (_warning_duration / 3.0))
			count_val = clampi(count_val, 1, 3)
			if countdown_label:
				countdown_label.text = str(count_val)
				if count_val == 1:
					countdown_label.modulate = Color(1.0, 0.2, 0.3)
				elif count_val == 2:
					countdown_label.modulate = Color(1.0, 0.7, 0.2)
				else:
					countdown_label.modulate = Color(1.0, 0.9, 0.4)

func _transition_to_hazardous() -> void:
	current_state = PlatformState.HAZARDOUS
	_state_timer = 0.0
	hazard_activated.emit()
	
	if warning_rect:
		warning_rect.visible = false
	if countdown_badge:
		countdown_badge.visible = false
		
	match hazard_type:
		HazardType.SPIKES:
			# Spikes emerge
			if spikes_area:
				spikes_area.visible = true
				spikes_area.monitoring = true
				if spikes_collision:
					spikes_collision.disabled = false
				if spikes_sprite:
					spikes_sprite.position.y = -18.0
			AudioManager.play_sfx("flame")
			
		HazardType.PHANTOM:
			# Platform becomes intangible
			if collision_shape:
				collision_shape.disabled = true
			solid_visual.modulate.a = 0.2
			if spectral_visual:
				spectral_visual.visible = true
				spectral_visual.modulate.a = 0.35
				
		HazardType.CRUMBLING:
			# Platform falls downward
			if collision_shape:
				collision_shape.disabled = true
			_stop_shake()
			_fall_down()
			
		HazardType.CHAINS:
			# Chains are handled by linked_surprise_chain
			pass
			
		HazardType.COUNTDOWN:
			# Platform dissolves
			if collision_shape:
				collision_shape.disabled = true
			solid_visual.modulate.a = 0.15

func _process_hazardous(_delta: float) -> void:
	match hazard_type:
		HazardType.PHANTOM, HazardType.COUNTDOWN:
			solid_visual.modulate.a = 0.2 + 0.1 * sin(_state_timer * 8.0)

func _transition_to_safe() -> void:
	_apply_safe_state()
	hazard_recovered.emit()

func _apply_safe_state() -> void:
	current_state = PlatformState.SAFE
	_state_timer = 0.0
	
	_stop_shake()
	if _fall_tween:
		_fall_tween.kill()
		_fall_tween = null
	position = _original_position
	
	if collision_shape:
		collision_shape.disabled = false
	if solid_visual:
		solid_visual.modulate.a = 1.0
		solid_visual.visible = true
	if spectral_visual:
		spectral_visual.visible = false
	if warning_rect:
		warning_rect.visible = false
	if countdown_badge:
		countdown_badge.visible = false
	if particles:
		particles.emitting = false
		
	if spikes_area:
		spikes_area.visible = false
		spikes_area.monitoring = false
		if spikes_collision:
			spikes_collision.disabled = true
		if spikes_sprite:
			spikes_sprite.position.y = -6.0

func _start_rumble_shake() -> void:
	_stop_shake()
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_property(self, "position:x", _original_position.x - 3.0, 0.04)
	_shake_tween.tween_property(self, "position:x", _original_position.x + 3.0, 0.04)

func _stop_shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	position.x = _original_position.x

func _fall_down() -> void:
	if _fall_tween:
		_fall_tween.kill()
	_fall_tween = create_tween()
	_fall_tween.tween_property(self, "position:y", _original_position.y + 70.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fall_tween.parallel().tween_property(solid_visual, "modulate:a", 0.0, 0.35)

func _on_spikes_body_entered(body: Node2D) -> void:
	if current_state != PlatformState.HAZARDOUS or hazard_type != HazardType.SPIKES:
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player"):
		GameManager.trigger_player_death()

func reset_hazard() -> void:
	hazard_type = default_hazard_type
	_apply_safe_state()
	if linked_surprise_chain:
		linked_surprise_chain.reset()

func is_hazard_active() -> bool:
	return current_state != PlatformState.SAFE

func is_platform_safe() -> bool:
	if hazard_type == HazardType.CHAINS:
		if linked_surprise_chain and linked_surprise_chain.is_active():
			return false
	return current_state == PlatformState.SAFE
