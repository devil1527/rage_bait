class_name InfernoGate
extends Node2D

## SIGNATURE MECHANIC: INFERNO GATE
## A vertical wall of fire spanning floor to ceiling.
## Activates when the player enters proximity detection area.
## Cycles between active (lethal flames blocking passage) and safe opening (retracted flames).
## Players who jump reflexively into the fire die; players who stop and observe the cycle cross safely.
## Resets cleanly on level retry.

signal fire_erupted
signal fire_retracted

@export var trigger_area_path: NodePath = NodePath("")
@export var active_duration: float = 1.3
@export var safe_duration: float = 1.3

var _is_triggered: bool = false
var _is_active: bool = false
var _in_safe_phase: bool = false
var _cycle_timer: float = 0.0
var _initial_pos: Vector2

@onready var top_emitter: Sprite2D = get_node_or_null("TopEmitter")
@onready var bottom_emitter: Sprite2D = get_node_or_null("BottomEmitter")
@onready var flame_area: Area2D = get_node_or_null("FlameArea")
@onready var flame_sprite: Sprite2D = get_node_or_null("FlameArea/FlameSprite")
@onready var flame_collision: CollisionShape2D = get_node_or_null("FlameArea/CollisionShape2D")
@onready var trigger_area: Area2D = get_node_or_null("TriggerArea")

var _tween: Tween = null

func _ready() -> void:
	_initial_pos = global_position
	GameManager.coins_reset.connect(reset)
	
	if flame_area:
		flame_area.collision_layer = 4
		flame_area.collision_mask = 1
		flame_area.body_entered.connect(_on_flame_body_entered)
		
	if trigger_area_path != NodePath(""):
		var ext_trig = get_node_or_null(trigger_area_path)
		if ext_trig is Area2D:
			ext_trig.body_entered.connect(_on_trigger_entered)
			
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_entered)
		
	_setup_initial_state()

func _setup_initial_state() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_triggered = false
	_is_active = false
	_in_safe_phase = false
	_cycle_timer = 0.0
	
	if flame_sprite:
		flame_sprite.visible = false
		flame_sprite.modulate.a = 0.0
		flame_sprite.scale = Vector2(1.0, 1.0)
	if flame_collision:
		flame_collision.disabled = true
	if top_emitter:
		top_emitter.visible = false
	if bottom_emitter:
		bottom_emitter.visible = false

func _physics_process(delta: float) -> void:
	if not _is_triggered:
		return
		
	_cycle_timer -= delta
	if _cycle_timer <= 0.0:
		if _in_safe_phase:
			_erupt_flames()
		else:
			_retract_flames()
			
	# Lethality enforcement while flames are active
	if _is_active and flame_area:
		for b in flame_area.get_overlapping_bodies():
			_kill_player(b)

func _on_trigger_entered(body: Node2D) -> void:
	if not _is_triggered and (body.is_in_group("player") or body.name == "Player"):
		activate_gate()

func activate_gate() -> void:
	if _is_triggered:
		return
	_is_triggered = true
	_erupt_flames()

func _erupt_flames() -> void:
	_in_safe_phase = false
	_is_active = true
	_cycle_timer = active_duration
	AudioManager.play_sfx("warning")
	
	if flame_collision:
		flame_collision.disabled = false
		
	if top_emitter:
		top_emitter.visible = true
		top_emitter.modulate = Color(1.3, 0.8, 0.5, 1.0)
	if bottom_emitter:
		bottom_emitter.visible = true
		bottom_emitter.modulate = Color(1.3, 0.8, 0.5, 1.0)

	if flame_sprite:
		flame_sprite.visible = true
		flame_sprite.modulate.a = 1.0
		if _tween and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		flame_sprite.scale = Vector2(0.2, 1.0)
		_tween.tween_property(flame_sprite, "scale:x", 1.0, 0.05)
		
	fire_erupted.emit()
	
	# Check instant lethality
	if flame_area:
		for b in flame_area.get_overlapping_bodies():
			_kill_player(b)

func _retract_flames() -> void:
	_in_safe_phase = true
	_is_active = false
	_cycle_timer = safe_duration
	
	if flame_collision:
		flame_collision.disabled = true
		
	if top_emitter:
		top_emitter.visible = false
	if bottom_emitter:
		bottom_emitter.visible = false

	if flame_sprite:
		if _tween and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(flame_sprite, "modulate:a", 0.0, 0.08)
		_tween.tween_callback(func():
			if _in_safe_phase:
				flame_sprite.visible = false
		)
		
	fire_retracted.emit()

func _on_flame_body_entered(body: Node2D) -> void:
	if _is_active:
		_kill_player(body)

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
