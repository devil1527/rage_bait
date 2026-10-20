class_name FakeSafePlatform
extends StaticBody2D

## TRICK B — THE FAKE SAFE LANDING / COIN-TRIGGERED SPIKE TRAP
## A platform with concealed pop-up spikes.
## Can trigger immediately or via coin collection with a fair visual warning period.
## Resets cleanly on retry.

signal trap_triggered
signal warning_started

@export var is_coin_triggered: bool = false
@export var warning_duration: float = 0.5

var _initial_pos: Vector2
var _triggered: bool = false
var _active_spikes: bool = false
var _in_warning: bool = false
var _warning_timer: float = 0.0
var _warning_tween: Tween = null

@onready var visual_rect: NinePatchRect = get_node_or_null("NinePatchRect")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var trigger_area: Area2D = get_node_or_null("TriggerArea")
@onready var spikes_area: Area2D = get_node_or_null("SpikesArea")
@onready var spikes_sprite: Sprite2D = get_node_or_null("SpikesArea/Sprite2D")
@onready var spikes_collision: CollisionShape2D = get_node_or_null("SpikesArea/CollisionShape2D")

func _ready() -> void:
	_initial_pos = global_position
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	if spikes_area:
		spikes_area.body_entered.connect(_on_spikes_body_entered)
	GameManager.coins_reset.connect(reset)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(func(_pos): reset())
	_setup_initial_spikes_state()

func _setup_initial_spikes_state() -> void:
	_triggered = false
	_active_spikes = false
	_in_warning = false
	_warning_timer = 0.0
	if _warning_tween:
		_warning_tween.kill()
		_warning_tween = null
	if spikes_sprite:
		spikes_sprite.visible = false
		spikes_sprite.position.y = -14.0  # Fully aligned with spike collision shape
		spikes_sprite.z_index = 2         # Ensure spikes render in front of platform graphics
		spikes_sprite.scale = Vector2.ONE
		spikes_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
	if spikes_collision:
		spikes_collision.disabled = true
		spikes_collision.position.y = -14.0

func _physics_process(delta: float) -> void:
	if _in_warning:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			_in_warning = false
			_activate_spikes()
	elif _active_spikes:
		_check_spike_collision()

func _on_trigger_body_entered(body: Node2D) -> void:
	if is_coin_triggered:
		return
	if not _triggered and not _in_warning and not _active_spikes and (body.is_in_group("player") or body.name == "Player"):
		trigger_trap()

func trigger_from_coin() -> void:
	if _triggered or _in_warning or _active_spikes:
		return
	trigger_trap_with_warning(warning_duration)

func trigger_trap_with_warning(duration: float = 0.5) -> void:
	if _triggered or _in_warning or _active_spikes:
		return
	_in_warning = true
	_warning_timer = duration
	warning_started.emit()
	AudioManager.play_sfx("warning")
	
	# Clear visual warning state:
	# Spikes peek slightly (4px above surface) with an amber/red pulsing tell
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = -4.0
		spikes_sprite.z_index = 2
		spikes_sprite.modulate = Color(1.0, 0.6, 0.1, 0.9)
		if _warning_tween:
			_warning_tween.kill()
		_warning_tween = create_tween()
		_warning_tween.set_loops()
		_warning_tween.tween_property(spikes_sprite, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.1)
		_warning_tween.tween_property(spikes_sprite, "modulate", Color(1.0, 0.85, 0.2, 0.85), 0.1)
	
	# Lethal collision remains strictly DISABLED during warning period!
	if spikes_collision:
		spikes_collision.disabled = true

func trigger_trap() -> void:
	_activate_spikes()

func _activate_spikes() -> void:
	if _warning_tween:
		_warning_tween.kill()
		_warning_tween = null
	_in_warning = false
	_triggered = true
	_active_spikes = true
	trap_triggered.emit()
	AudioManager.play_sfx("warning")
	
	# Make spikes artwork fully visible above platform before/during collision check
	if spikes_sprite:
		spikes_sprite.visible = true
		spikes_sprite.position.y = -14.0
		spikes_sprite.z_index = 2
		spikes_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
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
