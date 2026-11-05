class_name BulletBetrayalEnemySoldier
extends CharacterBody2D

## Reusable enemy soldier for Bullet Betrayal.
## Supports patrol, player detection, telegraph, and ranged firing.

signal eliminated

const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/bullet_betrayal/bb_enemy_bullet.tscn")

@export var patrol_speed: float = 70.0
@export var patrol_distance: float = 120.0
@export var can_shoot: bool = true
@export var shoot_interval: float = 2.4
@export var detection_range: float = 320.0
@export var gravity: float = 1100.0

var facing_direction: int = -1 # -1 = Left, 1 = Right
var is_dead: bool = false
var is_aiming: bool = false
var _origin_x: float = 0.0
var _initial_pos: Vector2 = Vector2.ZERO
var _shoot_timer: float = 0.0
var _anim_timer: float = 0.0
var _run_frame: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_col: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var alert_icon: Label = $AlertIcon
@onready var muzzle_pos: Marker2D = $MuzzlePos

var _tex_idle: Texture2D
var _tex_run1: Texture2D
var _tex_run2: Texture2D

func _ready() -> void:
	add_to_group("enemies")
	_initial_pos = global_position
	_origin_x = global_position.x
	_shoot_timer = randf_range(0.8, 1.8) # Stagger initial firing
	alert_icon.visible = false
	
	_tex_idle = load("res://assets/sprites/bb_enemy_idle.png")
	_tex_run1 = load("res://assets/sprites/bb_enemy_run_1.png")
	_tex_run2 = load("res://assets/sprites/bb_enemy_run_2.png")
	
	_update_facing()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	var player = _get_active_player()
	var sees_player := false
	if player and not player.is_dead:
		sees_player = _check_player_detection(player)

	if sees_player and can_shoot:
		# Engage player
		_face_player(player)
		velocity.x = 0.0
		if not is_aiming:
			_aim_and_fire(player, delta)
	else:
		# Patrol normally
		alert_icon.visible = false
		is_aiming = false
		_shoot_timer = maxf(0.0, _shoot_timer - delta)
		_patrol(delta)

	move_and_slide()
	_update_animation(delta)

func _patrol(_delta: float) -> void:
	if patrol_distance <= 0.0:
		velocity.x = 0.0
		return

	velocity.x = facing_direction * patrol_speed

	# Patrol boundaries check
	var offset = global_position.x - _origin_x
	if facing_direction > 0 and offset >= patrol_distance:
		facing_direction = -1
		_update_facing()
	elif facing_direction < 0 and offset <= -patrol_distance:
		facing_direction = 1
		_update_facing()

	# Wall collision check
	if is_on_wall():
		facing_direction = -facing_direction
		_update_facing()

func _check_player_detection(player: Node2D) -> bool:
	var diff: Vector2 = player.global_position - global_position
	var dist_x: float = absf(diff.x)
	var dist_y: float = absf(diff.y)
	
	# Only detect within horizontal line of sight and within reasonable elevation (+/- 80px)
	if dist_x <= detection_range and dist_y <= 80.0:
		return true
	return false

func _face_player(player: Node2D) -> void:
	var desired_dir := 1 if player.global_position.x > global_position.x else -1
	if desired_dir != facing_direction:
		facing_direction = desired_dir
		_update_facing()

func _update_facing() -> void:
	if sprite:
		# Enemy sprite defaults to facing left
		sprite.flip_h = (facing_direction > 0)
	if muzzle_pos:
		muzzle_pos.position.x = 18.0 * facing_direction

func _aim_and_fire(_player: Node2D, delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.4:
		# Show warning telegraph glint
		alert_icon.visible = true
	
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval
		alert_icon.visible = false
		_spawn_bullet()

func _spawn_bullet() -> void:
	if is_dead or not ENEMY_BULLET_SCENE:
		return
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	var spawn_pos = muzzle_pos.global_position if muzzle_pos else global_position
	get_parent().add_child(bullet)
	bullet.setup(Vector2(facing_direction, 0.0), spawn_pos)
	AudioManager.play_sfx("warning")

func _update_animation(delta: float) -> void:
	if not sprite:
		return
	if absf(velocity.x) > 10.0:
		_anim_timer += delta
		if _anim_timer >= 0.16:
			_anim_timer = 0.0
			_run_frame = 2 if _run_frame == 1 else 1
			sprite.texture = _tex_run2 if _run_frame == 2 else _tex_run1
	else:
		sprite.texture = _tex_idle

func take_hit(_damage: int = 1) -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	alert_icon.visible = false
	
	if collision_shape:
		collision_shape.disabled = true
	if hurtbox_col:
		hurtbox_col.disabled = true
		
	AudioManager.play_sfx("enemy_kill")
	eliminated.emit()

	# Defeat animation: red flash and drop/fade
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.04)
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.08)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 6.0, 0.12)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _get_active_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)

func reset() -> void:
	is_dead = false
	is_aiming = false
	set_physics_process(true)
	global_position = _initial_pos
	_origin_x = _initial_pos.x
	facing_direction = -1
	_shoot_timer = randf_range(0.8, 1.8)
	alert_icon.visible = false
	if sprite:
		sprite.texture = _tex_idle
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", false)
	_update_facing()
