class_name IndustrialCrusher
extends Node2D

## Heavy Industrial Pneumatic Crusher for World 3: Rage Factory
## Timed 6-state machine: IDLE -> WARNING -> DESCENDING -> ACTIVE -> RETRACTING -> RESET
## Synchronized visual body and lethal collision area with clear reaction windows.
## Resets cleanly on level retry.

signal crusher_warned
signal crusher_slammed
signal crusher_retracted

enum State {
	IDLE,
	WARNING,
	DESCENDING,
	ACTIVE,
	RETRACTING,
	RESET
}

@export var travel_distance: float = 120.0
@export var warning_duration: float = 0.7
@export var slam_duration: float = 0.15
@export var active_duration: float = 0.6
@export var retract_duration: float = 0.9
@export var reset_delay: float = 0.4
@export var auto_cycle: bool = true
@export var auto_cycle_offset: float = 0.0
@export var block_size: Vector2 = Vector2(80.0, 36.0)

var current_state: State = State.IDLE
var _state_timer: float = 0.0
var _initial_pos: Vector2
var _retracted_pos: Vector2
var _slammed_pos: Vector2
var _current_block_y: float = 0.0
var _shake_offset_x: float = 0.0
var _tween: Tween = null

@onready var crusher_body: AnimatableBody2D = get_node_or_null("CrusherBody")
@onready var body_collision: CollisionShape2D = get_node_or_null("CrusherBody/CollisionShape2D")
@onready var hazard_area: Area2D = get_node_or_null("CrusherBody/HazardArea")
@onready var hazard_collision: CollisionShape2D = get_node_or_null("CrusherBody/HazardArea/CollisionShape2D")

func _ready() -> void:
	_initial_pos = global_position
	_retracted_pos = Vector2.ZERO
	_slammed_pos = Vector2(0.0, travel_distance)
	GameManager.coins_reset.connect(reset)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(func(_pos): reset())
	_setup_nodes()
	reset()

func _setup_nodes() -> void:
	if not crusher_body:
		crusher_body = AnimatableBody2D.new()
		crusher_body.name = "CrusherBody"
		crusher_body.sync_to_physics = false
		crusher_body.collision_layer = 2
		crusher_body.collision_mask = 0
		add_child(crusher_body)

	if not body_collision:
		body_collision = CollisionShape2D.new()
		body_collision.name = "CollisionShape2D"
		var r := RectangleShape2D.new()
		r.size = block_size
		body_collision.shape = r
		crusher_body.add_child(body_collision)

	if not hazard_area:
		hazard_area = Area2D.new()
		hazard_area.name = "HazardArea"
		hazard_area.collision_layer = 4
		hazard_area.collision_mask = 1
		hazard_area.body_entered.connect(_on_hazard_body_entered)
		crusher_body.add_child(hazard_area)

	if not hazard_collision:
		hazard_collision = CollisionShape2D.new()
		hazard_collision.name = "CollisionShape2D"
		var hr := RectangleShape2D.new()
		hr.size = Vector2(block_size.x - 4.0, 14.0)
		hazard_collision.shape = hr
		hazard_collision.position = Vector2(0.0, (block_size.y * 0.5) - 6.0)
		hazard_area.add_child(hazard_collision)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			if auto_cycle:
				_state_timer -= delta
				if _state_timer <= 0.0:
					_trigger_warning()

		State.WARNING:
			_state_timer -= delta
			_shake_offset_x = randf_range(-2.0, 2.0)
			if crusher_body:
				crusher_body.position.x = _retracted_pos.x + _shake_offset_x
			if _state_timer <= 0.0:
				_shake_offset_x = 0.0
				if crusher_body:
					crusher_body.position.x = _retracted_pos.x
				_start_descending()

		State.DESCENDING:
			_check_crusher_collision()

		State.ACTIVE:
			_check_crusher_collision()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_start_retracting()

		State.RETRACTING:
			pass

		State.RESET:
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_state_timer = 0.0
				if auto_cycle:
					_trigger_warning()

	if crusher_body:
		_current_block_y = crusher_body.position.y
	queue_redraw()

func _trigger_warning() -> void:
	current_state = State.WARNING
	_state_timer = warning_duration
	if hazard_collision:
		hazard_collision.disabled = true
	crusher_warned.emit()
	AudioManager.play_sfx("warning")

func _start_descending() -> void:
	current_state = State.DESCENDING
	if hazard_collision:
		hazard_collision.disabled = false

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(crusher_body, "position:y", _slammed_pos.y, slam_duration)
	_tween.tween_callback(_on_slam_reached)

func _on_slam_reached() -> void:
	current_state = State.ACTIVE
	_state_timer = active_duration
	crusher_slammed.emit()
	AudioManager.play_sfx("land")
	_check_crusher_collision()

func _start_retracting() -> void:
	current_state = State.RETRACTING
	if hazard_collision:
		hazard_collision.disabled = true

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(crusher_body, "position:y", _retracted_pos.y, retract_duration)
	_tween.tween_callback(_on_retract_reached)

func _on_retract_reached() -> void:
	current_state = State.RESET
	_state_timer = reset_delay
	crusher_retracted.emit()

func _on_hazard_body_entered(body: Node2D) -> void:
	if current_state == State.DESCENDING or current_state == State.ACTIVE:
		_kill_player(body)

func _check_crusher_collision() -> void:
	if current_state != State.DESCENDING and current_state != State.ACTIVE:
		return
	if hazard_area:
		for b in hazard_area.get_overlapping_bodies():
			_kill_player(b)

	var player = _get_active_player()
	if player and is_instance_valid(player) and player.has_method("die") and player._is_alive:
		var h_center := hazard_collision.global_position if hazard_collision else crusher_body.global_position
		var h_size := Vector2(block_size.x - 4.0, 16.0)
		var h_rect := Rect2(h_center - h_size * 0.5, h_size)
		var p_rect := Rect2(player.global_position - Vector2(8.0, 12.0), Vector2(16.0, 24.0))
		if h_rect.intersects(p_rect):
			_kill_player(player)

func _get_active_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p.has_method("die"):
			return p
	return null

func _kill_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func _draw() -> void:
	# 1. Ceiling Mount Bracket
	var mount_rect := Rect2(-30.0, -14.0, 60.0, 14.0)
	draw_rect(mount_rect, Color(0.18, 0.20, 0.25, 1.0))
	draw_rect(mount_rect, Color(0.35, 0.38, 0.45, 1.0), false, 2.0)

	# 2. Hydraulic Piston Stem connecting ceiling to crusher block
	var stem_top := 0.0
	var stem_bottom := _current_block_y - (block_size.y * 0.5)
	if stem_bottom > stem_top:
		var stem_w := 14.0
		var stem_rect := Rect2(-stem_w * 0.5, stem_top, stem_w, stem_bottom - stem_top)
		draw_rect(stem_rect, Color(0.45, 0.48, 0.55, 1.0))
		draw_rect(stem_rect, Color(0.25, 0.28, 0.35, 1.0), false, 1.5)

	# 3. Crushing Block Rendering
	var block_half_w := block_size.x * 0.5
	var block_half_h := block_size.y * 0.5
	var block_rect := Rect2(-block_half_w + _shake_offset_x, _current_block_y - block_half_h, block_size.x, block_size.y)

	# Heavy dark steel block
	draw_rect(block_rect, Color(0.14, 0.16, 0.20, 1.0))
	draw_rect(block_rect, Color(0.35, 0.38, 0.48, 1.0), false, 2.0)

	# Yellow & Black Hazard Stripes on front face
	var stripe_rect := Rect2(-block_half_w + 4.0 + _shake_offset_x, _current_block_y - 6.0, block_size.x - 8.0, 12.0)
	draw_rect(stripe_rect, Color(0.1, 0.1, 0.1, 1.0))
	var stripe_w := 10.0
	var stripes_count := int(stripe_rect.size.x / stripe_w)
	for i in range(stripes_count):
		if i % 2 == 0:
			var sx := stripe_rect.position.x + (i * stripe_w)
			draw_line(Vector2(sx, stripe_rect.position.y), Vector2(sx + 6.0, stripe_rect.position.y + stripe_rect.size.y), Color(0.95, 0.75, 0.1, 1.0), 3.0)

	# Warning Light Beacon on Top Center of Block
	var beacon_color: Color
	if current_state == State.WARNING:
		beacon_color = Color(1.0, 0.2, 0.1, 1.0) if fmod(_state_timer * 12.0, 1.0) < 0.5 else Color(1.0, 0.85, 0.1, 1.0)
	elif current_state == State.DESCENDING or current_state == State.ACTIVE:
		beacon_color = Color(1.0, 0.1, 0.1, 1.0) # Bright red
	else:
		beacon_color = Color(0.2, 0.8, 0.4, 0.7) # Muted green/standby

	draw_circle(Vector2(_shake_offset_x, _current_block_y - block_half_h + 4.0), 4.0, beacon_color)

	# Bottom Crushing Teeth
	var tooth_count := int(block_size.x / 12.0)
	var tooth_spacing := block_size.x / float(tooth_count)
	for i in range(tooth_count):
		var tx := -block_half_w + (i * tooth_spacing) + (tooth_spacing * 0.5) + _shake_offset_x
		var ty := _current_block_y + block_half_h
		var tooth_color := Color(0.9, 0.2, 0.2, 1.0) if (current_state == State.DESCENDING or current_state == State.ACTIVE) else Color(0.5, 0.5, 0.5, 1.0)
		draw_line(Vector2(tx - 3.0, ty), Vector2(tx, ty + 5.0), tooth_color, 2.0)
		draw_line(Vector2(tx, ty + 5.0), Vector2(tx + 3.0, ty), tooth_color, 2.0)

func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	current_state = State.IDLE
	_state_timer = auto_cycle_offset if auto_cycle_offset > 0.0 else 0.0
	_shake_offset_x = 0.0
	_current_block_y = _retracted_pos.y
	if crusher_body:
		crusher_body.position = _retracted_pos
	if hazard_collision:
		hazard_collision.disabled = true
	queue_redraw()
