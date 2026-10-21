class_name SteamVent
extends Node2D

## SteamVent: Industrial High-Pressure Steam Hazard for World 3: Rage Factory
## Cycles through:
##   DORMANT (safe, pressure building)
##   WARNING (telegraphed vibration, amber beacon flashing, audio hiss)
##   BLASTING (superheated steam erupts, lethal hazard collision layer 4)
## Cleanly resets on level retry and player revive.

signal pressure_warning_started
signal steam_blast_started
signal steam_blast_ended

enum State {
	DORMANT,
	WARNING,
	BLASTING
}

@export var dormant_duration: float = 1.4
@export var warning_duration: float = 0.7
@export var blast_duration: float = 0.9
@export var initial_offset: float = 0.0
@export var auto_start: bool = true
@export var blast_direction: Vector2 = Vector2.UP
@export var blast_length: float = 96.0
@export var blast_width: float = 24.0

var current_state: State = State.DORMANT
var _state_timer: float = 0.0
var _warning_sound_played: bool = false
var _blast_sound_played: bool = false
var _shake_offset: float = 0.0

@onready var nozzle_sprite: Sprite2D = get_node_or_null("NozzleSprite")
@onready var warning_beacon: Sprite2D = get_node_or_null("WarningBeacon")
@onready var steam_area: Area2D = get_node_or_null("SteamArea")
@onready var steam_collision: CollisionShape2D = get_node_or_null("SteamArea/CollisionShape2D")
@onready var steam_sprite: Sprite2D = get_node_or_null("SteamArea/SteamSprite")

var _nozzle_orig_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if nozzle_sprite:
		_nozzle_orig_pos = nozzle_sprite.position
	GameManager.coins_reset.connect(reset)
	if GameManager.has_signal("player_revived"):
		GameManager.player_revived.connect(func(_pos): reset())
	_setup_nodes()
	reset()

func _setup_nodes() -> void:
	if not steam_area:
		steam_area = Area2D.new()
		steam_area.name = "SteamArea"
		steam_area.collision_layer = 4 # Hazard layer
		steam_area.collision_mask = 1  # Player mask
		steam_area.body_entered.connect(_on_steam_body_entered)
		add_child(steam_area)

	if not steam_collision:
		steam_collision = CollisionShape2D.new()
		steam_collision.name = "CollisionShape2D"
		var r := RectangleShape2D.new()
		r.size = Vector2(blast_width, blast_length)
		steam_collision.shape = r
		# Position along blast direction from nozzle orifice (assumed centered at origin)
		steam_collision.position = blast_direction.normalized() * (blast_length * 0.5 + 4.0)
		steam_area.add_child(steam_collision)

	if not steam_sprite:
		steam_sprite = Sprite2D.new()
		steam_sprite.name = "SteamSprite"
		var plume_tex: Texture2D = load("res://assets/sprites/steam_plume.png")
		if plume_tex:
			steam_sprite.texture = plume_tex
		steam_sprite.position = blast_direction.normalized() * (blast_length * 0.5 + 4.0)
		# Orient plume if blasting horizontally or downwards
		if blast_direction == Vector2.DOWN:
			steam_sprite.rotation = PI
		elif blast_direction == Vector2.RIGHT:
			steam_sprite.rotation = PI * 0.5
		elif blast_direction == Vector2.LEFT:
			steam_sprite.rotation = -PI * 0.5
		steam_area.add_child(steam_sprite)

func reset() -> void:
	_warning_sound_played = false
	_blast_sound_played = false
	_shake_offset = 0.0
	if nozzle_sprite:
		nozzle_sprite.position = _nozzle_orig_pos
		nozzle_sprite.modulate = Color.WHITE

	if initial_offset > 0.0:
		current_state = State.DORMANT
		_state_timer = dormant_duration + initial_offset
	else:
		current_state = State.DORMANT
		_state_timer = dormant_duration

	_apply_state_visuals()

func _physics_process(delta: float) -> void:
	if not auto_start:
		return

	_state_timer -= delta

	match current_state:
		State.DORMANT:
			if _state_timer <= 0.0:
				_set_state(State.WARNING)

		State.WARNING:
			# Visual shake and pulsating warning glow
			_shake_offset = sin(_state_timer * 45.0) * 2.0
			if nozzle_sprite:
				nozzle_sprite.position = _nozzle_orig_pos + Vector2(_shake_offset, 0.0)
				nozzle_sprite.modulate = Color(1.0, 0.75, 0.3, 1.0)
			if warning_beacon:
				warning_beacon.modulate = Color(1.0, 0.2, 0.1, 1.0) if int(_state_timer * 15.0) % 2 == 0 else Color(1.0, 0.8, 0.1, 0.5)

			if _state_timer <= 0.0:
				_set_state(State.BLASTING)

		State.BLASTING:
			# Plume turbulent flicker
			if steam_sprite:
				steam_sprite.modulate.a = randf_range(0.85, 1.0)
				steam_sprite.scale.x = randf_range(0.95, 1.05)

			# Continuous hazard overlap check
			if steam_area:
				for body in steam_area.get_overlapping_bodies():
					_kill_player(body)

			if _state_timer <= 0.0:
				_set_state(State.DORMANT)

func _set_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.DORMANT:
			_state_timer = dormant_duration
			_warning_sound_played = false
			_blast_sound_played = false
			steam_blast_ended.emit()
		State.WARNING:
			_state_timer = warning_duration
			pressure_warning_started.emit()
			if not _warning_sound_played:
				_warning_sound_played = true
				AudioManager.play_sfx("warning")
		State.BLASTING:
			_state_timer = blast_duration
			steam_blast_started.emit()
			if not _blast_sound_played:
				_blast_sound_played = true
				AudioManager.play_sfx("fire")

	_apply_state_visuals()

func _apply_state_visuals() -> void:
	match current_state:
		State.DORMANT:
			if steam_collision:
				steam_collision.disabled = true
			if steam_sprite:
				steam_sprite.visible = false
			if warning_beacon:
				warning_beacon.modulate = Color(0.4, 0.3, 0.2, 0.4)
			if nozzle_sprite:
				nozzle_sprite.position = _nozzle_orig_pos
				nozzle_sprite.modulate = Color.WHITE

		State.WARNING:
			# Warning phase is NON-LETHAL (telegraph window)
			if steam_collision:
				steam_collision.disabled = true
			if steam_sprite:
				steam_sprite.visible = false

		State.BLASTING:
			# Blast phase is LETHAL
			if steam_collision:
				steam_collision.disabled = false
			if steam_sprite:
				steam_sprite.visible = true
			if warning_beacon:
				warning_beacon.modulate = Color(1.0, 0.1, 0.1, 1.0)
			if nozzle_sprite:
				nozzle_sprite.position = _nozzle_orig_pos
				nozzle_sprite.modulate = Color(1.0, 0.4, 0.2, 1.0)

func _on_steam_body_entered(body: Node2D) -> void:
	if current_state == State.BLASTING:
		_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if body and body.is_in_group("player") and body.has_method("die"):
		body.die()

func get_non_lethal_window() -> float:
	return dormant_duration + warning_duration
