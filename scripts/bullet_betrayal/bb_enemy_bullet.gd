class_name BulletBetrayalEnemyBullet
extends Area2D

## Projectile fired by enemy soldiers in Bullet Betrayal.

@export var speed: float = 260.0
@export var damage: int = 1
@export var max_lifetime: float = 2.2

var direction: Vector2 = Vector2.LEFT
var _lifetime: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_update_rotation()

func setup(dir: Vector2, start_pos: Vector2) -> void:
	direction = dir.normalized()
	global_position = start_pos
	_update_rotation()

func _update_rotation() -> void:
	if sprite:
		# Sprite points left by default
		sprite.flip_h = (direction.x > 0)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_impact_and_free()
	elif body is StaticBody2D or body is TileMap:
		_impact_and_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		var p = area.owner if area.owner else area
		if p and p.has_method("take_damage"):
			p.take_damage(damage)
		_impact_and_free()

func _impact_and_free() -> void:
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.04)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.04)
	tween.tween_callback(queue_free)
