class_name SecretHellPlatform
extends AnimatableBody2D

## SecretHellPlatform provides the signature Section E ending mechanism for Level 16: The Platform That Lied.
## Initially indistinguishable from empty space (invisible and non-solid).
## Revealed upon:
## - Route A: Living player lands on or touches the designated middle platform area while alive.
## - Route B: A genuine failed jump attempt into the final gap chasm abyss.
## Once revealed, it becomes permanently visible, solid, and reliable across retries/revives.

signal platform_revealed

@export var platform_size: Vector2 = Vector2(65.0, 20.0)

var is_revealed: bool = false
var _active_tween: Tween = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: NinePatchRect = get_node_or_null("NinePatchRect")
@onready var rune_particles: CPUParticles2D = get_node_or_null("RuneParticles")
@onready var landing_area: Area2D = get_node_or_null("LandingArea")

func _ready() -> void:
	sync_to_physics = false
	_setup_collision()
	GameManager.coins_reset.connect(_on_coins_reset)
	GameManager.player_revived.connect(_on_player_revived)
	reset()

func _setup_collision() -> void:
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
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

	if not landing_area:
		landing_area = get_node_or_null("LandingArea")
	if landing_area:
		if not landing_area.body_entered.is_connected(_on_landing_area_body_entered):
			landing_area.body_entered.connect(_on_landing_area_body_entered)
		var lshape = landing_area.get_node_or_null("CollisionShape2D")
		if lshape and lshape.shape is RectangleShape2D:
			(lshape.shape as RectangleShape2D).size = Vector2(platform_size.x - 4.0, 14.0)
			lshape.position = Vector2(0.0, -7.0)

func _physics_process(_delta: float) -> void:
	if is_revealed:
		return
	if is_inside_tree():
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and _is_valid_landing(player_node):
			reveal_for_landing(player_node)
			return
	if landing_area:
		for body in landing_area.get_overlapping_bodies():
			if _is_valid_landing(body):
				reveal_for_landing(body)
				break

func _on_landing_area_body_entered(body: Node2D) -> void:
	if not is_revealed and _is_valid_landing(body):
		reveal_for_landing(body)

func _is_valid_landing(body: Node2D) -> bool:
	if is_revealed:
		return false
	if not (body.is_in_group("player") or body.name == "Player"):
		return false
	if "_is_alive" in body and not body._is_alive:
		return false

	# The player MUST be falling / descending onto the platform, NOT jumping upward
	var p_vel: Vector2 = Vector2.ZERO
	if "velocity" in body:
		p_vel = body.velocity
	if p_vel.y < 0.0:
		# Player is ascending (jumping upward), cannot be landing on platform
		return false

	var surface_top: float = global_position.y - (platform_size.y * 0.5)
	var left_edge: float = global_position.x - (platform_size.x * 0.5)
	var right_edge: float = global_position.x + (platform_size.x * 0.5)

	# Check horizontal alignment: player's center must be horizontally over the platform
	var px: float = body.global_position.x
	if px < left_edge - 2.0 or px > right_edge + 2.0:
		return false

	# Check vertical alignment: player's feet (global_position.y + 16.0) must be
	# at or crossing the platform's top surface level.
	# If player is jumping overhead (feet well above surface), this is NOT a landing.
	var feet_y: float = body.global_position.y + 16.0
	if feet_y < surface_top - 6.0:
		return false
	# If player is already deep below the platform, they fell past it into the chasm
	if feet_y > surface_top + 30.0:
		return false

	return true

func reveal_for_landing(body: Node2D) -> void:
	reveal()
	if body is CharacterBody2D:
		# Ensure the living player is firmly supported on top of the newly solid platform
		body.velocity.y = 0.0
		var surface_top: float = global_position.y - (platform_size.y * 0.5)
		# Player feet are at origin + 16.0, place origin at surface_top - 16.0
		body.global_position.y = surface_top - 16.0

func reveal() -> void:
	if is_revealed:
		return
	is_revealed = true
	visible = true
	modulate.a = 1.0
	collision_layer = 2 # Terrain layer

	if collision_shape:
		collision_shape.disabled = false
		collision_shape.set_deferred("disabled", false)

	if SaveManager and SaveManager.has_method("set_level_16_secret_revealed"):
		SaveManager.set_level_16_secret_revealed(true)

	AudioManager.play_sfx("unlock")
	platform_revealed.emit()

	if rune_particles:
		rune_particles.emitting = true

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = create_tween().set_parallel(true)
	if visual_rect:
		visual_rect.self_modulate = Color(1.0, 0.35, 0.45, 1.0) # Bright crimson ignition
		_active_tween.tween_property(visual_rect, "self_modulate", Color(0.9, 0.8, 0.85, 1.0), 0.45)

func set_revealed_instant(revealed: bool) -> void:
	is_revealed = revealed
	if is_revealed:
		visible = true
		modulate.a = 1.0
		collision_layer = 2 # Terrain layer
		if collision_shape:
			collision_shape.disabled = false
			collision_shape.set_deferred("disabled", false)
		if visual_rect:
			visual_rect.self_modulate = Color(0.9, 0.8, 0.85, 1.0)
		if rune_particles:
			rune_particles.emitting = false
	else:
		visible = false
		modulate.a = 0.0
		collision_layer = 0 # Non-collidable
		if collision_shape:
			collision_shape.disabled = true
			collision_shape.set_deferred("disabled", true)
		if visual_rect:
			visual_rect.self_modulate = Color(0.9, 0.8, 0.85, 1.0)
		if rune_particles:
			rune_particles.emitting = false

func reset() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	set_revealed_instant(false)
	if SaveManager and SaveManager.has_method("set_level_16_secret_revealed"):
		SaveManager.set_level_16_secret_revealed(false)

func _on_coins_reset() -> void:
	reset()

func _on_player_revived(_pos: Vector2) -> void:
	# Revive continues the current attempt; preserve current discovery state
	pass
