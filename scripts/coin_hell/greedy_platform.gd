class_name GreedyPlatform
extends StaticBody2D

## TRICK C — THE GREEDY COIN
## Lower platform under the tempting coin.
## If the player misses the intended high jump for Coin 6 and falls down here,
## the coin cannot be reached from below (height > 120px vs max jump 96px).
## Stepping onto this lower platform causes it to drop into the pit,
## making the missed attempt unrecoverable and prompting an immediate retry.
## Communicates purely through animation and physics — NO spoiling warning text.
## Resets cleanly on retry.

signal triggered_drop

@export var drop_speed: float = 650.0

var _initial_pos: Vector2
var _has_dropped: bool = false
var _falling: bool = false
var _delay_timer: float = 0.40

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: NinePatchRect = $NinePatchRect
@onready var step_area: Area2D = $StepArea

var _initial_visual_pos: Vector2

func _ready() -> void:
	_initial_pos = global_position
	if visual_rect:
		_initial_visual_pos = visual_rect.position
	GameManager.coins_reset.connect(reset)
	GameManager.player_revived.connect(_on_player_revived)
	if step_area:
		step_area.body_entered.connect(_on_step_entered)

func _on_player_revived(_pos: Vector2) -> void:
	reset()

func _on_step_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		trigger_greedy_drop()

func trigger_greedy_drop() -> void:
	if _has_dropped:
		return
	_has_dropped = true
	triggered_drop.emit()
	AudioManager.play_sfx("warning")

func _physics_process(delta: float) -> void:
	if _has_dropped and not _falling:
		_delay_timer -= delta
		if visual_rect:
			visual_rect.position.x = _initial_visual_pos.x + sin(_delay_timer * 60.0) * 3.5
		if _delay_timer <= 0.0:
			_falling = true
			if visual_rect:
				visual_rect.position = _initial_visual_pos
			if collision_shape:
				collision_shape.disabled = true
	elif _falling:
		global_position.y += drop_speed * delta
		if global_position.y > _initial_pos.y + 60.0:
			modulate.a = maxf(0.0, modulate.a - delta * 3.5)

func reset() -> void:
	_has_dropped = false
	_falling = false
	_delay_timer = 0.40
	global_position = _initial_pos
	modulate = Color.WHITE
	if visual_rect:
		visual_rect.position = _initial_visual_pos
	if collision_shape:
		collision_shape.disabled = false
