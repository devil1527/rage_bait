class_name BulletBetrayalFireHazard
extends Area2D

## Environmental fire hazard for Bullet Betrayal.
## Touching the fire immediately causes one-hit player death.
## Features animated flame flickering and audio/visual hazard cues.

@onready var flame_sprite: Sprite2D = get_node_or_null("FlameSprite")
@onready var emitter_sprite: Sprite2D = get_node_or_null("EmitterSprite")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)
	_start_flame_animation()

func _start_flame_animation() -> void:
	if not flame_sprite:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(flame_sprite, "scale:y", 0.42, 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(flame_sprite, "modulate", Color(1.2, 0.8, 0.4, 0.95), 0.12)
	tween.tween_property(flame_sprite, "scale:y", 0.35, 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(flame_sprite, "modulate", Color(1.0, 0.6, 0.2, 0.85), 0.12)

func _on_body_entered(body: Node2D) -> void:
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
