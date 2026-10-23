class_name RisingAbyss
extends Node2D

## Rising Abyss Hazard Controller for Level 18: The Rising Abyss (World 4: Final Hell)
## Scripted, deterministic upward abyssal void/flame escape hazard.
## Escalating phases: Warning -> Awakening Rise -> Sinking Surge -> Infernal Climb -> Final Abyss Surge.
## Synchronized visual crest and lethal collision boundary.
## Max height strictly capped at max_height_y (-650.0) ensuring the Exit Gate at Y=-840 is never blocked.
## Resets cleanly on level retry and player revive.

signal abyss_warning_started
signal abyss_surge_started

@export var initial_y: float = 520.0
@export var max_height_y: float = -650.0
@export var level_width: float = 1400.0
@export var abyss_depth: float = 2200.0

var current_surface_y: float = 520.0
var _elapsed_time: float = 0.0
var _warning_emitted: bool = false
var _surge_emitted: bool = false
var _wave_phase: float = 0.0

@onready var hazard_area: Area2D = get_node_or_null("HazardArea")
@onready var collision_shape: CollisionShape2D = get_node_or_null("HazardArea/CollisionShape2D")

func _ready() -> void:
	current_surface_y = initial_y
	position.y = initial_y
	GameManager.coins_reset.connect(reset)
	_setup_collision()
	reset()

func _setup_collision() -> void:
	if not hazard_area:
		hazard_area = Area2D.new()
		hazard_area.name = "HazardArea"
		hazard_area.collision_layer = 4 # Hazard layer
		hazard_area.collision_mask = 1  # Player mask
		hazard_area.body_entered.connect(_on_hazard_body_entered)
		add_child(hazard_area)

	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var r := RectangleShape2D.new()
		r.size = Vector2(level_width + 400.0, abyss_depth)
		collision_shape.shape = r
		# Center of collision is half depth below surface
		collision_shape.position = Vector2(level_width * 0.5, abyss_depth * 0.5)
		hazard_area.add_child(collision_shape)

func _physics_process(delta: float) -> void:
	_elapsed_time += delta
	_wave_phase += delta * 4.5

	# Calculate deterministic surface height based on elapsed run time
	current_surface_y = _calculate_surface_height(_elapsed_time)
	position.y = current_surface_y

	# Check overlapping bodies
	if hazard_area:
		for body in hazard_area.get_overlapping_bodies():
			_kill_player(body)

	# Safety sweep against active player nodes
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if is_instance_valid(player) and not player.is_queued_for_deletion() and player.has_method("die") and player._is_alive:
			var player_bottom_y: float = player.global_position.y + 14.0
			if player_bottom_y >= current_surface_y:
				_kill_player(player)

	queue_redraw()

func _calculate_surface_height(t: float) -> float:
	# Scripted deterministic ascent across 5 sequential time windows:
	# 1. 0s - 4s: Warning Phase at 520.0
	if t < 4.0:
		if not _warning_emitted and t >= 1.0:
			_warning_emitted = true
			abyss_warning_started.emit()
			if AudioManager.has_method("play_sfx"):
				AudioManager.play_sfx("warning")
		return initial_y

	# 2. 4s - 16s (12s): Awakening Rise from 520.0 to 320.0 (rate = 16.67 px/s)
	elif t < 16.0:
		var progress := (t - 4.0) / 12.0
		return lerpf(520.0, 320.0, progress)

	# 3. 16s - 32s (16s): Sinking Surge from 320.0 to 40.0 (rate = 17.50 px/s)
	elif t < 32.0:
		var progress := (t - 16.0) / 16.0
		return lerpf(320.0, 40.0, progress)

	# 4. 32s - 52s (20s): The Infernal Climb from 40.0 to -340.0 (rate = 19.00 px/s)
	elif t < 52.0:
		var progress := (t - 32.0) / 20.0
		return lerpf(40.0, -340.0, progress)

	# 5. 52s - 75s (23s): Final Abyss Surge from -340.0 to -650.0 (rate = 13.48 px/s)
	elif t < 75.0:
		if not _surge_emitted:
			_surge_emitted = true
			abyss_surge_started.emit()
			if AudioManager.has_method("play_sfx"):
				AudioManager.play_sfx("warning")
		var progress := (t - 52.0) / 23.0
		return lerpf(-340.0, max_height_y, progress)

	# Capped strictly at max_height_y (-650.0)
	else:
		return max_height_y

func _on_hazard_body_entered(body: Node2D) -> void:
	_kill_player(body)

func _kill_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player") or body.name == "Player":
		GameManager.trigger_player_death()

func _draw() -> void:
	var left_x := -150.0
	var right_x := level_width + 150.0
	var seg_w := 24.0
	var seg_count := int((right_x - left_x) / seg_w) + 1

	# 1. Sinister Heat / Void Shimmer Line (24px above crest)
	var shimmer_pulse := 0.4 + 0.3 * sin(_wave_phase * 2.2)
	var shimmer_color := Color(1.0, 0.25, 0.35, shimmer_pulse)
	draw_line(Vector2(left_x, -18.0), Vector2(right_x, -18.0), shimmer_color, 2.5)

	# 2. Abyssal Void Surface Points
	var points := PackedVector2Array()
	points.append(Vector2(left_x, abyss_depth))
	for i in range(seg_count + 1):
		var px := left_x + (i * seg_w)
		var py := sin(_wave_phase + (i * 0.48)) * 4.5
		points.append(Vector2(px, py))
	points.append(Vector2(right_x, abyss_depth))

	# 3. Main Void/Molten Abyss Body Fill (Deep crimson / demonic black)
	draw_colored_polygon(points, Color(0.18, 0.03, 0.06, 0.98))

	# 4. Glowing Crest Wave
	for i in range(seg_count):
		var p1 := Vector2(left_x + (i * seg_w), sin(_wave_phase + (i * 0.48)) * 4.5)
		var p2 := Vector2(left_x + ((i + 1) * seg_w), sin(_wave_phase + ((i + 1) * 0.48)) * 4.5)
		# Upper searing flame line
		draw_line(p1, p2, Color(1.0, 0.35, 0.45, 0.98), 3.5)
		# Lower dark crimson glow line
		draw_line(p1 + Vector2(0, 4), p2 + Vector2(0, 4), Color(0.85, 0.15, 0.2, 0.75), 3.0)

	# 5. Rising Abyssal Void Orbs / Cursed Sparks
	for b in range(7):
		var bx := left_x + fmod(b * 210.0 + _elapsed_time * 35.0, right_x - left_x)
		var by := sin(_wave_phase + (b * 1.6)) * 4.5 - 3.0
		var orb_r := 3.5 + sin(_wave_phase * 3.2 + b) * 1.5
		draw_circle(Vector2(bx, by), maxf(1.8, orb_r), Color(1.0, 0.8, 0.3, 0.9))

func get_abyss_progress_percentage() -> float:
	# Returns 0.0% at start (520) to 100.0% at max ceiling (-650)
	var total_travel := initial_y - max_height_y
	var current_travel := initial_y - current_surface_y
	return clampf((current_travel / total_travel) * 100.0, 0.0, 100.0)

func reset() -> void:
	_elapsed_time = 0.0
	_warning_emitted = false
	_surge_emitted = false
	current_surface_y = initial_y
	position.y = initial_y
	queue_redraw()
