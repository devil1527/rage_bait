class_name BulletBetrayalLevel10
extends Node2D

## World 2 Level 5 (Stage 10): "THE GIANT WORM" — Final World 2 Survival Boss.
## Combines Coin Hell's 60-second survival timer cadence with Bullet Betrayal's
## strict 10-bullet / 10-enemy / 1-life rules and a massive unkillable desert worm boss.
## Completion Rule: player_alive AND enemies_killed == 10 (timer reaching 00:00 enters
## OVERTIME without ending, failing, or auto-completing the stage).

const MENU_SCENE: String = "res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn"
const ARCADE_SCENE: String = "res://scenes/ui/main_menu.tscn"
const ENEMY_SCENE: PackedScene = preload("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")

const TOTAL_REQUIRED_ENEMIES: int = 10
const SURVIVAL_DURATION: float = 60.0
const ENEMY_SPAWN_INTERVAL: float = 6.0
const FIRST_SPAWN_TIME: float = 4.5
const ARENA_MIN_X: float = 48.0
const ARENA_MAX_X: float = 1232.0

@export var survival_duration: float = SURVIVAL_DURATION
@export var spawn_interval: float = ENEMY_SPAWN_INTERVAL
@export var first_spawn_time: float = FIRST_SPAWN_TIME

@onready var player: BulletBetrayalPlayer = $Player
@onready var hud: BulletBetrayalHUD = $HUD
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var enemies_container: Node2D = $Enemies
@onready var giant_worm: BulletBetrayalGiantWorm = $GiantWorm
@onready var intro_banner: Control = get_node_or_null("HUD/IntroBanner")
@onready var timer_panel: PanelContainer = get_node_or_null("HUD/SurvivalTimerPanel")
@onready var timer_label: Label = get_node_or_null("HUD/SurvivalTimerPanel/VBox/SurvivalTimerLabel")
@onready var status_label: Label = get_node_or_null("HUD/SurvivalTimerPanel/VBox/StatusLabel")
@onready var alert_banner: Label = get_node_or_null("HUD/AlertBanner")

# Tracked encounter state (exposed clearly for HUD & verification)
var enemies_spawned: int = 0
var enemies_alive: int = 0
var enemies_killed: int = 0
var enemies_remaining_to_spawn: int = TOTAL_REQUIRED_ENEMIES
var survival_elapsed: float = 0.0
var survival_remaining: float = SURVIVAL_DURATION
var is_overtime: bool = false
var is_surviving: bool = false
var is_completed: bool = false
var spawn_timestamps: Array[float] = []
var active_enemies: Array[BulletBetrayalEnemySoldier] = []

var _paused_for_death: bool = false
var _spawning_stopped: bool = false
var _last_slot_promoted_idx: int = -1
var _pending_spawn_slots: int = 0
var _pending_wait_timer: float = 0.0
var _spawn_cooldown: float = 0.0
var _last_spawn_anchor_idx: int = -1
var _counted_dead_enemies: Dictionary = {}
var _shown_10s_alert: bool = false
var _alert_tween: Tween = null
var _enemy_counter_id: int = 0

const _STYLE_TIMER_NORMAL := Color(1.0, 0.72, 0.22, 0.92)
const _STYLE_TIMER_URGENT := Color(1.0, 0.24, 0.28, 0.96)

const ENEMY_SPAWN_ANCHORS: Array[Dictionary] = [
	{"pos": Vector2(1060.0, 393.0), "patrol": 85.0, "zone": "east_floor"},
	{"pos": Vector2(640.0, 321.0), "patrol": 56.0, "zone": "center_dais"},
	{"pos": Vector2(220.0, 393.0), "patrol": 85.0, "zone": "west_floor"},
	{"pos": Vector2(1060.0, 329.0), "patrol": 48.0, "zone": "east_mesa"},
	{"pos": Vector2(850.0, 393.0), "patrol": 80.0, "zone": "mid_east_floor"},
	{"pos": Vector2(220.0, 329.0), "patrol": 48.0, "zone": "west_mesa"},
	{"pos": Vector2(410.0, 393.0), "patrol": 80.0, "zone": "mid_west_floor"},
	{"pos": Vector2(1175.0, 393.0), "patrol": 60.0, "zone": "far_east_floor"},
	{"pos": Vector2(115.0, 393.0), "patrol": 60.0, "zone": "far_west_floor"},
	{"pos": Vector2(640.0, 393.0), "patrol": 95.0, "zone": "center_floor"}
]


func _ready() -> void:
	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		GameManager.current_run_id += 1

	survival_remaining = survival_duration
	is_surviving = true
	enemies_remaining_to_spawn = TOTAL_REQUIRED_ENEMIES

	if hud and player:
		hud.current_stage_id = 10
		hud.stage_clear_subtitle = "GIANT WORM SURVIVAL CLEARED"
		hud.update_stage_title(10)
		hud.connect_player(player)
		hud.restart_requested.connect(restart_level)
		hud.menu_requested.connect(return_to_menu)
		hud.arcade_requested.connect(_on_arcade_requested)
		hud.revive_requested.connect(_on_player_revived)
		hud.update_targets(enemies_killed, TOTAL_REQUIRED_ENEMIES)

	if player and not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

	if giant_worm and not giant_worm.submerged.is_connected(_on_giant_worm_submerged):
		giant_worm.submerged.connect(_on_giant_worm_submerged)

	_update_camera_framing()
	if get_viewport() and not get_viewport().size_changed.is_connected(_update_camera_framing):
		get_viewport().size_changed.connect(_update_camera_framing)
	if player:
		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.reset_smoothing()

	if alert_banner:
		alert_banner.visible = false
	_update_timer_hud()
	_animate_intro_banner()


func _exit_tree() -> void:
	if GameManager:
		GameManager.is_gameplay_active = false


func _update_camera_framing() -> void:
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam:
		return
	cam.limit_left = 0
	cam.limit_right = 1280
	cam.limit_top = 56
	cam.limit_bottom = 508

	var vp := get_viewport()
	var vis_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(960.0, 540.0)
	if vis_size.x <= 0.0 or vis_size.y <= 0.0:
		vis_size = Vector2(960.0, 540.0)

	var target_vis_height: float = 360.0
	var base_zoom: float = clampf(vis_size.y / target_vis_height, 1.30, 1.55)
	var max_horz_zoom: float = vis_size.x / 640.0
	var final_zoom: float = clampf(minf(base_zoom, max_horz_zoom), 1.20, 1.55)
	cam.zoom = Vector2(final_zoom, final_zoom)


func _animate_intro_banner() -> void:
	if not intro_banner:
		return
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(intro_banner, "modulate:a", 1.0, 0.35)
	tween.tween_interval(1.9)
	tween.tween_property(intro_banner, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func(): if is_instance_valid(intro_banner): intro_banner.visible = false)


func _physics_process(delta: float) -> void:
	if player and player.is_alive and player.global_position.y > 520.0:
		player.die()

	if not is_surviving or is_completed or _paused_for_death:
		return

	survival_elapsed += delta
	survival_remaining = maxf(0.0, survival_duration - survival_elapsed)

	if not is_overtime and survival_elapsed >= survival_duration:
		_enter_overtime_state()
	elif not is_overtime and not _shown_10s_alert and survival_remaining <= 10.0:
		_shown_10s_alert = true
		_show_alert_banner("⚠ 10 SECONDS LEFT! ⚠", Color(1.0, 0.32, 0.28, 1.0), 1.5)

	_update_timer_hud()
	_process_enemy_spawn_schedule(delta)


func _enter_overtime_state() -> void:
	is_overtime = true
	survival_remaining = 0.0
	_update_timer_hud()
	AudioManager.play_sfx("warning")
	_show_alert_banner("OVERTIME — ELIMINATE REMAINING ENEMIES!", Color(1.0, 0.25, 0.3, 1.0), 2.1)


func _update_timer_hud() -> void:
	if timer_label:
		if is_overtime:
			timer_label.text = "⚠ OVERTIME · 00:00"
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.28, 1.0))
		else:
			var sec_int: int = ceili(survival_remaining)
			var mins: int = int(sec_int / 60)
			var secs: int = sec_int % 60
			timer_label.text = "⏱ SURVIVE  %02d:%02d" % [mins, secs]
			if survival_remaining <= 10.0:
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.24, 0.28, 1.0))
			elif survival_remaining <= 20.0:
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.18, 1.0))
			else:
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22, 1.0))

	if status_label:
		var left_to_kill: int = maxi(0, TOTAL_REQUIRED_ENEMIES - enemies_killed)
		if is_overtime:
			status_label.text = "OVERTIME: KILL %d REMAINING TARGET%s!" % [left_to_kill, "S" if left_to_kill != 1 else ""]
			status_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.56, 1.0))
		else:
			status_label.text = "SPAWNED: %d/10  ·  TARGETS LEFT: %d" % [enemies_spawned, left_to_kill]
			status_label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0, 0.95))

	if timer_panel:
		var sb := timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = _STYLE_TIMER_URGENT if (is_overtime or survival_remaining <= 10.0) else _STYLE_TIMER_NORMAL


func _show_alert_banner(msg: String, col: Color, hold: float = 1.4) -> void:
	if not alert_banner:
		return
	if _alert_tween:
		_alert_tween.kill()
	alert_banner.text = msg
	alert_banner.add_theme_color_override("font_color", col)
	alert_banner.visible = true
	alert_banner.modulate.a = 1.0
	alert_banner.scale = Vector2(1.08, 1.08)
	_alert_tween = create_tween()
	_alert_tween.tween_property(alert_banner, "scale", Vector2.ONE, 0.14)
	_alert_tween.tween_interval(hold)
	_alert_tween.tween_property(alert_banner, "modulate:a", 0.0, 0.35)
	_alert_tween.tween_callback(func():
		if is_instance_valid(alert_banner):
			alert_banner.visible = false
			alert_banner.modulate.a = 1.0
	)


func _process_enemy_spawn_schedule(delta: float) -> void:
	if _spawning_stopped or enemies_spawned >= TOTAL_REQUIRED_ENEMIES:
		_pending_spawn_slots = 0
		return

	_spawn_cooldown = maxf(0.0, _spawn_cooldown - delta)

	# Promote scheduled 6-second spawn milestones strictly monotonically (max 10 total)
	while (_last_slot_promoted_idx + 1) < TOTAL_REQUIRED_ENEMIES:
		var next_idx: int = _last_slot_promoted_idx + 1
		var due_time: float = first_spawn_time + float(next_idx) * spawn_interval
		if survival_elapsed >= due_time:
			_last_slot_promoted_idx = next_idx
			if enemies_spawned + _pending_spawn_slots < TOTAL_REQUIRED_ENEMIES:
				_pending_spawn_slots += 1
				if _pending_spawn_slots == 1:
					_pending_wait_timer = 0.0
		else:
			break

	# Ask Giant Worm to dive underground smoothly when a scheduled enemy is imminent or due
	if giant_worm and is_instance_valid(giant_worm) and not _spawning_stopped:
		var next_unpromoted: int = _last_slot_promoted_idx + 1
		var imminent := false
		if _pending_spawn_slots > 0:
			imminent = true
		elif next_unpromoted < TOTAL_REQUIRED_ENEMIES:
			var next_due: float = first_spawn_time + float(next_unpromoted) * spawn_interval
			if next_due - survival_elapsed <= 0.65:
				imminent = true
		if imminent and giant_worm.state == BulletBetrayalGiantWorm.WormState.CRAWLING:
			giant_worm.request_soonest_dive(0.30)

	# Drain pending slot if worm is already underground or waited longer than maximum desync window
	if _pending_spawn_slots > 0 and _spawn_cooldown <= 0.0:
		_pending_wait_timer += delta
		var worm_absent_or_buried := (
			giant_worm == null
			or not is_instance_valid(giant_worm)
			or (giant_worm.is_underground() and _pending_wait_timer >= 0.25)
		)
		var desync_timeout := (_pending_wait_timer >= 1.50)
		if worm_absent_or_buried or desync_timeout:
			_consume_pending_spawn()


func _on_giant_worm_submerged() -> void:
	if not is_surviving or is_completed or _paused_for_death or _spawning_stopped:
		return
	if enemies_spawned >= TOTAL_REQUIRED_ENEMIES:
		return

	if _pending_spawn_slots > 0 and _spawn_cooldown <= 0.0:
		_consume_pending_spawn()
		return

	# Worm dove within early coordination window (<= 1.35s before due time): pull next single slot cleanly
	var next_idx: int = _last_slot_promoted_idx + 1
	if _pending_spawn_slots == 0 and next_idx < TOTAL_REQUIRED_ENEMIES and _spawn_cooldown <= 0.0:
		var due_time: float = first_spawn_time + float(next_idx) * spawn_interval
		if due_time - survival_elapsed <= 1.35:
			_last_slot_promoted_idx = next_idx
			_pending_spawn_slots += 1
			_consume_pending_spawn()


func _consume_pending_spawn() -> BulletBetrayalEnemySoldier:
	if _pending_spawn_slots <= 0 or enemies_spawned >= TOTAL_REQUIRED_ENEMIES:
		_pending_spawn_slots = 0
		return null
	_pending_spawn_slots -= 1
	_pending_wait_timer = 0.0
	_spawn_cooldown = 0.85
	return _spawn_next_enemy()


func _spawn_next_enemy() -> BulletBetrayalEnemySoldier:
	if is_completed or _spawning_stopped or enemies_spawned >= TOTAL_REQUIRED_ENEMIES:
		return null
	if not enemies_container or not ENEMY_SCENE:
		return null

	var chosen := _pick_safe_enemy_spawn_anchor()
	var spawn_pos: Vector2 = chosen.get("pos", Vector2(1060.0, 393.0))
	var patrol_dist: float = float(chosen.get("patrol", 70.0))

	var enemy := ENEMY_SCENE.instantiate() as BulletBetrayalEnemySoldier
	if not enemy:
		return null

	_enemy_counter_id += 1
	enemy.name = "BossWaveSoldier_%d" % _enemy_counter_id
	enemy.position = spawn_pos
	enemy.max_health = 1
	enemy.can_shoot = true
	enemy.is_ambush = false
	enemy.patrol_speed = randf_range(52.0, 68.0)
	enemy.patrol_distance = patrol_dist
	enemy.detection_range = 1400.0
	enemy.shoot_interval = randf_range(2.25, 2.75)

	enemies_spawned += 1
	enemies_alive += 1
	enemies_remaining_to_spawn = TOTAL_REQUIRED_ENEMIES - enemies_spawned
	spawn_timestamps.append(survival_elapsed)
	active_enemies.append(enemy)

	enemy.eliminated.connect(_on_enemy_eliminated.bind(enemy))
	enemies_container.add_child(enemy)

	# Stagger first bullet across live soldiers so overlapping shot walls never occur
	if player and is_instance_valid(player):
		enemy.facing_direction = 1 if player.global_position.x >= spawn_pos.x else -1
		enemy._update_facing()
	enemy._shoot_timer = 1.05 + minf(float(enemies_alive - 1) * 0.35, 1.15)

	# Readable pop-in emergence cue
	enemy.scale = Vector2(0.7, 1.3)
	var tw := enemy.create_tween()
	tw.tween_property(enemy, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("warning")

	_update_timer_hud()
	return enemy


func _pick_safe_enemy_spawn_anchor() -> Dictionary:
	var candidates: Array[int] = []
	var fallback_candidates: Array[int] = []
	var space := get_world_2d().direct_space_state if get_world_2d() else null

	for idx in range(ENEMY_SPAWN_ANCHORS.size()):
		var anchor: Dictionary = ENEMY_SPAWN_ANCHORS[idx]
		var pos: Vector2 = anchor["pos"]

		# Never spawn on or right beside the player
		if player and is_instance_valid(player):
			if pos.distance_to(player.global_position) < 135.0:
				continue

		# Verify solid floor support & zero wall overlap on Layer 2
		if space:
			var floor_ray := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0.0, 36.0), 2)
			if space.intersect_ray(floor_ray).is_empty():
				continue
			var wall_box := RectangleShape2D.new()
			wall_box.size = Vector2(18.0, 26.0)
			var wall_q := PhysicsShapeQueryParameters2D.new()
			wall_q.shape = wall_box
			wall_q.transform = Transform2D(0.0, pos)
			wall_q.collision_mask = 2
			wall_q.collide_with_bodies = true
			if not space.intersect_shape(wall_q, 1).is_empty():
				continue

		fallback_candidates.append(idx)

		# Prefer avoiding crowded spots near other active soldiers or an emerged boss
		var crowded := false
		for other in active_enemies:
			if is_instance_valid(other) and not other.is_dead and other.global_position.distance_to(pos) < 76.0:
				crowded = true
				break
		if not crowded and giant_worm and is_instance_valid(giant_worm) and giant_worm.is_emerged():
			if absf(giant_worm.global_position.x - pos.x) < 95.0 and absf(pos.y - 393.0) < 20.0:
				crowded = true

		if not crowded and idx != _last_spawn_anchor_idx:
			candidates.append(idx)

	var pool: Array[int] = candidates if not candidates.is_empty() else fallback_candidates
	if pool.is_empty():
		var alt_idx := 0
		if player and is_instance_valid(player) and player.global_position.x > 640.0:
			alt_idx = 2
		_last_spawn_anchor_idx = alt_idx
		return ENEMY_SPAWN_ANCHORS[alt_idx]

	var chosen_idx: int = pool[randi() % pool.size()]
	_last_spawn_anchor_idx = chosen_idx
	return ENEMY_SPAWN_ANCHORS[chosen_idx]


func _on_enemy_eliminated(enemy: BulletBetrayalEnemySoldier = null) -> void:
	if enemy != null:
		if _counted_dead_enemies.has(enemy):
			return
		_counted_dead_enemies[enemy] = true
		active_enemies.erase(enemy)

	enemies_killed += 1
	enemies_alive = maxi(0, enemies_alive - 1)

	if hud:
		hud.update_targets(enemies_killed, TOTAL_REQUIRED_ENEMIES)
	_update_timer_hud()

	if enemies_killed >= TOTAL_REQUIRED_ENEMIES and not is_completed:
		if player and is_instance_valid(player) and player.is_alive:
			_complete_stage()


func _complete_stage() -> void:
	if is_completed:
		return
	if not player or not is_instance_valid(player) or not player.is_alive:
		return

	is_completed = true
	is_surviving = false
	_spawning_stopped = true
	_pending_spawn_slots = 0

	# Stop Giant Worm, enemies, projectiles & lock player safely
	if giant_worm and is_instance_valid(giant_worm):
		giant_worm.stop_encounter()

	_clear_active_enemy_bullets()
	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.can_shoot = false
			enemy.set_physics_process(false)

	player.input_disabled = true
	player.velocity = Vector2.ZERO

	if hud:
		hud.complete_and_record_stage(10, "GIANT WORM SURVIVAL CLEARED", player.current_ammo)
	else:
		var earned_stars: int = 2 if (GameManager and GameManager.revives_used_this_run > 0) else 3
		if SaveManager:
			SaveManager.complete_bb_level(10, earned_stars)
		if AudioManager:
			AudioManager.play_sfx("complete")


func _on_player_died() -> void:
	_paused_for_death = true
	is_surviving = false
	_clear_active_enemy_bullets()
	if giant_worm and is_instance_valid(giant_worm):
		giant_worm.set_physics_process(false)
	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.set_physics_process(false)


func _on_player_revived() -> void:
	_paused_for_death = false
	is_surviving = true
	_clear_active_enemy_bullets()

	if player and is_instance_valid(player):
		var safe_pos: Vector2 = player.get_safe_revive_position()
		player.global_position = safe_pos
		player.velocity = Vector2.ZERO
		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.reset_smoothing()

	# Preserve Giant Worm encounter and remaining living enemies cleanly (never reset)
	if giant_worm and is_instance_valid(giant_worm) and not is_completed:
		giant_worm.set_physics_process(true)

	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.set_physics_process(true)
			enemy._shoot_timer = maxf(enemy._shoot_timer, 1.15)

	if hud:
		hud.update_targets(enemies_killed, TOTAL_REQUIRED_ENEMIES)
	_update_timer_hud()


func _clear_active_enemy_bullets() -> void:
	var parent_node := get_parent()
	for container in [self, parent_node]:
		if not container:
			continue
		for child in container.get_children():
			if child is BulletBetrayalEnemyBullet:
				child.queue_free()


func restart_level() -> void:
	if hud:
		hud.reset_touch_controls()
	get_tree().paused = false
	get_tree().reload_current_scene()


func return_to_menu() -> void:
	if GameManager:
		GameManager.is_gameplay_active = false
	get_tree().paused = false
	if get_tree().current_scene and get_tree().current_scene.name == "BulletBetrayalTestRunner":
		return
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_arcade_requested() -> void:
	if GameManager:
		GameManager.is_gameplay_active = false
	get_tree().paused = false
	if get_tree().current_scene and get_tree().current_scene.name == "BulletBetrayalTestRunner":
		return
	get_tree().change_scene_to_file(ARCADE_SCENE)
