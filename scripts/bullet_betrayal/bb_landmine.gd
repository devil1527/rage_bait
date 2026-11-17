class_name BulletBetrayalLandmine
extends Area2D

## Tactical Landmine for Bullet Betrayal (Operation Dead Ground).
## Ground-aligned explosive device with subtle pulsing LED telegraph.
## Triggers strictly on physical contact with the player.
## Detonates once, deals lethal 1-hit damage, plays concussive explosion SFX
## and visual shockwave animation. Completely immune to gunfire.

signal exploded

@export var is_active: bool = true

var _triggered: bool = false
var _pulse_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var warning_led: ColorRect = get_node_or_null("WarningLED")
@onready var explosion_fx: Node2D = get_node_or_null("ExplosionFX")
@onready var shockwave_circle: ColorRect = get_node_or_null("ExplosionFX/Shockwave")
@onready var fire_core: ColorRect = get_node_or_null("ExplosionFX/FireCore")

func _ready() -> void:
	# Layer 0 (not a solid body), Mask 1 (detects player on layer 1)
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

	if explosion_fx:
		explosion_fx.visible = false

	if warning_led:
		warning_led.visible = true

func _process(delta: float) -> void:
	if _triggered or not is_active:
		return
	
	# Subtle rhythmic pulse of the sensor LED (warning telegraph)
	if warning_led:
		_pulse_timer += delta * 3.5
		var alpha: float = (sin(_pulse_timer) + 1.0) * 0.4 + 0.2
		warning_led.modulate.a = alpha

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
		# Flash white/charred before vanishing
		sprite.modulate = Color(2.0, 1.5, 0.8, 1.0)

	if not explosion_fx:
		if sprite:
			sprite.visible = false
		return

	explosion_fx.visible = true
	explosion_fx.scale = Vector2(0.2, 0.2)
	explosion_fx.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var tween := create_tween()
	# Rapid explosive expansion
	tween.tween_property(explosion_fx, "scale", Vector2(1.8, 1.8), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if sprite:
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.08)
	# Shockwave dissipating and fading
	tween.tween_property(explosion_fx, "scale", Vector2(2.4, 2.4), 0.22)
	tween.parallel().tween_property(explosion_fx, "modulate:a", 0.0, 0.22)
	tween.tween_callback(func():
		if is_instance_valid(explosion_fx):
			explosion_fx.visible = false
		if is_instance_valid(sprite):
			sprite.visible = false
	)

func reset() -> void:
	_triggered = false
	is_active = true
	_pulse_timer = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.modulate = Color.WHITE
	if warning_led:
		warning_led.visible = true
	if explosion_fx:
		explosion_fx.visible = false
