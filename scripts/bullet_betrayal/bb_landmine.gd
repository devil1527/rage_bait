class_name BulletBetrayalLandmine
extends Area2D

## Tactical Landmine for Bullet Betrayal (Operation Dead Ground).
## Ground-aligned explosive device with high-visibility digital blinking red light.
## Triggers strictly on physical contact with the player.
## Detonates once, deals lethal 1-hit damage, plays concussive explosion SFX,
## triggers cinematic multi-layered blast FX (fireball plumes, expanding shockwave,
## shrapnel sparks, rising smoke, ground scorch mark, and camera shake).
## Completely immune to gunfire.

signal exploded

const BLINK_CYCLE: float = 0.65 # Rhythm: ~1.5 Hz double-pip military hazard strobe

@export var is_active: bool = true

var _triggered: bool = false
var _blink_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var warning_led: ColorRect = get_node_or_null("WarningLED")
@onready var warning_glow: Sprite2D = get_node_or_null("WarningGlow")
@onready var scorch_mark: Sprite2D = get_node_or_null("ScorchMark")
@onready var explosion_fx: Node2D = get_node_or_null("ExplosionFX")
@onready var flash: CanvasItem = get_node_or_null("ExplosionFX/Flash")
@onready var shockwave: CanvasItem = get_node_or_null("ExplosionFX/Shockwave")
@onready var fire_core: CanvasItem = get_node_or_null("ExplosionFX/FireCore")
@onready var fire_plume: CanvasItem = get_node_or_null("ExplosionFX/FirePlume")
@onready var shrapnel_particles: CPUParticles2D = get_node_or_null("ExplosionFX/ShrapnelParticles")
@onready var smoke_particles: CPUParticles2D = get_node_or_null("ExplosionFX/SmokeParticles")

func _ready() -> void:
	# Layer 0 (not a solid body), Mask 1 (detects player on layer 1)
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

	if explosion_fx:
		explosion_fx.visible = false

	if scorch_mark:
		scorch_mark.visible = false

	if warning_led:
		warning_led.visible = true

	if warning_glow:
		warning_glow.visible = true

func _process(delta: float) -> void:
	if _triggered or not is_active:
		return

	# High-visibility tactical strobe rhythm:
	# 0.00s - 0.12s: Flash 1 (Bright ON)
	# 0.12s - 0.20s: Gap 1 (OFF)
	# 0.20s - 0.32s: Flash 2 (Bright ON)
	# 0.32s - 0.65s: Rest (Dark OFF)
	_blink_timer += delta
	if _blink_timer >= BLINK_CYCLE:
		_blink_timer = fmod(_blink_timer, BLINK_CYCLE)

	var is_flashing: bool = (_blink_timer < 0.12) or (_blink_timer >= 0.20 and _blink_timer < 0.32)

	if is_flashing:
		if warning_led:
			warning_led.color = Color(1.0, 0.2, 0.15, 1.0)
			warning_led.modulate = Color(2.0, 1.3, 1.1, 1.0)
		if warning_glow:
			warning_glow.visible = true
			warning_glow.modulate = Color(1.3, 0.25, 0.1, 0.95)
			var pulse: float = 1.0 + 0.25 * sin(_blink_timer * 40.0)
			warning_glow.scale = Vector2(pulse, pulse) * 1.2
	else:
		if warning_led:
			# Dim, dark unpowered diode state
			warning_led.color = Color(0.2, 0.04, 0.04, 0.35)
			warning_led.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if warning_glow:
			warning_glow.visible = false

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not is_active:
		return

	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if body.has_method("is_alive") and not body.is_alive:
			return
		if "is_alive" in body and not body.is_alive:
			return

		detonate(body)

func detonate(victim: Node2D = null) -> void:
	if _triggered:
		return
	_triggered = true

	# Disable collision shape immediately to guarantee single trigger
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false

	# Play concussive explosion sound
	if AudioManager:
		AudioManager.play_sfx("explosion")

	# Trigger visual explosion effect
	_play_explosion_animation()

	# Emit signal
	exploded.emit()

	# Fatal strike to player
	if victim:
		if victim.has_method("die"):
			victim.die()
		elif victim.has_method("take_hit"):
			victim.take_hit(1)

func _play_explosion_animation() -> void:
	if sprite:
		# Rapid white/char flash then hide
		sprite.modulate = Color(2.5, 2.0, 1.5, 1.0)

	if scorch_mark:
		scorch_mark.visible = true
		scorch_mark.modulate.a = 0.9

	if not explosion_fx:
		if sprite:
			sprite.visible = false
		return

	explosion_fx.visible = true
	explosion_fx.modulate = Color.WHITE

	# Trigger high-speed shrapnel & rising smoke particles
	if shrapnel_particles:
		shrapnel_particles.restart()
		shrapnel_particles.emitting = true
	if smoke_particles:
		smoke_particles.restart()
		smoke_particles.emitting = true

	# 1. Flash burst (0.07s)
	if flash:
		flash.visible = true
		flash.scale = Vector2(0.6, 0.6)
		flash.modulate = Color(1.5, 1.4, 0.9, 1.0)
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.07)
		flash_tween.tween_callback(func(): if is_instance_valid(flash): flash.visible = false)

	# 2. Expanding shockwave ring (0.28s)
	if shockwave:
		shockwave.visible = true
		shockwave.scale = Vector2(0.2, 0.15)
		shockwave.modulate = Color(2.0, 1.8, 1.2, 1.0)
		var shock_tween := create_tween()
		shock_tween.tween_property(shockwave, "scale", Vector2(2.5, 1.8), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shock_tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		shock_tween.tween_callback(func(): if is_instance_valid(shockwave): shockwave.visible = false)

	# 3. Fireball core explosion & dissipation (0.42s)
	if fire_core:
		fire_core.visible = true
		fire_core.scale = Vector2(0.25, 0.25)
		fire_core.modulate = Color(2.2, 2.0, 1.4, 1.0)
		var fire_tween := create_tween()
		# Rapid eruption
		fire_tween.tween_property(fire_core, "scale", Vector2(1.8, 1.8), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(1.4, 0.6, 0.15, 1.0), 0.09)
		if sprite:
			fire_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.06)
		# Expansion and dissipation into smoke
		fire_tween.tween_property(fire_core, "scale", Vector2(2.3, 2.3), 0.32)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(0.2, 0.15, 0.15, 0.0), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fire_tween.tween_callback(func(): if is_instance_valid(fire_core): fire_core.visible = false)

	# 4. Asymmetrical secondary plume (0.38s)
	if fire_plume:
		fire_plume.visible = true
		fire_plume.scale = Vector2(0.2, 0.2)
		fire_plume.modulate = Color(1.8, 1.2, 0.5, 1.0)
		var plume_tween := create_tween()
		plume_tween.tween_interval(0.03) # Slight staggered pop
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(1.0, 0.3, 0.05, 0.9), 0.12)
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.9, 1.9), 0.23)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(0.15, 0.12, 0.12, 0.0), 0.23)
		plume_tween.tween_callback(func(): if is_instance_valid(fire_plume): fire_plume.visible = false)

	# 5. Screen shake
	_apply_camera_shake(7.0, 0.28)

func _apply_camera_shake(intensity: float = 7.0, duration: float = 0.28) -> void:
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
	is_active = true
	_blink_timer = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.modulate = Color.WHITE
	if warning_led:
		warning_led.visible = true
	if warning_glow:
		warning_glow.visible = true
	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false
