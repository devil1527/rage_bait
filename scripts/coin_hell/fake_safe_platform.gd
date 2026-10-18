class_name FakeSafePlatform
extends StaticBody2D

## TRICK B — THE FAKE SAFE LANDING
## A platform that appears completely safe and ordinary at a glance.
## Contains concealed pop-up spikes with NO visible red warnings or countdowns beforehand.
## When the player crosses the trigger point, the spikes emerge immediately with a
## fast, consistent pop-up animation and active lethal collision from all directions.
## Resets cleanly on retry.

signal trap_triggered

var _initial_pos: Vector2
var _triggered: bool = false
var _active_spikes: bool = false

@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var spikes_area: Area2D = $SpikesArea
@onready var spikes_sprite: Sprite2D = $SpikesArea/Sprite2D
@onready var spikes_collision: CollisionShape2D = $SpikesArea/CollisionShape2D

func _ready() -> void:
	_initial_pos = global_position
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	if spikes_area:
		spikes_area.body_entered.connect(_on_spikes_body_entered)
	GameManager.coins_reset.connect(reset)
	_setup_initial_spikes_state()

func _setup_initial_spikes_state() -> void:
	_triggered = false
	_active_spikes = false
	if spikes_sprite:
		spikes_sprite.visible = false
		spikes_sprite.position.y = -14.0  # Fully aligned with spike collision shape
		spikes_sprite.z_index = 2         # Ensure spikes render in front of platform graphics
		spikes_sprite.scale = Vector2.ONE
		spikes_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
	if spikes_collision:
		spikes_collision.disabled = true
		spikes_collision.position.y = -14.0

func _physics_process(_delta: float) -> void:
	if _active_spikes:
		_check_spike_collision()

func _on_trigger_body_entered(body: Node2D) -> void:
	if not _triggered and (body.is_in_group("player") or body.name == "Player"):
		trigger_trap()

func trigger_trap() -> void:
	if _triggered:
		return
	_triggered = true
	_active_spikes = true
	trap_triggered.emit()
	AudioManager.play_sfx("warning")
	
	# Make spikes artwork fully visible above platform before/during collision check
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = -14.0
		spikes_sprite.z_index = 2
		spikes_sprite.scale = Vector2(1.15, 1.25)
		var tween := create_tween()
		tween.tween_property(spikes_sprite, "scale", Vector2.ONE, 0.06)
	
	# Activate collision matching the emerged spikes exactly
	if spikes_collision:
		spikes_collision.disabled = false
		spikes_collision.position.y = -14.0
	
	# Immediate lethality check for any player already touching or in the trap area
	_check_spike_collision()

func _get_active_player() -> Node2D:
	var player = get_node_or_null("../../Player")
	if player and is_instance_valid(player) and player.has_method("die"):
		return player
	if owner:
		player = owner.get_node_or_null("Player")
		if player and is_instance_valid(player) and player.has_method("die"):
			return player
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p.has_method("die"):
			return p
	return null

func _check_spike_collision() -> void:
	if not _active_spikes:
		return
	
	# 1. Physics server overlapping bodies check
	if spikes_area:
		for body in spikes_area.get_overlapping_bodies():
			_kill_player(body)
	
	# 2. Geometric bounding box check against Player
	# Covers touches from any direction (top, side, bottom)
	var player = _get_active_player()
	if player and is_instance_valid(player) and player.has_method("die") and player._is_alive:
		var spike_shape: Shape2D = spikes_collision.shape if spikes_collision else null
		var spike_size: Vector2 = Vector2(34.0, 18.0)
		if spike_shape is RectangleShape2D:
			spike_size = (spike_shape as RectangleShape2D).size
		var spike_center_global: Vector2 = spikes_collision.global_position if spikes_collision else (spikes_area.global_position + Vector2(0.0, -14.0))
		var spike_rect := Rect2(
			spike_center_global - spike_size * 0.5,
			spike_size
		)
		# Player collision shape is 16px wide x 28px high centered at Vector2(0, 2)
		var player_center_global: Vector2 = player.global_position + Vector2(0.0, 2.0)
		var player_rect := Rect2(
			player_center_global - Vector2(8.0, 14.0),
			Vector2(16.0, 28.0)
		)
		if spike_rect.intersects(player_rect):
			_kill_player(player)

func _on_spikes_body_entered(body: Node2D) -> void:
	if _active_spikes:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if not _active_spikes:
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func reset() -> void:
	_setup_initial_spikes_state()
