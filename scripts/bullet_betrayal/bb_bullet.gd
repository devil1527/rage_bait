class_name BulletBetrayalBullet
extends Area2D

## Projectile fired by the player commando in Bullet Betrayal.

@export var speed: float = 620.0
@export var damage: int = 1
@export var max_lifetime: float = 1.4

var direction: Vector2 = Vector2.RIGHT
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
		if direction.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Impact with solid terrain or static geometry
	if body is StaticBody2D or body is TileMap:
		_impact_and_free()

func _on_area_entered(area: Area2D) -> void:
	# Impact with enemy hurtbox
	if area.is_in_group("enemy_hurtbox") or area.owner and area.owner.is_in_group("enemies"):
		var enemy = area.owner if area.owner and area.owner.is_in_group("enemies") else area
		if enemy and enemy.has_method("take_hit"):
			enemy.take_hit(damage)
		elif area.has_method("take_hit"):
			area.take_hit(damage)
		_impact_and_free()

func _impact_and_free() -> void:
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	# Quick fade / spark effect
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.04)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.04)
	tween.tween_callback(queue_free)
