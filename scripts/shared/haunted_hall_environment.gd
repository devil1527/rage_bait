class_name HauntedHallEnvironment
extends Node2D

## Reusable Haunted Hall atmospheric environment for World 2: The Haunted Hall (Stages 6–10).
## Features layered gothic castle parallax backdrop, moonlight lancet windows,
## ruined arches, ground fog mist, drifting spectral wisps,
## and a recycled pool of non-colliding decorative background ghosts.

@export var ghost_count: int = 8
@export var ghost_speed_scale: float = 1.0
@export var fog_intensity: float = 0.4
@export var ambient_particles: bool = true
@export var stage_width: float = 3000.0
@export var stage_height: float = 600.0

var _ghost_data: Array = []
var _ghost_container: Node2D

@onready var parallax_bg: ParallaxBackground = get_node_or_null("ParallaxBackground")
@onready var ground_mist: ColorRect = get_node_or_null("MistLayer/GroundMist")
@onready var wisps_particles: CPUParticles2D = get_node_or_null("SpectralWisps")
@onready var arches_container: Node2D = get_node_or_null("CastleArches")

const GHOST_TEXTURE = preload("res://assets/sprites/ghost_decor.png")
const ARCH_TEXTURE = preload("res://assets/sprites/gothic_arch.png")

func _ready() -> void:
	z_as_relative = false
	z_index = -10
	
	_setup_ground_mist()
	_setup_particles()
	_setup_arches()
	_setup_ghost_pool()

func _setup_ground_mist() -> void:
	if ground_mist:
		ground_mist.size = Vector2(stage_width + 400.0, 160.0)
		ground_mist.position = Vector2(-200.0, stage_height - 150.0)
		var base_purple := Color(0.12, 0.08, 0.22, fog_intensity)
		ground_mist.color = base_purple

func _setup_particles() -> void:
	if wisps_particles:
		wisps_particles.visible = ambient_particles
		wisps_particles.position = Vector2(stage_width * 0.5, stage_height - 60.0)
		wisps_particles.emission_rect_extents = Vector2(stage_width * 0.5 + 200.0, 30.0)

func _setup_arches() -> void:
	if not arches_container:
		arches_container = Node2D.new()
		arches_container.name = "CastleArches"
		arches_container.z_index = -3
		add_child(arches_container)
	
	# Place ruined arches along the hall if not already placed
	if arches_container.get_child_count() == 0:
		var arch_interval: float = 650.0
		var current_x: float = 250.0
		while current_x < stage_width:
			var arch := Sprite2D.new()
			arch.texture = ARCH_TEXTURE
			arch.position = Vector2(current_x, stage_height - 240.0)
			arch.z_index = -3
			arch.modulate = Color(0.75, 0.72, 0.88, 0.9)
			arches_container.add_child(arch)
			current_x += arch_interval

func _setup_ghost_pool() -> void:
	_ghost_container = Node2D.new()
	_ghost_container.name = "GhostsPool"
	_ghost_container.z_index = -5 # Behind castle arches (-3) and gameplay (0)
	add_child(_ghost_container)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261013 # Deterministic seed for reproducible testing
	
	# Palettes: pale spectral blue, ghostly white, faint green
	var ghost_colors: Array[Color] = [
		Color(0.82, 0.94, 1.0, 0.65),   # Pale spectral blue
		Color(0.95, 0.96, 1.0, 0.72),   # Ghostly white
		Color(0.78, 1.0, 0.88, 0.60),   # Faint green
		Color(0.88, 0.88, 1.0, 0.68)    # Spectral violet-white
	]
	
	_ghost_data.clear()
	for i in range(ghost_count):
		var ghost_spr := Sprite2D.new()
		ghost_spr.texture = GHOST_TEXTURE
		
		# Varied scale between 0.75 and 1.25
		var sc := rng.randf_range(0.75, 1.25)
		ghost_spr.scale = Vector2(sc, sc)
		
		# Varied color and transparency
		var color_idx := i % ghost_colors.size()
		ghost_spr.modulate = ghost_colors[color_idx]
		
		# Distributed horizontally across the stage
		var start_x := rng.randf_range(50.0, stage_width - 50.0)
		var start_y := rng.randf_range(80.0, stage_height - 180.0)
		ghost_spr.position = Vector2(start_x, start_y)
		
		# Decorative only: pure Sprite2D with NO collision shape, NO Area2D
		_ghost_container.add_child(ghost_spr)
		
		# Varied speeds and movement paths
		var dir := 1.0 if (i % 2 == 0) else -1.0
		var h_speed := rng.randf_range(22.0, 48.0) * dir
		var bob_amp := rng.randf_range(12.0, 26.0)
		var bob_freq := rng.randf_range(1.2, 2.2)
		var bob_phase := rng.randf_range(0.0, TAU)
		var fade_freq := rng.randf_range(0.8, 1.6)
		var fade_phase := rng.randf_range(0.0, TAU)
		var base_alpha := ghost_spr.modulate.a
		
		_ghost_data.append({
			"sprite": ghost_spr,
			"base_y": start_y,
			"speed_x": h_speed,
			"bob_amp": bob_amp,
			"bob_freq": bob_freq,
			"bob_phase": bob_phase,
			"fade_freq": fade_freq,
			"fade_phase": fade_phase,
			"base_alpha": base_alpha,
			"color_base": ghost_spr.modulate,
			"time": rng.randf_range(0.0, 10.0)
		})

func _process(delta: float) -> void:
	# Update decorative ghost positions smoothly and efficiently
	for data in _ghost_data:
		var spr: Sprite2D = data["sprite"]
		data["time"] += delta
		var t: float = data["time"]
		
		# Horizontal drift
		spr.position.x += data["speed_x"] * ghost_speed_scale * delta
		
		# Sine bobbing in Y
		spr.position.y = data["base_y"] + sin(t * data["bob_freq"] + data["bob_phase"]) * data["bob_amp"]
		
		# Subtle alpha fading in and out
		var alpha_offset: float = sin(t * data["fade_freq"] + data["fade_phase"]) * 0.18
		var target_col: Color = data["color_base"]
		spr.modulate.a = clampf(data["base_alpha"] + alpha_offset, 0.25, 0.85)
		
		# Smooth wrap-around recycling without node allocation
		var margin: float = 60.0
		if data["speed_x"] > 0 and spr.position.x > (stage_width + margin):
			spr.position.x = -margin
			data["base_y"] = randf_range(80.0, stage_height - 180.0)
		elif data["speed_x"] < 0 and spr.position.x < -margin:
			spr.position.x = stage_width + margin
			data["base_y"] = randf_range(80.0, stage_height - 180.0)
