class_name CeilingCrusher
extends Node2D

## LEVEL 4 CORE MECHANIC: CEILING CRUSHER
## Ceiling-mounted crushing block with a robust 6-state machine:
## IDLE -> TRIGGERED -> DESCENDING -> ACTIVE -> RETRACTING -> RESET -> IDLE
## Matches Neon Ruins aesthetic. Resets cleanly on level retry.

signal crusher_triggered
signal crusher_slammed
signal crusher_retracted

enum State {
	IDLE,
	TRIGGERED,
	DESCENDING,
	ACTIVE,
	RETRACTING,
	RESET
}

@export var travel_distance: float = 120.0
@export var trigger_delay: float = 0.15
@export var slam_duration: float = 0.15
@export var active_duration: float = 0.8
@export var retract_duration: float = 0.8
@export var reset_delay: float = 0.3
@export var auto_cycle: bool = false
@export var auto_cycle_offset: float = 0.0

var current_state: State = State.IDLE
var _state_timer: float = 0.0
var _initial_pos: Vector2
var _retracted_pos: Vector2
var _slammed_pos: Vector2
var _tween: Tween = null
var _player_in_trigger: bool = false

@onready var stem_sprite: Sprite2D = get_node_or_null("StemSprite")
@onready var crusher_body: AnimatableBody2D = get_node_or_null("CrusherBody")
@onready var block_sprite: Sprite2D = get_node_or_null("CrusherBody/BlockSprite")
@onready var body_collision: CollisionShape2D = get_node_or_null("CrusherBody/CollisionShape2D")
@onready var hazard_area: Area2D = get_node_or_null("CrusherBody/HazardArea")
@onready var hazard_collision: CollisionShape2D = get_node_or_null("CrusherBody/HazardArea/CollisionShape2D")
@onready var trigger_area: Area2D = get_node_or_null("TriggerArea")

func _ready() -> void:
	_initial_pos = global_position
	if crusher_body:
		_retracted_pos = crusher_body.position
		_slammed_pos = _retracted_pos + Vector2(0.0, travel_distance)
	else:
		_retracted_pos = Vector2.ZERO
		_slammed_pos = Vector2(0.0, travel_distance)
		
	GameManager.coins_reset.connect(reset)
	
	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 1
		trigger_area.body_entered.connect(_on_trigger_body_entered)
		trigger_area.body_exited.connect(_on_trigger_body_exited)
		
	if hazard_area:
		hazard_area.collision_layer = 4
		hazard_area.collision_mask = 1
		hazard_area.body_entered.connect(_on_hazard_body_entered)
		
	_setup_initial_state()
	
	if auto_cycle:
		if auto_cycle_offset > 0.0:
			_state_timer = auto_cycle_offset
		else:
			trigger_crusher()

func _setup_initial_state() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	current_state = State.IDLE
	_state_timer = 0.0
	_player_in_trigger = false
	
	if crusher_body:
		crusher_body.position = _retracted_pos
	if stem_sprite:
		stem_sprite.scale.y = 1.0
		stem_sprite.position.y = -16.0
	if hazard_collision:
		hazard_collision.disabled = true

func _physics_process(delta: float) -> void:
	# Update stem visual connection between ceiling and crusher body
	if stem_sprite and crusher_body:
		var current_dist: float = crusher_body.position.y - _retracted_pos.y
		var stem_h: float = 32.0
		var needed_scale: float = maxf(0.5, (current_dist + 24.0) / stem_h)
		stem_sprite.scale.y = needed_scale
		stem_sprite.position.y = -16.0 + (needed_scale * stem_h * 0.5)

	# Handle state transitions
	match current_state:
		State.IDLE:
			if auto_cycle:
				_state_timer -= delta
				if _state_timer <= 0.0:
					trigger_crusher()
			elif _player_in_trigger:
				trigger_crusher()

		State.TRIGGERED:
			_state_timer -= delta
			# Subtle pre-slam tremor / shake
			if crusher_body:
				crusher_body.position.x = _retracted_pos.x + randf_range(-1.5, 1.5)
			if _state_timer <= 0.0:
				if crusher_body:
					crusher_body.position.x = _retracted_pos.x
				_start_descending()

		State.DESCENDING:
			# Lethal collision active during rapid descent
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
				if auto_cycle or _player_in_trigger:
					trigger_crusher()

func _on_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_trigger = true
		if current_state == State.IDLE:
			trigger_crusher()

func _on_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_trigger = false

func trigger_crusher() -> void:
	if current_state != State.IDLE:
		return
		
	current_state = State.TRIGGERED
	_state_timer = trigger_delay
	crusher_triggered.emit()
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
		var hazard_shape: Shape2D = hazard_collision.shape if hazard_collision else null
		var hazard_size := Vector2(44.0, 44.0)
		if hazard_shape is RectangleShape2D:
			hazard_size = (hazard_shape as RectangleShape2D).size
		var hazard_center_global: Vector2 = hazard_collision.global_position if hazard_collision else crusher_body.global_position
		var hazard_rect := Rect2(hazard_center_global - hazard_size * 0.5, hazard_size)
		
		var player_center_global: Vector2 = player.global_position + Vector2(0.0, 2.0)
		var player_rect := Rect2(player_center_global - Vector2(8.0, 14.0), Vector2(16.0, 28.0))
		
		if hazard_rect.intersects(player_rect):
			_kill_player(player)

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

func _kill_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func reset() -> void:
	_setup_initial_state()
	global_position = _initial_pos
	if auto_cycle:
		if auto_cycle_offset > 0.0:
			_state_timer = auto_cycle_offset
		else:
			trigger_crusher()
