extends Area2D
class_name BulletBetrayalIcicleTrap
## Hanging icicle hazard for Bullet Betrayal World 3.
## Telegraphs via shake/glint/particles, accelerates downward, kills only the player,
## never blocks bullets or harms enemies, and shatters cleanly on terrain impact.

signal warning_started
signal fall_started
signal shattered

enum State {
	ARMED,
	WARNING,
	FALLING,
	SHATTERED,
}

@export var warning_duration: float = 0.55
@export var gravity_accel: float = 1280.0
@export var initial_fall_speed: float = 48.0
@export var max_fall_speed: float = 540.0
@export var max_fall_distance: float = 340.0
@export var fall_clear_margin: float = 20.0
@export var trigger_width: float = 78.0
@export var trigger_height: float = 250.0

var state: State = State.ARMED
var _mount_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _fall_speed: float = 0.0
var _fallen_distance: float = 0.0
var _shake_phase: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var shatter_particles: CPUParticles2D = $ShatterParticles

func _ready() -> void:
	_mount_position = position
	collision_layer = 0
	collision_mask = 3 # Player (1) + Solid Terrain (2); immune to bullets & enemies
	add_to_group("icicle_traps")
	add_to_group("hazards")
	_apply_trigger_dimensions()
	body_entered.connect(_on_body_entered)
	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 1
		trigger_area.body_entered.connect(_on_trigger_body_entered)

func _apply_trigger_dimensions() -> void:
	if not trigger_shape:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(20.0, trigger_width), maxf(40.0, trigger_height))
	trigger_shape.shape = rect
	trigger_shape.position = Vector2(0.0, rect.size.y * 0.5 + 8.0)

func is_threat_active() -> bool:
	return state != State.SHATTERED

func trigger_fall() -> void:
	if state != State.ARMED:
		return
	state = State.WARNING
	_state_timer = maxf(0.1, warning_duration)
	_shake_phase = 0.0
	if dust_particles:
		dust_particles.emitting = true
	warning_started.emit()

func reset() -> void:
	state = State.ARMED
	position = _mount_position
	_state_timer = 0.0
	_fall_speed = 0.0
	_fallen_distance = 0.0
	_shake_phase = 0.0
	monitoring = true
	monitorable = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.position = Vector2(0.0, 17.0)
		sprite.modulate = Color.WHITE
	if dust_particles:
		dust_particles.emitting = false
	if shatter_particles:
		shatter_particles.emitting = false
	if trigger_area:
		trigger_area.monitoring = true

func _physics_process(delta: float) -> void:
	match state:
		State.ARMED:
			if trigger_area and trigger_area.monitoring:
				for body in trigger_area.get_overlapping_bodies():
					if _is_valid_living_player(body):
						trigger_fall()
						break
		State.WARNING:
			_shake_phase += delta
			_state_timer -= delta
			if sprite:
				sprite.position = Vector2(sin(_shake_phase * 64.0) * 2.2, 17.0)
				var glint := 0.5 + 0.5 * sin(_shake_phase * 28.0)
				sprite.modulate = Color(1.0 + 0.25 * glint, 1.0 + 0.35 * glint, 1.2 + 0.3 * glint, 1.0)
			if _state_timer <= 0.0:
				_begin_fall()
		State.FALLING:
			_fall_speed = minf(max_fall_speed, _fall_speed + gravity_accel * delta)
			var step_y := _fall_speed * delta
			position.y += step_y
			_fallen_distance += step_y

			var hit_ground := false
			for body in get_overlapping_bodies():
				if _is_valid_living_player(body):
					_damage_player(body)
				elif _fallen_distance >= fall_clear_margin and _is_terrain_body(body):
					hit_ground = true

			if hit_ground or _fallen_distance >= max_fall_distance or global_position.y > 520.0:
				_shatter()
		State.SHATTERED:
			pass

func _begin_fall() -> void:
	state = State.FALLING
	_fall_speed = initial_fall_speed
	_fallen_distance = 0.0
	if sprite:
		sprite.position = Vector2(0.0, 17.0)
		sprite.modulate = Color.WHITE
	if dust_particles:
		dust_particles.emitting = false
	if trigger_area:
		trigger_area.set_deferred("monitoring", false)
	fall_started.emit()

func _shatter() -> void:
	if state == State.SHATTERED:
		return
	state = State.SHATTERED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if sprite:
		sprite.visible = false
	if dust_particles:
		dust_particles.emitting = false
	if shatter_particles:
		shatter_particles.restart()
		shatter_particles.emitting = true
	shattered.emit()

func _is_valid_living_player(body: Node) -> bool:
	if not body or not body.is_in_group("player"):
		return false
	if "is_alive" in body and not body.is_alive:
		return false
	return true

func _is_terrain_body(body: Node) -> bool:
	return body is StaticBody2D or body is TileMap or body is TileMapLayer

func _damage_player(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", 1)

func _on_trigger_body_entered(body: Node2D) -> void:
	if state == State.ARMED and _is_valid_living_player(body):
		trigger_fall()

func _on_body_entered(body: Node2D) -> void:
	if state != State.FALLING:
		return
	if _is_valid_living_player(body):
		_damage_player(body)
	elif _fallen_distance >= fall_clear_margin and _is_terrain_body(body):
		_shatter()
