class_name TimedSpikes
extends Area2D

## TimedSpikes: Industrial pop-up spike trap for Coin Hell Level 11.
## Rhythmical hazard that cycles between RETRACTED (safe) -> WARNING (tremor) -> EXTENDED (lethal).
## Provides clear telegraphing through visual shake and amber warning glow.
## Resets cleanly on level retry.

enum State { RETRACTED, WARNING, EXTENDED }

@export var retracted_duration: float = 1.2
@export var warning_duration: float = 0.5
@export var extended_duration: float = 0.9
@export var auto_start: bool = true
@export var initial_offset: float = 0.0

var current_state: State = State.RETRACTED
var _state_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_sprite_y: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	GameManager.coins_reset.connect(reset)
	if sprite:
		_base_sprite_y = sprite.position.y
	reset()

func _physics_process(delta: float) -> void:
	_state_timer -= delta

	if current_state == State.WARNING:
		# Warning tremor and amber flash
		if sprite:
			sprite.position.x = sin(_state_timer * 40.0) * 2.0
			sprite.modulate = Color(1.0, 0.7, 0.2, 0.8)

	if _state_timer <= 0.0:
		match current_state:
			State.RETRACTED:
				_set_state(State.WARNING)
			State.WARNING:
				_set_state(State.EXTENDED)
			State.EXTENDED:
				_set_state(State.RETRACTED)

	# Active lethality check
	if current_state == State.EXTENDED:
		for body in get_overlapping_bodies():
			_kill_player(body)

func _set_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.RETRACTED:
			_state_timer = retracted_duration
			if sprite:
				sprite.position = Vector2(0.0, _base_sprite_y + 12.0)
				sprite.visible = false
				sprite.modulate = Color.WHITE
			if collision_shape:
				collision_shape.disabled = true
		State.WARNING:
			_state_timer = warning_duration
			if sprite:
				sprite.position = Vector2(0.0, _base_sprite_y + 6.0)
				sprite.visible = true
				sprite.modulate = Color(1.0, 0.6, 0.2, 0.7)
			if collision_shape:
				collision_shape.disabled = true
			AudioManager.play_sfx("warning")
		State.EXTENDED:
			_state_timer = extended_duration
			if sprite:
				sprite.position = Vector2(0.0, _base_sprite_y)
				sprite.visible = true
				sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
			if collision_shape:
				collision_shape.disabled = false
			for body in get_overlapping_bodies():
				_kill_player(body)

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.EXTENDED:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func reset() -> void:
	_state_timer = retracted_duration + initial_offset
	current_state = State.RETRACTED
	if sprite:
		sprite.position = Vector2(0.0, _base_sprite_y + 12.0)
		sprite.visible = false
		sprite.modulate = Color.WHITE
	if collision_shape:
		collision_shape.disabled = true
