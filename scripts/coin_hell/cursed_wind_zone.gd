class_name CursedWindZone
extends Area2D

## Supernatural Cursed Wind zone for World 2: The Haunted Hall (Level 8: The Cursed Wind).
## Applies a controlled, learnable horizontal force to the player inside the zone.
## 3 Variants:
## 1. SIDEWAYS: Continuous push in one direction.
## 2. REVERSING: Changes direction on a predictable cycle with a visual cue before reversal.
## 3. BURST: Short-duration surge with warning telegraph and recovery interval.
## The effect clears immediately when the player exits, dies, or retries.

enum WindType {
	SIDEWAYS,
	REVERSING,
	BURST
}

signal wind_reversing(new_direction: float)
signal wind_burst_warning
signal wind_burst_started
signal wind_burst_ended

@export var wind_type: WindType = WindType.SIDEWAYS
@export var base_strength: float = 80.0
@export var direction: float = 1.0 # 1.0 = right (east), -1.0 = left (west)

# Reversing gust settings
@export var cycle_duration: float = 2.6
@export var warning_duration: float = 0.7
@export var initial_cycle_offset: float = 0.0

# Burst gust settings
@export var burst_interval: float = 3.2
@export var burst_warning_duration: float = 0.8
@export var burst_duration: float = 1.2
@export var burst_strength: float = 135.0

# Visual zone size
@export var zone_size: Vector2 = Vector2(240, 180)

var current_force: float = 0.0
var current_direction: float = 1.0
var is_warning: bool = false
var is_bursting: bool = false

var _player: CharacterBody2D = null
var _timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = $WindParticles
@onready var aura_rect: ColorRect = get_node_or_null("AuraRect")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	
	current_direction = direction
	_timer = initial_cycle_offset
	
	_update_dimensions()
	_update_particles()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.coins_reset.connect(reset)

func _update_dimensions() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = zone_size
	if particles:
		particles.emission_rect_extents = zone_size * 0.5
	if aura_rect:
		aura_rect.offset_left = -zone_size.x * 0.5
		aura_rect.offset_top = -zone_size.y * 0.5
		aura_rect.offset_right = zone_size.x * 0.5
		aura_rect.offset_bottom = zone_size.y * 0.5

func _physics_process(delta: float) -> void:
	match wind_type:
		WindType.SIDEWAYS:
			current_direction = direction
			current_force = base_strength * current_direction
		WindType.REVERSING:
			_process_reversing(delta)
		WindType.BURST:
			_process_burst(delta)
			
	if _player and is_instance_valid(_player):
		if not _player._is_alive:
			_player.wind_velocity = 0.0
			_player = null
		else:
			# Smooth interpolation toward current_force
			_player.wind_velocity = move_toward(_player.wind_velocity, current_force, 450.0 * delta)

func _process_reversing(delta: float) -> void:
	_timer += delta
	var warning_start := maxf(0.1, cycle_duration - warning_duration)
	
	if _timer < warning_start:
		if is_warning:
			is_warning = false
			_update_particles()
	elif _timer < cycle_duration:
		if not is_warning:
			is_warning = true
			_update_particles()
	else:
		# Reverse direction
		_timer = 0.0
		is_warning = false
		current_direction = -current_direction
		_update_particles()
		wind_reversing.emit(current_direction)
		
	current_force = base_strength * current_direction

func _process_burst(delta: float) -> void:
	_timer += delta
	var warning_start := maxf(0.1, burst_interval - burst_warning_duration)
	var burst_start := burst_interval
	var burst_end := burst_interval + burst_duration
	
	current_direction = direction
	
	if _timer < warning_start:
		if is_warning or is_bursting:
			is_warning = false
			is_bursting = false
			_update_particles()
		current_force = base_strength * current_direction
	elif _timer < burst_start:
		if not is_warning:
			is_warning = true
			is_bursting = false
			_update_particles()
			wind_burst_warning.emit()
			if _player and is_instance_valid(_player):
				AudioManager.play_sfx("warning")
		current_force = base_strength * current_direction
	elif _timer < burst_end:
		if not is_bursting:
			is_warning = false
			is_bursting = true
			_update_particles()
			wind_burst_started.emit()
		current_force = burst_strength * current_direction
	else:
		# Burst cycle complete
		_timer = 0.0
		is_warning = false
		is_bursting = false
		_update_particles()
		wind_burst_ended.emit()
		current_force = base_strength * current_direction

func _update_particles() -> void:
	if not particles:
		return
		
	var dir_vec := Vector2(current_direction, 0.0)
	particles.direction = dir_vec
	
	if is_warning:
		# Warning cue: swirling amber/violet particles
		particles.modulate = Color(1.0, 0.75, 0.35, 0.85)
		particles.initial_velocity_min = 25.0
		particles.initial_velocity_max = 60.0
		particles.spread = 45.0
		if aura_rect:
			aura_rect.color = Color(0.4, 0.15, 0.35, 0.18)
	elif is_bursting:
		# Burst surge: rapid glowing cyan stream
		particles.modulate = Color(0.3, 0.95, 1.0, 0.9)
		particles.initial_velocity_min = 120.0
		particles.initial_velocity_max = 220.0
		particles.spread = 12.0
		if aura_rect:
			aura_rect.color = Color(0.1, 0.4, 0.6, 0.22)
	else:
		# Ambient steady flow: pale spectral cyan
		particles.modulate = Color(0.55, 0.88, 1.0, 0.6)
		particles.initial_velocity_min = 40.0
		particles.initial_velocity_max = 95.0
		particles.spread = 18.0
		if aura_rect:
			aura_rect.color = Color(0.12, 0.22, 0.35, 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player = body as CharacterBody2D

func _on_body_exited(body: Node2D) -> void:
	if body == _player or body.is_in_group("player"):
		if body.get("wind_velocity") != null:
			body.wind_velocity = 0.0
		if body == _player:
			_player = null

func reset() -> void:
	if _player and is_instance_valid(_player):
		if _player.get("wind_velocity") != null:
			_player.wind_velocity = 0.0
	_player = null
	_timer = initial_cycle_offset
	current_direction = direction
	is_warning = false
	is_bursting = false
	_update_dimensions()
	_update_particles()
