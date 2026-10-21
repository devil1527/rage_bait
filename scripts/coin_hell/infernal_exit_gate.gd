class_name InfernalExitGate
extends "res://scripts/coin_hell/exit_gate.gd"

## World 4 Distinctive Infernal Exit Gate.
## Features demonic obsidian archway with glowing crimson eye glyphs,
## locked red energy seals, and swirling dimensional hellfire when unlocked.

@onready var energy_particles: CPUParticles2D = get_node_or_null("EnergyParticles")

func _init() -> void:
	locked_texture = preload("res://assets/sprites/infernal_exit_locked.png")
	open_texture = preload("res://assets/sprites/infernal_exit_open.png")

func _ready() -> void:
	super._ready()
	if status_label:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.35))
	_update_energy_particles()

func unlock_gate() -> void:
	super.unlock_gate()
	_update_energy_particles()

func _update_energy_particles() -> void:
	if energy_particles:
		if _is_open:
			energy_particles.amount = 32
			energy_particles.color = Color(1.0, 0.6, 0.2, 1.0) # Swirling fire
			energy_particles.speed_scale = 1.4
		else:
			energy_particles.amount = 16
			energy_particles.color = Color(1.0, 0.2, 0.3, 0.7) # Simmering crimson
			energy_particles.speed_scale = 0.8
