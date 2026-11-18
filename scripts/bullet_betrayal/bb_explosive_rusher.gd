class_name BulletBetrayalExplosiveRusher
extends BulletBetrayalEnemySoldier

## Surprise Explosive Rusher for Bullet Betrayal (World 1 Level 5).
## Initially resembles an ordinary enemy soldier without glowing or flashing.
## Upon detection or ambush trigger, suddenly emerges with a red flashing warning effect,
## an accelerating alarm beep, and sprints towards the player.
## Detonates within proximity, dealing lethal blast radius damage to the player
## and eliminating nearby enemies without chain reactions or wall penetration.
## One player bullet kills it cleanly before detonation, preventing the explosion.

enum RusherState {
	WAITING,       # Concealed / waiting behind cover, looks 100% like an ordinary soldier
	ALERT,         # Just detected player: telegraph bump, '!' alert, warning chirp, LED begins pulsing
	RUSHING,       # Sprints directly towards player at high speed, accelerating alarm beeps
	DETONATING,    # Lethal blast sequence, deals radius damage, emits eliminated
	DEAD           # Shot by player before exploding, eliminated cleanly without blast
}

@export_group("Rusher Tuning")
@export var rush_speed: float = 145.0
@export var detonation_distance: float = 32.0
@export var blast_radius: float = 65.0
@export var rusher_alert_duration: float = 0.28

var rusher_state: RusherState = RusherState.WAITING
var _has_detonated: bool = false
var _state_timer: float = 0.0
var _beep_timer: float = 0.0
var _strobe_timer: float = 0.0
var _strobe_state: bool = false

# Rusher Visual Nodes
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

func _ready() -> void:
	super._ready()
	can_shoot = false # Rusher does not shoot bullets; it charges and detonates!

	# Ensure warning effects start completely dark and ordinary
	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false
	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false

	# Default detection range for rusher if not triggered via AmbushTrigger
	if detection_range <= 0.0:
		detection_range = 220.0

func _physics_process(delta: float) -> void:
	if is_dead or rusher_state == RusherState.DEAD or rusher_state == RusherState.DETONATING:
		return

	# Apply gravity to hug terrain
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Pit fall check
	if global_position.y > 520.0:
		take_hit(current_health)
		return

	var player = _get_active_player()
	var player_alive: bool = (player != null and player.get("is_alive") == true)

	match rusher_state:
		RusherState.WAITING:
			_process_waiting(delta, player, player_alive)
		RusherState.ALERT:
			_process_alert(delta, player)
		RusherState.RUSHING:
			_process_rushing(delta, player, player_alive)

	move_and_slide()

func _process_waiting(_delta: float, player: Node2D, player_alive: bool) -> void:
	if is_dormant:
		velocity = Vector2.ZERO
		return

	# If placed visible behind cover, patrol locally or wait until player is detected
	if patrol_distance > 0.0:
		_patrol(_delta)
		_update_animation(_delta)
	else:
		velocity.x = 0.0
		if sprite:
			sprite.texture = _tex_idle

	if player_alive and _check_player_detection(player):
		activate_rusher(player)

func activate_rusher(player: Node2D = null) -> void:
	if rusher_state != RusherState.WAITING or is_dead or _has_detonated:
		return

	rusher_state = RusherState.ALERT
	_state_timer = rusher_alert_duration
	is_dormant = false
	visible = true
	patrol_distance = 0.0 # Stop patrol immediately

	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

	# Telegraph scale bump and exclamation mark
	if alert_icon:
		alert_icon.visible = true
	if AudioManager:
		AudioManager.play_sfx("warning")

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.07)

	# Turn on warning LED & glow
	if warning_led:
		warning_led.visible = true
	if warning_glow:
		warning_glow.visible = true

	if player:
		_face_player(player)

func _process_alert(delta: float, player: Node2D) -> void:
	velocity.x = 0.0
	if player:
		_face_player(player)

	_state_timer -= delta
	if _state_timer <= 0.0:
		rusher_state = RusherState.RUSHING
		if alert_icon:
			alert_icon.visible = false
		_beep_timer = 0.0 # First beep immediately upon rushing
		if player:
			var x_diff: float = player.global_position.x - global_position.x
			facing_direction = 1 if x_diff > 0.0 else -1
			_update_facing()
			velocity.x = float(facing_direction) * rush_speed

func _process_rushing(delta: float, player: Node2D, player_alive: bool) -> void:
	if not player_alive:
		velocity.x = 0.0
		return

	var dist_to_player: float = global_position.distance_to(player.global_position)
	var x_diff: float = player.global_position.x - global_position.x

	# Update facing direction towards player
	facing_direction = 1 if x_diff > 0.0 else -1
	_update_facing()

	# High-speed sprint towards player
	velocity.x = float(facing_direction) * rush_speed

	# Rapid running leg cycle (every 0.09s)
	_anim_timer += delta
	if _anim_timer >= 0.09:
		_anim_timer = 0.0
		_run_frame = 2 if _run_frame == 1 else 1
		if sprite:
			sprite.texture = _tex_run2 if _run_frame == 2 else _tex_run1

	# High-urgency red flashing strobe (0.12s cycle)
	_strobe_timer += delta
	if _strobe_timer >= 0.12:
		_strobe_timer = 0.0
		_strobe_state = not _strobe_state
		if _strobe_state:
			if sprite:
				sprite.modulate = Color(2.2, 0.4, 0.3, 1.0)
			if warning_led:
				warning_led.color = Color(1.0, 0.1, 0.1, 1.0)
			if warning_glow:
				warning_glow.visible = true
				warning_glow.modulate = Color(1.8, 0.2, 0.1, 1.0)
		else:
			if sprite:
				sprite.modulate = Color.WHITE
			if warning_led:
				warning_led.color = Color(0.3, 0.05, 0.05, 0.5)
			if warning_glow:
				warning_glow.visible = false

	# Accelerating alarm beep: interval scales from 0.35s at distance down to 0.09s close-up
	var beep_interval: float = clampf(remap(dist_to_player, 30.0, 240.0, 0.09, 0.35), 0.08, 0.38)
	_beep_timer -= delta
	if _beep_timer <= 0.0:
		_beep_timer = beep_interval
		if AudioManager:
			AudioManager.play_sfx("dry_fire") # Tactical telegraph chirp

	# Detonation proximity check
	if dist_to_player <= detonation_distance or (is_on_wall() and absf(x_diff) <= (detonation_distance * 1.5)):
		detonate()

## Ambush Trigger hook
func trigger_ambush(active_player: Node2D = null) -> void:
	if not is_dormant and rusher_state != RusherState.WAITING:
		return
	if is_dead or _has_detonated:
		return

	has_ambushed = true
	var player = active_player if active_player else _get_active_player()

	# Rear Ambush Archetype: emerge behind the player's direction of travel
	if ambush_type == AmbushType.BEHIND and player:
		var player_dir := 1
		if absf(player.velocity.x) > 10.0:
			player_dir = 1 if player.velocity.x > 0.0 else -1
		elif "facing_direction" in player and player.facing_direction != 0:
			player_dir = player.facing_direction

		var rear_dir := -player_dir
		var ambush_dist := 220.0
		var spawn_x: float = clampf(player.global_position.x + (rear_dir * ambush_dist), 80.0, 2750.0)

		global_position = Vector2(spawn_x, 393.0)
		_origin_x = spawn_x
		facing_direction = -rear_dir
		_update_facing()

	activate_rusher(player)

## Detonation Sequence: deals blast radius damage, screen shake, and FX
func detonate() -> void:
	if is_dead or _has_detonated:
		return

	_has_detonated = true
	is_dead = true
	rusher_state = RusherState.DETONATING
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Disable colliders to prevent duplicate hits
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", true)

	if alert_icon:
		alert_icon.visible = false
	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false
	if sprite:
		sprite.visible = false

	# Play concussive explosion audio & visual effects
	if AudioManager:
		AudioManager.play_sfx("explosion")
	_play_explosion_animation()

	# Deal lethal blast radius damage
	_apply_blast_damage()

	# Emit eliminated for this rusher
	eliminated.emit()

	# Queue free after explosion effects finish
	var free_timer := get_tree().create_timer(0.6)
	free_timer.timeout.connect(queue_free)

func _apply_blast_damage() -> void:
	var player = _get_active_player()
	# Check Player inside blast radius
	if player and player.get("is_alive") == true:
		var dist_to_player: float = global_position.distance_to(player.global_position)
		if dist_to_player <= blast_radius:
			if _has_line_of_sight(player.global_position):
				if player.has_method("die"):
					player.die()
				elif player.has_method("take_hit"):
					player.take_hit(1)

	# Check nearby ordinary enemies inside blast radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue
		var dist_to_enemy: float = global_position.distance_to(enemy.global_position)
		if dist_to_enemy <= blast_radius:
			if _has_line_of_sight(enemy.global_position):
				# If target is another rusher, eliminate cleanly without secondary detonation (prevent chain reactions)
				if enemy is BulletBetrayalExplosiveRusher:
					enemy.take_hit(1)
				elif enemy.has_method("take_hit"):
					enemy.take_hit(1)

## Line-of-sight raycast: ensures blast cannot kill through solid terrain walls (layer 2)
func _has_line_of_sight(target_pos: Vector2) -> bool:
	var world_2d = get_world_2d()
	if not world_2d:
		return true
	var space_state = world_2d.direct_space_state
	if not space_state:
		return true

	var query := PhysicsRayQueryParameters2D.create(global_position, target_pos, 2) # layer 2 = solid terrain
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()

func _play_explosion_animation() -> void:
	if scorch_mark:
		scorch_mark.visible = true
		scorch_mark.modulate.a = 0.9

	if not explosion_fx:
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

	# 5. Screen shake
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

## Shooting the rusher before detonation: 1 bullet eliminates it cleanly without exploding!
func take_hit(damage: int = 1) -> void:
	if is_dead or _has_detonated:
		return

	current_health = clampi(current_health - damage, 0, max_health)

	if current_health <= 0:
		is_dead = true
		rusher_state = RusherState.DEAD
		set_physics_process(false)

		if alert_icon:
			alert_icon.visible = false
		if warning_led:
			warning_led.visible = false
		if warning_glow:
			warning_glow.visible = false

		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		if hurtbox_col:
			hurtbox_col.set_deferred("disabled", true)

		if AudioManager:
			AudioManager.play_sfx("enemy_kill")
		eliminated.emit()

		# Clean defeat animation (NO explosion!)
		if sprite:
			var tween := create_tween()
			tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.04)
			tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.08)
			tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.08)
			tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		if AudioManager:
			AudioManager.play_sfx("enemy_hit")
