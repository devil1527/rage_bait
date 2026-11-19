class_name BulletBetrayalHuntingMine
extends CharacterBody2D

## Limited-Range Hunting Landmine for Bullet Betrayal (World 1 Level 4).
## Visual appearance: Identical to Level 3 stationary landmine.
## Mechanics:
## 1. Smooth ground patrol within a predefined distance.
## 2. Detects player within a configurable detection radius.
## 3. Alerts with rapid flashing LED and audio cue before chasing.
## 4. Chases player at balanced pursuit speed within a limited distance.
## 5. Gives up when player escapes beyond pursuit boundary and returns to patrol.
## 6. Single-trigger lethal explosion upon player contact, exactly matching Level 3 rules.
## 7. Immune to bullets.

signal exploded
signal state_changed(new_state: int)

enum State {
	PATROL,
	ALERT,
	CHASE,
	RETURNING,
	EXPLODING
}

const BLINK_CYCLE_PATROL: float = 0.65
const BLINK_CYCLE_CHASE: float = 0.16

@export_group("Patrol Settings")
@export var patrol_distance: float = 60.0
@export var patrol_speed: float = 45.0

@export_group("Detection & Pursuit")
@export var detection_radius: float = 110.0
@export var chase_speed: float = 80.0
@export var max_pursuit_distance: float = 180.0
@export var alert_duration: float = 0.30
@export var return_speed: float = 55.0

@export_group("Physics")
@export var gravity: float = 800.0

var current_state: State = State.PATROL
var spawn_position: Vector2 = Vector2.ZERO
var patrol_direction: int = 1 # 1 = right, -1 = left

var _triggered: bool = false
var _blink_timer: float = 0.0
var _alert_timer: float = 0.0
var _redetect_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var terrain_collider: CollisionShape2D = $TerrainCollider
@onready var hurt_area: Area2D = $HurtArea
@onready var hurt_collider: CollisionShape2D = $HurtArea/CollisionShape2D
@onready var warning_led: ColorRect = get_node_or_null("WarningLED")
@onready var warning_glow: Sprite2D = get_node_or_null("WarningGlow")
@onready var scorch_mark: Sprite2D = get_node_or_null("ScorchMark")
@onready var explosion_fx: Node2D = get_node_or_null("ExplosionFX")
@onready var flash: CanvasItem = get_node_or_null("ExplosionFX/Flash")
@onready var shockwave: CanvasItem = get_node_or_null("ExplosionFX/Shockwave")
@onready var fire_core: CanvasItem = get_node_or_null("ExplosionFX/FireCore")
@onready var fire_plume: CanvasItem = get_node_or_null("ExplosionFX/FirePlume")
@onready var shrapnel_particles: CPUParticles2D = get_node_or_null("ExplosionFX/ShrapnelParticles")
@onready var smoke_particles: CPUParticles2D = get_node_or_null("ExplosionFX/SmokeParticles")

var _player_ref: BulletBetrayalPlayer = null

func _ready() -> void:
	add_to_group("hunting_mines")
	spawn_position = global_position

	# Setup collision layers
	# CharacterBody2D layer = 0 (immune to bullets), mask = 2 (solid terrain)
	collision_layer = 0
	collision_mask = 2

	# HurtArea: layer = 0, mask = 1 (detects player on layer 1)
	if hurt_area:
		hurt_area.collision_layer = 0
		hurt_area.collision_mask = 1
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

	if explosion_fx:
		explosion_fx.visible = false
	if scorch_mark:
		scorch_mark.visible = false
	if warning_led:
		warning_led.visible = true
	if warning_glow:
		warning_glow.visible = true

func _physics_process(delta: float) -> void:
	if _triggered or current_state == State.EXPLODING:
		return

	# Apply gravity to hug ground
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Find player reference if needed
	if not _player_ref or not is_instance_valid(_player_ref):
		_find_player()

	if _redetect_cooldown > 0.0:
		_redetect_cooldown -= delta

	# Process FSM
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURNING:
			_process_returning(delta)

	move_and_slide()
	_update_blinking_led(delta)

func _find_player() -> void:
	var tree = get_tree()
	if not tree:
		return
	var players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0] as BulletBetrayalPlayer
	else:
		# Fallback: check sibling nodes
		var parent = get_parent()
		if parent:
			var candidate = parent.get_node_or_null("Player")
			if candidate is BulletBetrayalPlayer:
				_player_ref = candidate

func _is_player_valid() -> bool:
	if not _player_ref or not is_instance_valid(_player_ref):
		return false
	if _player_ref.has_method("is_alive") and not _player_ref.is_alive:
		return false
	if "is_dead" in _player_ref and _player_ref.is_dead:
		return false
	return true

func _get_dist_to_player() -> float:
	if not _is_player_valid():
		return 9999.0
	return global_position.distance_to(_player_ref.global_position)

func _get_dist_from_spawn() -> float:
	return abs(global_position.x - spawn_position.x)

func _process_patrol(delta: float) -> void:
	# Check player detection
	if _redetect_cooldown <= 0.0 and _is_player_valid():
		var dist: float = _get_dist_to_player()
		if dist <= detection_radius:
			_change_state(State.ALERT)
			return

	# Ground patrol locomotion
	velocity.x = float(patrol_direction) * patrol_speed

	var dist_from_spawn: float = global_position.x - spawn_position.x
	if patrol_direction > 0 and dist_from_spawn >= patrol_distance:
		patrol_direction = -1
		velocity.x = float(patrol_direction) * patrol_speed
	elif patrol_direction < 0 and dist_from_spawn <= -patrol_distance:
		patrol_direction = 1
		velocity.x = float(patrol_direction) * patrol_speed

	# Wall collision handling
	if is_on_wall():
		patrol_direction *= -1
		velocity.x = float(patrol_direction) * patrol_speed

func _process_alert(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, patrol_speed * 4.0 * delta)
	_alert_timer -= delta
	if _alert_timer <= 0.0:
		if _is_player_valid() and _get_dist_to_player() <= (detection_radius * 1.35):
			_change_state(State.CHASE)
		else:
			_change_state(State.RETURNING)

func _process_chase(delta: float) -> void:
	if not _is_player_valid():
		_change_state(State.RETURNING)
		return

	var dist_to_player: float = _get_dist_to_player()
	var dist_from_home: float = _get_dist_from_spawn()

	# Give up conditions:
	# 1. Player escaped beyond detection radius + tolerance
	# 2. Mine traveled beyond max pursuit distance from home
	if dist_from_home > max_pursuit_distance or dist_to_player > (detection_radius + 60.0):
		_change_state(State.RETURNING)
		return

	# Chase player along X axis
	var target_x: float = _player_ref.global_position.x
	var chase_dir: float = sign(target_x - global_position.x)
	if chase_dir == 0.0:
		chase_dir = float(patrol_direction)

	velocity.x = chase_dir * chase_speed

func _process_returning(delta: float) -> void:
	var offset_from_home: float = global_position.x - spawn_position.x

	# Arrived back inside patrol area: resume patrol
	if abs(offset_from_home) <= (patrol_distance * 0.4):
		patrol_direction = 1 if offset_from_home < 0 else -1
		_change_state(State.PATROL)
		return

	# Move toward spawn position
	var return_dir: float = -sign(offset_from_home)
	if return_dir == 0.0:
		return_dir = 1.0

	velocity.x = return_dir * return_speed

	# Check re-detection if player gets close while returning
	if _redetect_cooldown <= 0.0 and _is_player_valid():
		var dist_to_player: float = _get_dist_to_player()
		var dist_from_home: float = _get_dist_from_spawn()
		if dist_to_player <= detection_radius and dist_from_home <= (max_pursuit_distance * 0.75):
			_change_state(State.ALERT)
			return

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(int(new_state))

	match new_state:
		State.ALERT:
			_alert_timer = alert_duration
			if AudioManager:
				AudioManager.play_sfx("dry_fire") # Tactical telegraph chirp
		State.RETURNING:
			_redetect_cooldown = 0.85 # Hysteresis prevention
			var offset_from_home: float = global_position.x - spawn_position.x
			var return_dir: float = -sign(offset_from_home)
			if return_dir == 0.0:
				return_dir = -float(patrol_direction)
			velocity.x = return_dir * return_speed
		State.CHASE:
			pass
		State.PATROL:
			pass

func _update_blinking_led(delta: float) -> void:
	var cycle: float = BLINK_CYCLE_CHASE if (current_state == State.CHASE or current_state == State.ALERT) else BLINK_CYCLE_PATROL
	_blink_timer += delta
	if _blink_timer >= cycle:
		_blink_timer = fmod(_blink_timer, cycle)

	var is_flashing: bool = false
	if current_state == State.CHASE or current_state == State.ALERT:
		# Rapid high-urgency emergency strobe (equal duty cycle)
		is_flashing = (_blink_timer < (cycle * 0.5))
	else:
		# Tactical double-pip hazard pulse matching Level 3 stationary mine
		is_flashing = (_blink_timer < 0.12) or (_blink_timer >= 0.20 and _blink_timer < 0.32)

	if is_flashing:
		if warning_led:
			warning_led.color = Color(1.0, 0.2, 0.15, 1.0)
			warning_led.modulate = Color(2.2, 1.4, 1.1, 1.0)
		if warning_glow:
			warning_glow.visible = true
			warning_glow.modulate = Color(1.4, 0.25, 0.1, 0.95)
			var scale_mult: float = 1.35 if (current_state == State.CHASE) else 1.2
			warning_glow.scale = Vector2(scale_mult, scale_mult)
	else:
		if warning_led:
			warning_led.color = Color(0.2, 0.04, 0.04, 0.35)
			warning_led.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if warning_glow:
			warning_glow.visible = false

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if _triggered or current_state == State.EXPLODING:
		return

	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if body.has_method("is_alive") and not body.is_alive:
			return
		if "is_dead" in body and body.is_dead:
			return
		detonate(body)

func detonate(victim: Node2D = null) -> void:
	if _triggered:
		return
	_triggered = true
	_change_state(State.EXPLODING)
	velocity = Vector2.ZERO

	# Single trigger guarantee: disable hurtbox immediately
	if hurt_collider:
		hurt_collider.set_deferred("disabled", true)
	if terrain_collider:
		terrain_collider.set_deferred("disabled", true)

	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false

	# Play concussive explosion audio
	if AudioManager:
		AudioManager.play_sfx("explosion")

	# Play identical Level 3 multi-stage explosion FX
	_play_explosion_animation()

	exploded.emit()

	# Lethal strike to player
	if victim:
		if victim.has_method("die"):
			victim.die()
		elif victim.has_method("take_hit"):
			victim.take_hit(1)

func _play_explosion_animation() -> void:
	if sprite:
		sprite.modulate = Color(2.5, 2.0, 1.5, 1.0)

	if scorch_mark:
		scorch_mark.visible = true
		scorch_mark.modulate.a = 0.9

	if not explosion_fx:
		if sprite:
			sprite.visible = false
		return

	explosion_fx.visible = true
	explosion_fx.modulate = Color.WHITE

	if shrapnel_particles:
		shrapnel_particles.restart()
		shrapnel_particles.emitting = true
	if smoke_particles:
		smoke_particles.restart()
		smoke_particles.emitting = true

	# 1. Flash burst
	if flash:
		flash.visible = true
		flash.scale = Vector2(0.6, 0.6)
		flash.modulate = Color(1.5, 1.4, 0.9, 1.0)
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.07)
		flash_tween.tween_callback(func(): if is_instance_valid(flash): flash.visible = false)

	# 2. Expanding shockwave ring
	if shockwave:
		shockwave.visible = true
		shockwave.scale = Vector2(0.2, 0.15)
		shockwave.modulate = Color(2.0, 1.8, 1.2, 1.0)
		var shock_tween := create_tween()
		shock_tween.tween_property(shockwave, "scale", Vector2(2.5, 1.8), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shock_tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		shock_tween.tween_callback(func(): if is_instance_valid(shockwave): shockwave.visible = false)

	# 3. Fireball core explosion
	if fire_core:
		fire_core.visible = true
		fire_core.scale = Vector2(0.25, 0.25)
		fire_core.modulate = Color(2.2, 2.0, 1.4, 1.0)
		var fire_tween := create_tween()
		fire_tween.tween_property(fire_core, "scale", Vector2(1.8, 1.8), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(1.4, 0.6, 0.15, 1.0), 0.09)
		if sprite:
			fire_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.06)
		fire_tween.tween_property(fire_core, "scale", Vector2(2.3, 2.3), 0.32)
		fire_tween.parallel().tween_property(fire_core, "modulate", Color(0.2, 0.15, 0.15, 0.0), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fire_tween.tween_callback(func(): if is_instance_valid(fire_core): fire_core.visible = false)

	# 4. Asymmetrical secondary plume
	if fire_plume:
		fire_plume.visible = true
		fire_plume.scale = Vector2(0.2, 0.2)
		fire_plume.modulate = Color(1.8, 1.2, 0.5, 1.0)
		var plume_tween := create_tween()
		plume_tween.tween_interval(0.03)
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(1.0, 0.3, 0.05, 0.9), 0.12)
		plume_tween.tween_property(fire_plume, "scale", Vector2(1.9, 1.9), 0.23)
		plume_tween.parallel().tween_property(fire_plume, "modulate", Color(0.15, 0.12, 0.12, 0.0), 0.23)
		plume_tween.tween_callback(func(): if is_instance_valid(fire_plume): fire_plume.visible = false)

	# 5. Concussion screen shake
	_apply_camera_shake(7.0, 0.28)

func _apply_camera_shake(intensity: float = 7.0, duration: float = 0.28) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var cam: Camera2D = viewport.get_camera_2d()
	if not cam:
		return

	var tween := create_tween()
	var steps: int = 6
	for i in range(steps):
		var decay: float = 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity * 0.8, intensity * 0.4) * decay
		)
		tween.tween_property(cam, "offset", offset, duration / float(steps))
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.04)

func reset() -> void:
	_triggered = false
	current_state = State.PATROL
	global_position = spawn_position
	velocity = Vector2.ZERO
	patrol_direction = 1
	_blink_timer = 0.0
	_alert_timer = 0.0
	_redetect_cooldown = 0.0

	if hurt_collider:
		hurt_collider.set_deferred("disabled", false)
	if terrain_collider:
		terrain_collider.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.modulate = Color.WHITE
	if warning_led:
		warning_led.visible = true
	if warning_glow:
		warning_glow.visible = true
	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false
