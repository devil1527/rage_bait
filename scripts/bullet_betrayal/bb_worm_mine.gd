class_name BulletBetrayalWormMine
extends Area2D

## Partially buried desert proximity mine dynamically spawned when a slow
## sandworm finishes retreating underground in World 2, Level 9.
## Arms cleanly over arm_delay before enabling collision, pulses faster with
## a proximity warning ring when approached, and detonates at most once.

signal exploded
signal armed
signal disarmed

const SPRITE_REST_Y: float = -8.0
const SPRITE_EMERGE_START_Y: float = -3.0

@export var arm_delay: float = 0.28
@export var proximity_warning_distance: float = 94.0

var is_armed: bool = false
var is_active: bool = true
var _triggered: bool = false
var _disarming: bool = false
var _arm_timer: float = 0.0
var _pulse_timer: float = 0.0
var _proximity_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var warning_led: ColorRect = $WarningLED
@onready var warning_glow: Sprite2D = $WarningGlow
@onready var proximity_ring: Sprite2D = $ProximityRing
@onready var scorch_mark: Sprite2D = $ScorchMark
@onready var explosion_fx: Node2D = $ExplosionFX
@onready var flash: ColorRect = $ExplosionFX/Flash
@onready var shockwave: Sprite2D = $ExplosionFX/Shockwave
@onready var fire_core: Sprite2D = $ExplosionFX/FireCore
@onready var fire_plume: Sprite2D = $ExplosionFX/FirePlume
@onready var shrapnel_particles: CPUParticles2D = $ExplosionFX/ShrapnelParticles
@onready var smoke_particles: CPUParticles2D = $ExplosionFX/SmokeParticles


func _ready() -> void:
	add_to_group("landmines")
	add_to_group("worm_mines")
	body_entered.connect(_on_body_entered)

	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false
	if proximity_ring:
		proximity_ring.visible = false

	if arm_delay <= 0.0:
		_finish_arming()
	else:
		_start_arming()


func _process(delta: float) -> void:
	if _triggered or _disarming:
		return

	if not is_armed:
		_arm_timer = maxf(0.0, _arm_timer - delta)
		var progress: float = 1.0 - (_arm_timer / maxf(0.01, arm_delay))
		if sprite:
			sprite.position.y = lerpf(SPRITE_EMERGE_START_Y, SPRITE_REST_Y, progress)
			var s: float = lerpf(0.72, 1.0, progress)
			sprite.scale = Vector2(s, s)
			sprite.modulate = Color(1.0, 0.94, 0.85, lerpf(0.6, 1.0, progress))
		if warning_led:
			warning_led.visible = true
			warning_led.color = Color(0.95, 0.65, 0.2, 0.45)
		if warning_glow:
			warning_glow.visible = true
			warning_glow.modulate = Color(0.95, 0.65, 0.2, 0.22)
		if _arm_timer <= 0.0:
			_finish_arming()
		return

	_update_proximity_and_pulse(delta)


func _start_arming() -> void:
	is_armed = false
	is_active = true
	_arm_timer = arm_delay
	monitoring = false
	monitorable = false
	if collision_shape:
		collision_shape.disabled = true
	if sprite:
		sprite.visible = true
		sprite.position.y = SPRITE_EMERGE_START_Y
		sprite.scale = Vector2(0.72, 0.72)
		sprite.modulate = Color(1.0, 0.94, 0.85, 0.6)


func _finish_arming() -> void:
	if _triggered or _disarming:
		return
	is_armed = true
	is_active = true
	monitoring = true
	monitorable = true
	if collision_shape:
		collision_shape.disabled = false
	if sprite:
		sprite.position.y = SPRITE_REST_Y
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	armed.emit()


func _update_proximity_and_pulse(delta: float) -> void:
	var near_player := _is_alive_player_nearby()
	_proximity_active = near_player

	var pulse_speed: float = 13.5 if near_player else 4.6
	_pulse_timer += delta * pulse_speed
	var pulse_val: float = 0.5 + 0.5 * sin(_pulse_timer)

	if warning_led:
		warning_led.visible = true
		warning_led.color = (
			Color(1.0, lerpf(0.28, 0.72, pulse_val), 0.12, lerpf(0.55, 1.0, pulse_val))
			if near_player
			else Color(1.0, 0.24, 0.14, lerpf(0.32, 0.95, pulse_val))
		)

	if warning_glow:
		warning_glow.visible = true
		var glow_scale: float = lerpf(1.05, 1.65, pulse_val) if near_player else lerpf(0.85, 1.18, pulse_val)
		warning_glow.scale = Vector2(glow_scale, glow_scale)
		warning_glow.modulate = (
			Color(1.0, 0.42, 0.15, lerpf(0.35, 0.88, pulse_val))
			if near_player
			else Color(1.0, 0.22, 0.12, lerpf(0.18, 0.65, pulse_val))
		)

	if proximity_ring:
		proximity_ring.visible = near_player
		if near_player:
			var ring_scale: float = lerpf(0.38, 0.68, pulse_val)
			proximity_ring.scale = Vector2(ring_scale, ring_scale * 0.72)
			proximity_ring.modulate = Color(1.0, 0.55, 0.18, lerpf(0.55, 0.14, pulse_val))


func _is_alive_player_nearby() -> bool:
	if not is_inside_tree():
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return false
	if "is_alive" in player and not player.is_alive:
		return false
	return global_position.distance_to(player.global_position) <= proximity_warning_distance


func is_proximity_warning_active() -> bool:
	return is_armed and not _triggered and not _disarming and _proximity_active


func has_detonated() -> bool:
	return _triggered and not _disarming


func is_disarming() -> bool:
	return _disarming


func _on_body_entered(body: Node2D) -> void:
	if _triggered or _disarming or not is_armed or not is_active:
		return

	if body.is_in_group("player"):
		if "is_alive" in body and not body.is_alive:
			return
		detonate(body)


func detonate(victim: Node2D = null) -> void:
	if _triggered or _disarming or not is_armed:
		return
	_triggered = true
	is_active = false
	_proximity_active = false

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false
	if proximity_ring:
		proximity_ring.visible = false

	if AudioManager:
		AudioManager.play_sfx("explosion")

	_play_explosion_animation()
	exploded.emit()

	if victim:
		if victim.has_method("die"):
			victim.die()
		elif victim.has_method("take_hit"):
			victim.take_hit(1)


func disarm_and_cleanup() -> void:
	if _triggered or _disarming:
		return
	_disarming = true
	_triggered = true
	is_armed = false
	is_active = false
	_proximity_active = false

	if is_in_group("landmines"):
		remove_from_group("landmines")
	if is_in_group("worm_mines"):
		remove_from_group("worm_mines")

	monitoring = false
	monitorable = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if proximity_ring:
		proximity_ring.visible = false

	disarmed.emit()

	if not is_inside_tree():
		queue_free()
		return

	var tween := create_tween()
	if warning_led:
		warning_led.color = Color(1.0, 0.72, 0.25, 0.85)
		tween.parallel().tween_property(warning_led, "color:a", 0.0, 0.24)
	if warning_glow:
		warning_glow.modulate = Color(1.0, 0.68, 0.22, 0.5)
		tween.parallel().tween_property(warning_glow, "modulate:a", 0.0, 0.24)
	if sprite:
		tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.82, 0.55, 0.0), 0.26)
		tween.parallel().tween_property(sprite, "position:y", SPRITE_EMERGE_START_Y, 0.26)
	tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)


func _play_explosion_animation() -> void:
	if sprite:
		sprite.modulate = Color(2.4, 1.9, 1.4, 1.0)

	if scorch_mark:
		scorch_mark.visible = true
		scorch_mark.modulate = Color(1.0, 1.0, 1.0, 0.85)

	if not explosion_fx:
		if sprite:
			sprite.visible = false
		return

	explosion_fx.visible = true
	explosion_fx.modulate = Color.WHITE

	if shrapnel_particles:
		shrapnel_particles.restart()
		shrapnel_particles.emitting = true
	if smoke_particles:
		smoke_particles.restart()
		smoke_particles.emitting = true

	if flash:
		flash.visible = true
		flash.scale = Vector2(0.55, 0.55)
		flash.modulate = Color(1.5, 1.35, 0.85, 1.0)
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "scale", Vector2(1.75, 1.75), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.07)
		flash_tween.tween_callback(func(): if is_instance_valid(flash): flash.visible = false)

	if shockwave:
		shockwave.visible = true
		shockwave.scale = Vector2(0.22, 0.16)
		shockwave.modulate = Color(2.0, 1.65, 1.05, 1.0)
		var shock_tween := create_tween()
		shock_tween.tween_property(shockwave, "scale", Vector2(2.4, 1.7), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shock_tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		shock_tween.tween_callback(func(): if is_instance_valid(shockwave): shockwave.visible = false)

	if fire_core:
		fire_core.visible = true
		fire_core.scale = Vector2(0.25, 0.25)
		fire_core.modulate = Color(2.1, 1.9, 1.3, 1.0)
		var fire_tween := create_tween()
		fire_tween.tween_property(fire_core, "scale", Vector2(1.75, 1.75), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(1.4, 0.6, 0.15, 1.0), 0.09)
		if sprite:
			fire_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.06)
		fire_tween.tween_property(fire_core, "scale", Vector2(2.2, 2.2), 0.30)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(0.2, 0.15, 0.15, 0.0), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fire_tween.tween_callback(func(): if is_instance_valid(fire_core): fire_core.visible = false)

	if fire_plume:
		fire_plume.visible = true
		fire_plume.scale = Vector2(0.2, 0.2)
		fire_plume.modulate = Color(1.75, 1.15, 0.45, 1.0)
		var plume_tween := create_tween()
		plume_tween.tween_interval(0.03)
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.45, 1.45), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(1.0, 0.3, 0.05, 0.9), 0.12)
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.85, 1.85), 0.22)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(0.15, 0.12, 0.12, 0.0), 0.22)
		plume_tween.tween_callback(func(): if is_instance_valid(fire_plume): fire_plume.visible = false)

	_apply_camera_shake(6.5, 0.26)


func _apply_camera_shake(intensity: float = 6.5, duration: float = 0.26) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var cam: Camera2D = viewport.get_camera_2d()
	if not cam:
		return

	var tween := create_tween()
	var steps: int = 6
	for i in range(steps):
		var decay: float = 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity * 0.8, intensity * 0.4) * decay
		)
		tween.tween_property(cam, "offset", offset, duration / float(steps))
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.04)


func reset() -> void:
	_triggered = false
	_disarming = false
	is_active = true
	_proximity_active = false
	_pulse_timer = 0.0
	if not is_in_group("landmines"):
		add_to_group("landmines")
	if not is_in_group("worm_mines"):
		add_to_group("worm_mines")
	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false
	if proximity_ring:
		proximity_ring.visible = false
	if arm_delay <= 0.0:
		_finish_arming()
	else:
		_start_arming()
