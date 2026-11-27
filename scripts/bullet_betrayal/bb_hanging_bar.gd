class_name BulletBetrayalHangingBar
extends Area2D

## Overhead grab-and-traverse steel girder bar for Bullet Betrayal (World 2 Stage 10).
## Players can jump up to grab the rail, hang suspended above ground hazards,
## traverse horizontally left/right while shooting, and release via jump or edges.

signal player_grabbed(bar: Node2D)
signal player_released(bar: Node2D)

@export var bar_width: float = 220.0
@export var hang_offset_y: float = 18.0
@export var accent_color: Color = Color(0.98, 0.72, 0.20, 1.0)

var is_occupied: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var rail_body: ColorRect = $Visuals/RailBody
@onready var rail_trim: ColorRect = $Visuals/RailTrim
@onready var grab_glow: ColorRect = $Visuals/GrabGlow
@onready var left_cap: ColorRect = $Visuals/LeftCap
@onready var right_cap: ColorRect = $Visuals/RightCap


func _ready() -> void:
	add_to_group("hanging_bars")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	_apply_bar_dimensions()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _apply_bar_dimensions() -> void:
	var half_w: float = bar_width * 0.5
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape.duplicate() as RectangleShape2D
		rect.size = Vector2(bar_width, 28.0)
		collision_shape.shape = rect
		collision_shape.position = Vector2(0.0, 10.0)

	if rail_body:
		rail_body.offset_left = -half_w
		rail_body.offset_right = half_w
	if rail_trim:
		rail_trim.offset_left = -half_w + 4.0
		rail_trim.offset_right = half_w - 4.0
	if grab_glow:
		grab_glow.offset_left = -half_w + 6.0
		grab_glow.offset_right = half_w - 6.0
		grab_glow.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.28)
	if left_cap:
		left_cap.offset_left = -half_w - 4.0
		left_cap.offset_right = -half_w + 6.0
	if right_cap:
		right_cap.offset_left = half_w - 6.0
		right_cap.offset_right = half_w + 4.0


func get_min_x() -> float:
	return global_position.x - (bar_width * 0.5)


func get_max_x() -> float:
	return global_position.x + (bar_width * 0.5)


func get_hang_y() -> float:
	return global_position.y + hang_offset_y


func set_occupied(active: bool) -> void:
	if is_occupied == active:
		return
	is_occupied = active
	if grab_glow:
		grab_glow.color = (
			Color(0.25, 0.96, 1.0, 0.72)
			if active
			else Color(accent_color.r, accent_color.g, accent_color.b, 0.28)
		)
	if active:
		player_grabbed.emit(self)
	else:
		player_released.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("register_hanging_bar"):
		body.register_hanging_bar(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_hanging_bar"):
		body.unregister_hanging_bar(self)
