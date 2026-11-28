extends Area2D
class_name BulletBetrayalIcePatch
## Slippery glacier ice surface patch for Stage 11.
## Registers and unregisters opt-in ice traction on BulletBetrayalPlayer without affecting other stages.

@export var patch_width: float = 96.0
@export var patch_height: float = 18.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var surface_sprite: Sprite2D = $SurfaceSprite
@onready var highlight_bar: ColorRect = $HighlightBar

var _tracked_players: Array[Node2D] = []
var _shimmer_time: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("ice_patches")
	_apply_dimensions()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	for player in _tracked_players:
		if is_instance_valid(player) and player.has_method("unregister_ice_surface"):
			player.call("unregister_ice_surface", self)
	_tracked_players.clear()

func _apply_dimensions() -> void:
	var w := maxf(16.0, patch_width)
	var h := maxf(8.0, patch_height)
	if collision_shape:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(w, h)
		collision_shape.shape = rect
		# Span just above the surface so grounded player feet stay registered.
		collision_shape.position = Vector2(0.0, -h * 0.5 + 3.0)
	if surface_sprite:
		surface_sprite.region_enabled = true
		surface_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		surface_sprite.region_rect = Rect2(0.0, 0.0, w, 10.0)
		surface_sprite.position = Vector2(0.0, 1.0)
	if highlight_bar:
		highlight_bar.offset_left = -w * 0.5
		highlight_bar.offset_right = w * 0.5
		highlight_bar.offset_top = -3.0
		highlight_bar.offset_bottom = -1.0

func _process(delta: float) -> void:
	if not highlight_bar:
		return
	_shimmer_time += delta * 2.2
	highlight_bar.modulate.a = 0.45 + 0.30 * sin(_shimmer_time)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if not body or not body.is_in_group("player"):
			continue
		if "is_alive" in body and not body.is_alive:
			continue
		if body.has_method("has_ice_surface") and not bool(body.call("has_ice_surface", self)):
			_on_body_entered(body)

func _on_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	if body is Node2D and not _tracked_players.has(body):
		_tracked_players.append(body)
	if body.has_method("register_ice_surface"):
		body.call("register_ice_surface", self)

func _on_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	if body is Node2D:
		_tracked_players.erase(body)
	if body.has_method("unregister_ice_surface"):
		body.call("unregister_ice_surface", self)
