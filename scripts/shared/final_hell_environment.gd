class_name FinalHellEnvironment
extends Node2D

## Reusable Final Hell atmospheric environment for World 4: Final Hell (Stages 16–20).
## Features deep crimson and burgundy sky backdrop, distant demonic architecture,
## molten lava horizon glow, and floating ash/ember atmospheric particles.

@export var stage_width: float = 2900.0
@export var stage_height: float = 600.0
@export var ember_count: int = 40
@export var ambient_particles: bool = true

@onready var embers_particles: CPUParticles2D = get_node_or_null("EmbersParticles")
@onready var lava_glow: ColorRect = get_node_or_null("LavaGlow")
@onready var pillars_container: Node2D = get_node_or_null("RuinedPillars")

const PILLAR_TEXTURE = preload("res://assets/sprites/ruined_pillar.png")

func _ready() -> void:
	z_as_relative = false
	z_index = -10
	_setup_lava_glow()
	_setup_particles()
	_setup_pillars()

func _setup_lava_glow() -> void:
	if lava_glow:
		lava_glow.size = Vector2(stage_width + 400.0, 140.0)
		lava_glow.position = Vector2(-200.0, stage_height - 120.0)

func _setup_particles() -> void:
	if embers_particles:
		embers_particles.visible = ambient_particles
		embers_particles.amount = ember_count
		embers_particles.position = Vector2(stage_width * 0.5, stage_height - 30.0)
		embers_particles.emission_rect_extents = Vector2(stage_width * 0.5 + 200.0, 20.0)

func _setup_pillars() -> void:
	if not pillars_container:
		pillars_container = Node2D.new()
		pillars_container.name = "RuinedPillars"
		pillars_container.z_index = -4
		add_child(pillars_container)

	if pillars_container.get_child_count() == 0 and PILLAR_TEXTURE:
		var pillar_spacing: float = 550.0
		var current_x: float = 200.0
		var idx: int = 0
		while current_x < stage_width:
			var p := Sprite2D.new()
			p.texture = PILLAR_TEXTURE
			p.name = "Pillar_%d" % idx
			# Vary height and slight scale for visual depth
			var y_pos: float = 340.0 if idx % 2 == 0 else 320.0
			p.position = Vector2(current_x, y_pos)
			p.self_modulate = Color(0.7, 0.45, 0.5, 0.65)
			p.scale = Vector2(1.2, 1.4 if idx % 2 == 0 else 1.1)
			pillars_container.add_child(p)
			current_x += pillar_spacing
			idx += 1
