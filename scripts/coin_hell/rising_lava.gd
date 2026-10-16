class_name RisingLava
extends Node2D

## Rising Molten Lava Controller for Level 11: Meltdown (World 3: Rage Factory)
## Scripted, deterministic upward molten lava escape hazard.
## Four distinct phases: Warning -> Rise -> Pressure -> Meltdown Surge.
## Synchronized visual crest and lethal collision boundary.
## Max height strictly capped at max_height_y (-480) ensuring the Exit Gate is never blocked.
## Resets cleanly on level retry.

signal lava_warning_started
signal meltdown_surge_started

@export var initial_y: float = 510.0
@export var max_height_y: float = -480.0
@export var level_width: float = 1200.0
@export var lava_depth: float = 1400.0

var current_surface_y: float = 510.0
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
		r.size = Vector2(level_width + 200.0, lava_depth)
		collision_shape.shape = r
		# Center of collision is half depth below surface
		collision_shape.position = Vector2(level_width * 0.5, lava_depth * 0.5)
		hazard_area.add_child(collision_shape)

func _physics_process(delta: float) -> void:
	_elapsed_time += delta
	_wave_phase += delta * 4.0

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
			# Player feet position
			var player_bottom_y: float = player.global_position.y + 14.0
			if player_bottom_y >= current_surface_y:
				_kill_player(player)

	queue_redraw()

func _calculate_surface_height(t: float) -> float:
	# Scripted deterministic ascent across 6 sequential time windows:
	# 1. 0s - 3s: Warning Phase at 510.0
	if t < 3.0:
		if not _warning_emitted and t >= 0.5:
			_warning_emitted = true
			lava_warning_started.emit()
			AudioManager.play_sfx("warning")
		return initial_y

	# 2. 3s - 12s (9s): Rise from 510.0 to 360.0 (rate = 16.67 px/s)
	elif t < 12.0:
		var progress := (t - 3.0) / 9.0
		return lerpf(510.0, 360.0, progress)

	# 3. 12s - 24s (12s): Rise from 360.0 to 160.0 (rate = 16.67 px/s)
	elif t < 24.0:
		var progress := (t - 12.0) / 12.0
		return lerpf(360.0, 160.0, progress)

	# 4. 24s - 42s (18s): Rise from 160.0 to -60.0 (rate = 12.22 px/s)
	elif t < 42.0:
		var progress := (t - 24.0) / 18.0
		return lerpf(160.0, -60.0, progress)

	# 5. 42s - 60s (18s): Rise from -60.0 to -220.0 (rate = 8.89 px/s)
	elif t < 60.0:
		var progress := (t - 42.0) / 18.0
		return lerpf(-60.0, -220.0, progress)

	# 6. 60s - 80s (20s): Meltdown Final Surge from -220.0 to -480.0 (rate = 13.00 px/s)
	elif t < 80.0:
		if not _surge_emitted:
			_surge_emitted = true
			meltdown_surge_started.emit()
			AudioManager.play_sfx("warning")
		var progress := (t - 60.0) / 20.0
		return lerpf(-220.0, max_height_y, progress)

	# Capped at max_height_y (-480.0)
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

func _get_active_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p.has_method("die"):
			return p
	return null

func _draw() -> void:
	var left_x := -100.0
	var right_x := level_width + 100.0
	var seg_w := 24.0
	var seg_count := int((right_x - left_x) / seg_w) + 1

	# 1. Warning Heat Shimmer Line (30px above the molten crest)
	var heat_pulse := 0.3 + 0.2 * sin(_wave_phase * 2.0)
	var heat_color := Color(1.0, 0.45, 0.1, heat_pulse)
	draw_line(Vector2(left_x, -16.0), Vector2(right_x, -16.0), heat_color, 2.0)

	# 2. Molten Surface Points
	var points := PackedVector2Array()
	points.append(Vector2(left_x, lava_depth))
	for i in range(seg_count + 1):
		var px := left_x + (i * seg_w)
		var py := sin(_wave_phase + (i * 0.45)) * 4.0
		points.append(Vector2(px, py))
	points.append(Vector2(right_x, lava_depth))

	# 3. Main Molten Rock Body Fill
	var colors := PackedColorArray([
		Color(0.85, 0.15, 0.05, 0.95), # Molten red-orange
		Color(0.95, 0.45, 0.05, 0.98), # Bright fiery orange
		Color(0.55, 0.05, 0.02, 0.99), # Deep lava red
		Color(0.20, 0.02, 0.01, 1.0)   # Obsidian bedrock
	])
	draw_colored_polygon(points, Color(0.82, 0.18, 0.04, 0.96))

	# 4. Glowing Surface Crest Wave
	for i in range(seg_count):
		var p1 := Vector2(left_x + (i * seg_w), sin(_wave_phase + (i * 0.45)) * 4.0)
		var p2 := Vector2(left_x + ((i + 1) * seg_w), sin(_wave_phase + ((i + 1) * 0.45)) * 4.0)
		# Golden-yellow crest line
		draw_line(p1, p2, Color(1.0, 0.85, 0.2, 0.95), 3.0)
		# Lower orange glow line
		draw_line(p1 + Vector2(0, 3), p2 + Vector2(0, 3), Color(1.0, 0.4, 0.05, 0.7), 2.5)

	# 5. Molten Bubbles
	for b in range(6):
		var bx := left_x + fmod(b * 190.0 + _elapsed_time * 30.0, right_x - left_x)
		var by := sin(_wave_phase + (b * 1.5)) * 4.0 - 2.0
		var bubble_r := 3.0 + sin(_wave_phase * 3.0 + b) * 1.5
		draw_circle(Vector2(bx, by), maxf(1.5, bubble_r), Color(1.0, 0.9, 0.3, 0.85))

func get_lava_progress_percentage() -> float:
	# Returns 0.0% at start (510) to 100.0% at max ceiling (-480)
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
