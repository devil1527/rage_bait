class_name SwingingChain
extends Node2D

## World 2 (The Haunted Hall) Hazard: Swinging Ghost Chain
## A ceiling-mounted spectral iron pendulum that swings smoothly along a predictable harmonic arc.
## Follows deterministic cycle: theta(t) = max_angle * sin(t * swing_speed + phase_offset).
## Resets cleanly on level retry via GameManager.coins_reset.

signal swing_peak_reached(direction: float)

@export_group("Pendulum Properties")
@export var chain_length: float = 140.0:
	set(val):
		chain_length = maxf(40.0, val)
		if is_node_ready():
			_update_geometry()
@export var max_angle_degrees: float = 50.0:
	set(val):
		max_angle_degrees = clampf(val, 5.0, 85.0)
@export var swing_speed: float = 2.0 # Angular frequency in radians per second (T = 2*PI / swing_speed)
@export var phase_offset: float = 0.0 # Phase offset in radians (e.g. PI for antiphase double-chain)
@export var is_lethal: bool = true

@export_group("Collision Geometry")
@export var weight_radius: float = 13.0
@export var chain_hazard_ratio: float = 0.45 # Lower 45% of chain is lethal along with weight

var _time: float = 0.0
var _prev_velocity_sign: float = 0.0

@onready var mount_sprite: Sprite2D = $MountSprite
@onready var pivot: Node2D = $Pivot
@onready var chain_line: Line2D = $Pivot/ChainLine
@onready var weight_sprite: Sprite2D = $Pivot/WeightSprite
@onready var spectral_particles: CPUParticles2D = $Pivot/SpectralParticles
@onready var hazard_area: Area2D = $Pivot/HazardArea
@onready var weight_collision: CollisionShape2D = $Pivot/HazardArea/WeightCollision
@onready var chain_collision: CollisionShape2D = $Pivot/HazardArea/ChainCollision

func _ready() -> void:
	_update_geometry()
	_update_swing(0.0)
	
	if hazard_area:
		hazard_area.collision_layer = 4
		hazard_area.collision_mask = 1
		hazard_area.body_entered.connect(_on_hazard_body_entered)
		
	GameManager.coins_reset.connect(reset)

func _physics_process(delta: float) -> void:
	_time += delta
	_update_swing(_time)
	
	# Detect peak swing turnarounds (for sound/effects or test assertions)
	var ang_vel := cos(_time * swing_speed + phase_offset)
	var current_sign := signf(ang_vel)
	if _prev_velocity_sign != 0.0 and current_sign != 0.0 and current_sign != _prev_velocity_sign:
		swing_peak_reached.emit(-_prev_velocity_sign)
	if current_sign != 0.0:
		_prev_velocity_sign = current_sign

func _update_geometry() -> void:
	if not pivot:
		return
		
	# Setup Line2D points
	if chain_line:
		chain_line.clear_points()
		chain_line.add_point(Vector2.ZERO)
		chain_line.add_point(Vector2(0.0, chain_length))
		
	# Setup weight sprite position
	if weight_sprite:
		weight_sprite.position = Vector2(0.0, chain_length)
		
	# Setup particles position
	if spectral_particles:
		spectral_particles.position = Vector2(0.0, chain_length)
		
	# Setup collision shapes
	if weight_collision:
		weight_collision.position = Vector2(0.0, chain_length)
		if weight_collision.shape is CircleShape2D:
			(weight_collision.shape as CircleShape2D).radius = weight_radius
		else:
			var circle := CircleShape2D.new()
			circle.radius = weight_radius
			weight_collision.shape = circle
			
	if chain_collision:
		var lethal_chain_len := chain_length * chain_hazard_ratio
		var lethal_center_y := chain_length - (lethal_chain_len / 2.0)
		chain_collision.position = Vector2(0.0, lethal_center_y)
		if chain_collision.shape is RectangleShape2D:
			(chain_collision.shape as RectangleShape2D).size = Vector2(10.0, lethal_chain_len)
		else:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(10.0, lethal_chain_len)
			chain_collision.shape = rect

func _update_swing(t: float) -> void:
	if not pivot:
		return
	var current_angle_rad := deg_to_rad(max_angle_degrees) * sin(t * swing_speed + phase_offset)
	pivot.rotation = current_angle_rad

func _on_hazard_body_entered(body: Node2D) -> void:
	if not is_lethal:
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player"):
		GameManager.trigger_player_death()

func reset() -> void:
	_time = 0.0
	_prev_velocity_sign = 0.0
	_update_swing(0.0)

func get_current_angle_degrees() -> float:
	if not pivot:
		return 0.0
	return rad_to_deg(pivot.rotation)

func get_weight_global_position() -> Vector2:
	if not pivot:
		return global_position + Vector2(0.0, chain_length)
	return pivot.to_global(Vector2(0.0, chain_length))
