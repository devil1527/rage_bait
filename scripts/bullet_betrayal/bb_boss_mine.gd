class_name BulletBetrayalBossMine
extends Node2D

## Huge Timed Explosive Mine left behind at the Giant Worm's exact retreat spot
## in World 2, Stage 10. Counts down 10 seconds with escalating visual warnings
## and an expanding perimeter telegraph before detonating in a large 128px blast
## that kills any player inside the lethal radius (including on nearby hanging bars)
## while never auto-killing the 10 required enemy soldiers.

signal exploded(mine: Node2D, pos: Vector2, radius: float)
signal player_killed_by_mine

@export var fuse_duration: float = 10.0
@export var blast_radius: float = 128.0

var fuse_remaining: float = 10.0
var is_active: bool = true
var is_paused: bool = false
var _has_exploded: bool = false
var _disarmed: bool = false
var _pulse_time: float = 0.0
var _explosion_count: int = 0
var _death_events_emitted: int = 0

@onready var mine_sprite: Sprite2D = $Sprite2D
@onready var warning_glow: Sprite2D = $WarningGlow
@onready var warning_led: ColorRect = $WarningLED
@onready var perimeter_ring: Sprite2D = $PerimeterRing
@onready var blast_ring_sphere: Sprite2D = $BlastRadiusPreview
@onready var countdown_label: Label = $CountdownLabel
@onready var scorch_mark: Sprite2D = $ScorchMark
@onready var explosion_fx: Node2D = $ExplosionFX
@onready var flash: ColorRect = $ExplosionFX/Flash
@onready var shockwave: Sprite2D = $ExplosionFX/Shockwave
@onready var fire_core: Sprite2D = $ExplosionFX/FireCore
@onready var fire_plume: Sprite2D = $ExplosionFX/FirePlume
@onready var shrapnel_particles: CPUParticles2D = $ExplosionFX/ShrapnelParticles
@onready var smoke_particles: CPUParticles2D = $ExplosionFX/SmokeParticles


func _ready() -> void:
	add_to_group("boss_mines")
	add_to_group("hazards")
	fuse_remaining = fuse_duration
	is_active = true
	if scorch_mark:
		scorch_mark.visible = false
	if explosion_fx:
		explosion_fx.visible = false
	_update_visual_warning(0.0)
	_play_burrow_emerge_in()


func _play_burrow_emerge_in() -> void:
	if mine_sprite:
		mine_sprite.scale = Vector2(1.8, 1.4)
		var tw := create_tween()
		tw.tween_property(mine_sprite, "scale", Vector2(2.6, 2.5), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if _has_exploded or _disarmed or not is_active or is_paused:
		return

	fuse_remaining = maxf(0.0, fuse_remaining - delta)
	_update_visual_warning(delta)

	if fuse_remaining <= 0.0:
		detonate()


func _update_visual_warning(delta: float) -> void:
	var progress: float = clampf(1.0 - (fuse_remaining / maxf(0.01, fuse_duration)), 0.0, 1.0)
	var freq: float = lerpf(3.2, 20.0, progress * progress)
	_pulse_time += delta * freq
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time)

	# Escalating shake as detonation nears (< 3.5s)
	if mine_sprite:
		if fuse_remaining <= 3.5:
			var mag: float = lerpf(1.0, 3.2, 1.0 - (fuse_remaining / 3.5))
			mine_sprite.position = Vector2(sin(_pulse_time * 1.7) * mag, -15.0 + cos(_pulse_time * 1.3) * mag * 0.4)
		else:
			mine_sprite.position = Vector2(0.0, -15.0)

		if fuse_remaining <= 2.0 and pulse > 0.55:
			mine_sprite.modulate = Color(1.65, 0.52, 0.38, 1.0)
		else:
			mine_sprite.modulate = Color(lerpf(1.1, 1.35, progress), lerpf(0.75, 0.58, progress), lerpf(0.58, 0.44, progress), 1.0)

	if warning_led:
		warning_led.visible = true
		warning_led.color = (
			Color(1.0, 0.92, 0.80, 1.0)
			if (fuse_remaining <= 2.2 and pulse > 0.65)
			else Color(1.0, lerpf(0.28, 0.55, pulse), 0.12, lerpf(0.50, 1.0, pulse))
		)

	if warning_glow:
		warning_glow.visible = true
		var g_scale: float = lerpf(1.8, 3.3, pulse * (0.55 + 0.45 * progress))
		warning_glow.scale = Vector2(g_scale, g_scale)
		warning_glow.modulate = Color(1.0, lerpf(0.32, 0.14, progress), 0.10, lerpf(0.35, 0.92, pulse))

	# Show exact visual blast-radius footprint matching 128px blast_radius
	var ring_scale_match: float = blast_radius / 32.0 # bb_shockwave_ring is 64x64 (radius 32)
	if perimeter_ring:
		perimeter_ring.visible = true
		perimeter_ring.scale = Vector2(ring_scale_match, 0.68)
		perimeter_ring.modulate = Color(1.0, lerpf(0.45, 0.18, progress), 0.12, lerpf(0.22, 0.78, progress * (0.65 + 0.35 * pulse)))

	if blast_ring_sphere:
		blast_ring_sphere.visible = fuse_remaining <= 3.5
		if blast_ring_sphere.visible:
			blast_ring_sphere.scale = Vector2(ring_scale_match, ring_scale_match)
			blast_ring_sphere.modulate = Color(1.0, 0.24, 0.16, lerpf(0.10, 0.42, (0.4 + 0.6 * pulse) * progress))

	if countdown_label:
		countdown_label.visible = true
		var sec_left: int = maxi(1, ceili(fuse_remaining)) if fuse_remaining > 0.0 else 0
		countdown_label.text = ("⚠ %d" % sec_left) if fuse_remaining <= 3.0 else ("%ds" % sec_left)
		if fuse_remaining <= 2.5:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22, 1.0))
			countdown_label.scale = Vector2(1.16, 1.16) if pulse > 0.5 else Vector2.ONE
		elif fuse_remaining <= 5.0:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.16, 1.0))
			countdown_label.scale = Vector2.ONE
		else:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.24, 1.0))
			countdown_label.scale = Vector2.ONE


func get_blast_origin() -> Vector2:
	return global_position + Vector2(0.0, -12.0)


func is_position_in_blast_radius(world_pos: Vector2) -> bool:
	return get_blast_origin().distance_to(world_pos) <= blast_radius


func get_fuse_remaining() -> float:
	return fuse_remaining


func is_fuse_active() -> bool:
	return is_active and not _has_exploded and not _disarmed


func has_exploded() -> bool:
	return _has_exploded


func get_explosion_count() -> int:
	return _explosion_count


func get_death_events_emitted() -> int:
	return _death_events_emitted


func detonate() -> void:
	if _has_exploded or _disarmed:
		return
	_has_exploded = true
	_explosion_count += 1
	is_active = false
	fuse_remaining = 0.0

	if is_in_group("boss_mines"):
		remove_from_group("boss_mines")
	if is_in_group("hazards"):
		remove_from_group("hazards")

	if warning_led:
		warning_led.visible = false
	if warning_glow:
		warning_glow.visible = false
	if perimeter_ring:
		perimeter_ring.visible = false
	if blast_ring_sphere:
		blast_ring_sphere.visible = false
	if countdown_label:
		countdown_label.visible = false

	var origin: Vector2 = get_blast_origin()
	if AudioManager:
		AudioManager.play_sfx("explosion")

	# Apply lethal blast ONLY to living vulnerable players inside blast_radius (never kill enemies)
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(node) or not (node is Node2D):
				continue
			var player_node := node as Node2D
			if "is_alive" in player_node and not player_node.is_alive:
				continue
			if "is_invulnerable" in player_node and player_node.is_invulnerable:
				continue
			if is_position_in_blast_radius(player_node.global_position):
				if player_node.has_method("take_damage"):
					player_node.take_damage(1)
					_death_events_emitted += 1
					player_killed_by_mine.emit()
					break

	_play_explosion_vfx()
	exploded.emit(self, origin, blast_radius)


func disarm_without_explosion() -> void:
	if _has_exploded or _disarmed:
		return
	_disarmed = true
	is_active = false
	if is_in_group("boss_mines"):
		remove_from_group("boss_mines")
	if is_in_group("hazards"):
		remove_from_group("hazards")
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.22)
		tw.tween_callback(func():
			if is_instance_valid(self):
				queue_free()
		)
	else:
		queue_free()


func _play_explosion_vfx() -> void:
	if scorch_mark:
		scorch_mark.visible = true
		scorch_mark.scale = Vector2(3.6, 2.2)
		scorch_mark.modulate = Color(1.0, 1.0, 1.0, 0.9)

	if not explosion_fx or not is_inside_tree():
		if mine_sprite:
			mine_sprite.visible = false
		queue_free()
		return

	if mine_sprite:
		mine_sprite.visible = false

	explosion_fx.visible = true
	var ring_match_scale: float = blast_radius / 32.0 # Exact 128px visual radius for 64x64 sprite

	if shrapnel_particles:
		shrapnel_particles.restart()
		shrapnel_particles.emitting = true
	if smoke_particles:
		smoke_particles.restart()
		smoke_particles.emitting = true

	if flash:
		flash.visible = true
		flash.scale = Vector2(0.6, 0.6)
		flash.modulate = Color(1.8, 1.5, 0.9, 1.0)
		var flash_tw := create_tween()
		flash_tw.tween_property(flash, "scale", Vector2(2.6, 2.6), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.09)

	if shockwave:
		shockwave.visible = true
		shockwave.scale = Vector2(0.4, 0.4)
		shockwave.modulate = Color(2.0, 1.5, 0.95, 1.0)
		var sw_tw := create_tween()
		sw_tw.tween_property(shockwave, "scale", Vector2(ring_match_scale, ring_match_scale), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sw_tw.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	if fire_core:
		fire_core.visible = true
		fire_core.scale = Vector2(0.5, 0.5)
		fire_core.modulate = Color(2.0, 1.7, 1.0, 1.0)
		var fc_tw := create_tween()
		fc_tw.tween_property(fire_core, "scale", Vector2(ring_match_scale * 0.95, ring_match_scale * 0.85), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fc_tw.parallel().tween_property(fire_core, "modulate", Color(1.4, 0.55, 0.14, 1.0), 0.12)
		fc_tw.tween_property(fire_core, "scale", Vector2(ring_match_scale * 1.02, ring_match_scale * 0.92), 0.32)
		fc_tw.parallel().tween_property(fire_core, "modulate", Color(0.25, 0.14, 0.12, 0.0), 0.32)

	if fire_plume:
		fire_plume.visible = true
		fire_plume.scale = Vector2(0.4, 0.4)
		fire_plume.modulate = Color(1.7, 1.0, 0.4, 1.0)
		var fp_tw := create_tween()
		fp_tw.tween_property(fire_plume, "scale", Vector2(ring_match_scale * 0.72, ring_match_scale * 0.9), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fp_tw.tween_property(fire_plume, "scale", Vector2(ring_match_scale * 0.82, ring_match_scale * 0.96), 0.30)
		fp_tw.parallel().tween_property(fire_plume, "modulate", Color(0.2, 0.15, 0.15, 0.0), 0.30)

	_apply_camera_shake(9.5, 0.32)

	var cleanup_tw := create_tween()
	cleanup_tw.tween_interval(0.58)
	cleanup_tw.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)


func _apply_camera_shake(intensity: float = 9.5, duration: float = 0.32) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var cam: Camera2D = viewport.get_camera_2d()
	if not cam:
		return
	var tween := create_tween()
	var steps: int = 7
	for i in range(steps):
		var decay: float = 1.0 - (float(i) / float(steps))
		tween.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity) * decay, randf_range(-intensity, intensity * 0.5) * decay), duration / float(steps))
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.04)
