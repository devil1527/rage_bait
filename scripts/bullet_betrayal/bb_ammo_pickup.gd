class_name BulletBetrayalAmmoPickup
extends Area2D

## Tactical military ammo crate pickup for Bullet Betrayal.

signal collected(amount: int)

@export var ammo_amount: int = 8

var _base_y: float = 0.0
var _is_collected: bool = false
var _initial_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_initial_pos = global_position
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if not _is_collected:
		# Smooth hovering/bobbing motion
		position.y = _base_y + sin(Time.get_ticks_msec() * 0.004) * 3.5

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		_collect(body)

func _on_area_entered(area: Area2D) -> void:
	if _is_collected:
		return
	if area.is_in_group("player_pickup_zone"):
		var p = area.owner if area.owner else area
		if p and p.has_method("add_ammo"):
			_collect(p)

func _collect(player: Node) -> void:
	if _is_collected:
		return
	_is_collected = true
	if player.has_method("add_ammo"):
		player.add_ammo(ammo_amount)
	
	AudioManager.play_sfx("ammo_pickup")
	collected.emit(ammo_amount)
	_spawn_floating_text("+%d AMMO" % ammo_amount)

	# Pickup visual feedback
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _spawn_floating_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.2, 0.05, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.global_position = global_position + Vector2(-24, -20)
	label.top_level = true
	get_parent().add_child(label)

	var tween := label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 25.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func reset() -> void:
	_is_collected = false
	global_position = _initial_pos
	_base_y = position.y
	if sprite:
		sprite.scale = Vector2.ONE
		sprite.modulate.a = 1.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
