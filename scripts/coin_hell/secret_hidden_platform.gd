class_name SecretHiddenPlatform
extends AnimatableBody2D

## SecretHiddenPlatform provides the signature Phase E ending mechanism for Level 15: Rage Furnace.
## Initially indistinguishable from empty space (invisible and non-solid).
## Revealed exclusively upon the player's first genuine failed attempt at the impossible final gap.
## Once revealed, it becomes permanently visible, solid, and reliable across retries.

signal platform_revealed

@export var platform_size: Vector2 = Vector2(65.0, 20.0)

var is_revealed: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: NinePatchRect = get_node_or_null("NinePatchRect")

func _ready() -> void:
	sync_to_physics = false
	collision_layer = 2 # Terrain layer
	collision_mask = 0

	_setup_collision()
	GameManager.coins_reset.connect(_on_coins_reset)
	GameManager.player_revived.connect(_on_player_revived)

	# Check persistent discovery state
	if SaveManager and SaveManager.has_method("is_level_15_secret_revealed") and SaveManager.is_level_15_secret_revealed():
		set_revealed_instant(true)
	else:
		set_revealed_instant(false)

func _setup_collision() -> void:
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = platform_size
		collision_shape.shape = rect
		add_child(collision_shape)
	elif collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = platform_size

	if visual_rect:
		visual_rect.offset_left = -platform_size.x * 0.5
		visual_rect.offset_top = -platform_size.y * 0.5
		visual_rect.offset_right = platform_size.x * 0.5
		visual_rect.offset_bottom = platform_size.y * 0.5

func reveal() -> void:
	if is_revealed:
		return
	is_revealed = true
	if collision_shape:
		collision_shape.disabled = false
		collision_shape.set_deferred("disabled", false)

	if SaveManager and SaveManager.has_method("set_level_15_secret_revealed"):
		SaveManager.set_level_15_secret_revealed(true)

	AudioManager.play_sfx("unlock")
	platform_revealed.emit()

	# Visual ignition reveal animation
	visible = true
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	if visual_rect:
		visual_rect.self_modulate = Color(1.0, 0.7, 0.2, 1.0) # Ember orange flash
		tween.chain().tween_property(visual_rect, "self_modulate", Color(0.65, 0.42, 0.35, 1.0), 0.5)

func set_revealed_instant(revealed: bool) -> void:
	is_revealed = revealed
	if is_revealed:
		visible = true
		modulate.a = 1.0
		if collision_shape:
			collision_shape.disabled = false
			collision_shape.set_deferred("disabled", false)
		if visual_rect:
			visual_rect.self_modulate = Color(0.65, 0.42, 0.35, 1.0)
	else:
		visible = false
		modulate.a = 0.0
		if collision_shape:
			collision_shape.disabled = true
			collision_shape.set_deferred("disabled", true)

func _on_coins_reset() -> void:
	# Preserve discovery on ordinary retry/reset
	if SaveManager and SaveManager.has_method("is_level_15_secret_revealed") and SaveManager.is_level_15_secret_revealed():
		set_revealed_instant(true)

func _on_player_revived(_pos: Vector2) -> void:
	if SaveManager and SaveManager.has_method("is_level_15_secret_revealed") and SaveManager.is_level_15_secret_revealed():
		set_revealed_instant(true)
