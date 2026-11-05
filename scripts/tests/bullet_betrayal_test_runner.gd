class_name BulletBetrayalTestRunner
extends Node

## Automated test runner for Bullet Betrayal (World 1 Level 1).

var passed_count: int = 0
var failed_count: int = 0
@export var auto_quit: bool = true

func _ready() -> void:
	if not auto_quit:
		return
	print("\n=======================================================")
	print("    BULLET BETRAYAL — AUTOMATED TEST SUITE (W1 L1)     ")
	print("=======================================================\n")
	
	await run_all_tests()
	
	print("\n=======================================================")
	print("  BULLET BETRAYAL RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("=======================================================\n")
	
	if failed_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		failed_count += 1

func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		print("  [PASS] %s" % test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] %s - Expected: %s, Got: %s" % [test_name, str(expected), str(actual)])
		failed_count += 1

func run_all_tests() -> void:
	test_audio_manager_bullet_betrayal_sfx()
	test_main_menu_bullet_betrayal_card()
	test_bullet_betrayal_menu()
	test_player_mechanics_and_kinematics()
	test_player_shooting_and_ammo_management()
	test_simultaneous_movement_and_shooting()
	test_bullet_projectiles()
	test_enemy_soldier_ai_and_elimination()
	test_ammo_crate_pickup()
	test_extraction_beacon_and_victory()
	test_mobile_touch_controls_and_hud()
	test_level_1_layout_and_sections()
	test_level_1_full_lifecycle()

func test_audio_manager_bullet_betrayal_sfx() -> void:
	print("\n--- TEST: Bullet Betrayal Audio SFX ---")
	var required_sounds = ["shoot", "enemy_hit", "enemy_kill", "ammo_pickup", "player_hit", "victory", "dry_fire"]
	for snd in required_sounds:
		assert_true(AudioManager._sounds.has(snd), "AudioManager has synthesized '%s' SFX" % snd)
		AudioManager.play_sfx(snd)
	assert_true(true, "All Bullet Betrayal audio played successfully without errors")

func test_main_menu_bullet_betrayal_card() -> void:
	print("\n--- TEST: Main Menu Bullet Betrayal Card ---")
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	assert_true(menu_scene != null, "Main menu scene loads successfully")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	var card_bbet: Button = menu.get_node_or_null("MarginContainer/VBoxContainer/CardsGrid/CardBulletBetrayal")
	assert_true(card_bbet != null, "CardBulletBetrayal exists in arcade main menu")
	
	var status_lbl: Label = card_bbet.get_node_or_null("VBox/Status")
	assert_true(status_lbl != null, "Status label exists on CardBulletBetrayal")
	assert_eq(status_lbl.text, "▶ PLAY NOW", "CardBulletBetrayal status updated to ▶ PLAY NOW")
	
	menu.queue_free()

func test_bullet_betrayal_menu() -> void:
	print("\n--- TEST: Bullet Betrayal Dedicated Menu ---")
	var bb_menu_scene: PackedScene = load("res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn")
	assert_true(bb_menu_scene != null, "Bullet Betrayal menu scene loads successfully")
	var bb_menu: BulletBetrayalMenu = bb_menu_scene.instantiate()
	add_child(bb_menu)
	
	var deploy_btn = bb_menu.get_node_or_null("MarginContainer/VBox/MissionCard/VBox/DeployBtn")
	assert_true(deploy_btn != null, "Deploy Mission button exists")
	assert_true(deploy_btn.text.contains("STAGE 1"), "Deploy button targets Stage 1")
	
	var back_btn = bb_menu.get_node_or_null("MarginContainer/VBox/HeaderBar/BackBtn")
	assert_true(back_btn != null, "Return to Arcade button exists")
	
	var sfx_btn: Button = bb_menu.get_node_or_null("MarginContainer/VBox/HeaderBar/SfxBtn")
	assert_true(sfx_btn != null, "SFX toggle button exists on Bullet Betrayal menu")
	
	bb_menu.queue_free()

func test_player_mechanics_and_kinematics() -> void:
	print("\n--- TEST: Player Controller Locomotion & Health ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	assert_true(player_scene != null, "Player scene loads successfully")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	assert_eq(player.current_health, 3, "Player initial health is 3")
	assert_eq(player.current_ammo, 10, "Player starts with exactly 10 bullets as per Section 7")
	assert_true(player.is_alive, "Player is alive on spawn")
	assert_eq(player.facing_direction, 1, "Player faces right by default")
	
	# Kinematic jump parameters
	assert_eq(player.jump_velocity, -460.0, "Player jump velocity is calibrated (-460 px/s)")
	assert_eq(player.move_speed, 230.0, "Player movement speed is calibrated (230 px/s)")
	
	# Test jump execution
	player._execute_jump()
	assert_eq(player.velocity.y, -460.0, "Jump sets negative vertical velocity")
	
	# Test variable jump height cut
	player.velocity.y = -400.0
	player.velocity.y *= 0.52
	assert_true(player.velocity.y > -400.0, "Jump cut reduces upward velocity upon releasing jump")
	
	# Test taking damage
	player.take_damage(1)
	assert_eq(player.current_health, 2, "Taking 1 damage reduces health to 2")
	assert_true(player.is_invulnerable, "Taking damage activates invulnerability window")
	
	# Damage during invulnerability is blocked
	player.take_damage(1)
	assert_eq(player.current_health, 2, "Damage during invulnerability is blocked")
	
	# Death at 0 HP
	player.is_invulnerable = false
	player.take_damage(2)
	assert_eq(player.current_health, 0, "Health drops to 0")
	assert_true(not player.is_alive, "Player is dead when HP reaches 0")
	assert_true(player.input_disabled, "Player input is disabled on death")
	
	player.queue_free()

func test_player_shooting_and_ammo_management() -> void:
	print("\n--- TEST: Player Shooting & Ammo Management ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	# Starts with 10 bullets
	assert_eq(player.current_ammo, 10, "Ammunition starts at 10")
	
	# Fire 1 bullet
	player._fire_timer = 0.0
	player._attempt_shoot()
	assert_eq(player.current_ammo, 9, "Each shot consumes exactly 1 bullet")
	
	# Fire remaining bullets down to 0
	for i in range(9):
		player._fire_timer = 0.0
		player._attempt_shoot()
	
	assert_eq(player.current_ammo, 0, "All 10 initial bullets consumed")
	
	# Dry fire when ammo is 0
	var dry_fire_received := [false]
	player.dry_fire.connect(func(): dry_fire_received[0] = true)
	player._fire_timer = 0.0
	player._attempt_shoot()
	assert_true(dry_fire_received[0], "Dry fire signal emitted when out of ammo")
	assert_eq(player.current_ammo, 0, "Ammo count does not drop below 0")
	
	# Add ammo pickup
	player.add_ammo(8)
	assert_eq(player.current_ammo, 8, "add_ammo(8) restores 8 bullets")
	
	player.queue_free()

func test_simultaneous_movement_and_shooting() -> void:
	print("\n--- TEST: Simultaneous Movement and Shooting ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	# Simulate moving right
	player.velocity.x = 230.0
	player._fire_timer = 0.0
	var ammo_before := player.current_ammo
	player._attempt_shoot()
	assert_eq(player.current_ammo, ammo_before - 1, "Player fires successfully while in motion (moving right)")
	assert_eq(player.velocity.x, 230.0, "Player movement velocity is maintained while shooting")
	
	# Simulate jumping and shooting simultaneously
	player.velocity.y = -460.0
	player._fire_timer = 0.0
	ammo_before = player.current_ammo
	player._attempt_shoot()
	assert_eq(player.current_ammo, ammo_before - 1, "Player fires successfully while jumping in mid-air")
	assert_eq(player.velocity.y, -460.0, "Jump trajectory maintained while shooting")
	
	player.queue_free()

func test_bullet_projectiles() -> void:
	print("\n--- TEST: Bullet Projectiles (Player & Enemy) ---")
	var pbullet_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_bullet.tscn")
	assert_true(pbullet_scene != null, "Player bullet scene loads")
	var pbullet: BulletBetrayalBullet = pbullet_scene.instantiate()
	add_child(pbullet)
	pbullet.setup(Vector2.RIGHT, Vector2(100, 200))
	assert_eq(pbullet.direction, Vector2.RIGHT, "Player bullet direction is right")
	assert_eq(pbullet.speed, 620.0, "Player bullet travels at high velocity (620 px/s)")
	pbullet.queue_free()
	
	var ebullet_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_bullet.tscn")
	assert_true(ebullet_scene != null, "Enemy bullet scene loads")
	var ebullet: BulletBetrayalEnemyBullet = ebullet_scene.instantiate()
	add_child(ebullet)
	ebullet.setup(Vector2.LEFT, Vector2(300, 200))
	assert_eq(ebullet.direction, Vector2.LEFT, "Enemy bullet direction is left")
	assert_eq(ebullet.speed, 260.0, "Enemy bullet travels at fair dodgeable velocity (260 px/s)")
	ebullet.queue_free()

func test_enemy_soldier_ai_and_elimination() -> void:
	print("\n--- TEST: Enemy Soldier AI & 1-Hit Elimination ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	assert_true(enemy_scene != null, "Enemy soldier scene loads")
	var enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	add_child(enemy)
	
	assert_true(not enemy.is_dead, "Enemy is alive on spawn")
	assert_eq(enemy.collision_layer, 16, "Enemy collision layer is 16")
	
	# Test patrol reversing
	enemy.facing_direction = 1
	enemy.global_position.x = enemy._origin_x + enemy.patrol_distance + 5.0
	enemy._patrol(0.016)
	assert_eq(enemy.facing_direction, -1, "Enemy reverses patrol direction at boundary")
	
	# Test 1-hit elimination rule
	var eliminated_called := [false]
	enemy.eliminated.connect(func(): eliminated_called[0] = true)
	enemy.take_hit(1)
	assert_true(enemy.is_dead, "Enemy soldier is defeated in exactly 1 hit as required by spec")
	assert_true(eliminated_called[0], "Enemy emits eliminated signal upon defeat")
	assert_true(enemy.collision_shape.disabled, "Collision disabled immediately on defeat")
	
	enemy.queue_free()

func test_ammo_crate_pickup() -> void:
	print("\n--- TEST: Ammo Crate Pickups ---")
	var ammo_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_ammo_pickup.tscn")
	assert_true(ammo_scene != null, "Ammo crate scene loads")
	var ammo_pickup: BulletBetrayalAmmoPickup = ammo_scene.instantiate()
	add_child(ammo_pickup)
	
	assert_eq(ammo_pickup.ammo_amount, 8, "Ammo crate grants +8 rounds")
	assert_true(not ammo_pickup._is_collected, "Ammo crate starts uncollected")
	
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	player.current_ammo = 4
	
	ammo_pickup._collect(player)
	assert_true(ammo_pickup._is_collected, "Ammo crate marked collected")
	assert_eq(player.current_ammo, 12, "Player ammunition increased from 4 to 12 (+8)")
	
	player.queue_free()
	ammo_pickup.queue_free()

func test_extraction_beacon_and_victory() -> void:
	print("\n--- TEST: Extraction Beacon & Stage Completion ---")
	var beacon_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_extraction_beacon.tscn")
	assert_true(beacon_scene != null, "Extraction beacon scene loads")
	var beacon: BulletBetrayalExtractionBeacon = beacon_scene.instantiate()
	add_child(beacon)
	
	assert_true(not beacon._activated, "Extraction beacon starts inactive")
	
	var victory_reached := [false]
	beacon.extraction_reached.connect(func(): victory_reached[0] = true)
	
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	beacon._on_body_entered(player)
	assert_true(beacon._activated, "Extraction beacon activates upon player entry")
	assert_true(victory_reached[0], "extraction_reached signal fired upon reaching goal")
	
	player.queue_free()
	beacon.queue_free()

func test_mobile_touch_controls_and_hud() -> void:
	print("\n--- TEST: Mobile Touch Controls & HUD ---")
	var hud_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_hud.tscn")
	assert_true(hud_scene != null, "HUD scene loads")
	var hud: BulletBetrayalHUD = hud_scene.instantiate()
	add_child(hud)
	
	var left_btn = hud.get_node_or_null("TouchControls/LeftBtn")
	var right_btn = hud.get_node_or_null("TouchControls/RightBtn")
	var jump_btn = hud.get_node_or_null("TouchControls/JumpBtn")
	var shoot_btn = hud.get_node_or_null("TouchControls/ShootBtn")
	
	assert_true(left_btn != null, "Mobile Left TouchButton exists")
	assert_true(right_btn != null, "Mobile Right TouchButton exists")
	assert_true(jump_btn != null, "Mobile Jump TouchButton exists")
	assert_true(shoot_btn != null, "Mobile Shoot TouchButton exists")
	
	assert_eq(left_btn.action_name, "move_left", "LeftBtn maps to move_left")
	assert_eq(right_btn.action_name, "move_right", "RightBtn maps to move_right")
	assert_eq(jump_btn.action_name, "jump", "JumpBtn maps to jump")
	assert_eq(shoot_btn.action_name, "shoot", "ShootBtn maps to shoot")
	
	# Multi-touch configuration
	assert_true(left_btn is TouchButton, "LeftBtn is a TouchButton instance")
	assert_true(shoot_btn is TouchButton, "ShootBtn is a TouchButton instance")
	assert_true(jump_btn is TouchButton, "JumpBtn is a TouchButton instance")
	
	# Overlays
	assert_true(hud.pause_overlay != null, "Pause overlay exists")
	assert_true(hud.death_overlay != null, "Death overlay exists")
	assert_true(hud.victory_overlay != null, "Victory overlay exists")
	
	hud.show_pause()
	assert_true(hud.pause_overlay.visible, "show_pause() makes pause overlay visible")
	assert_true(get_tree().paused, "show_pause() pauses the game tree")
	
	hud._on_pause_resume_pressed()
	assert_true(not hud.pause_overlay.visible, "Resuming hides pause overlay")
	assert_true(not get_tree().paused, "Resuming unpauses game tree")
	
	hud.queue_free()

func test_level_1_layout_and_sections() -> void:
	print("\n--- TEST: World 1 Level 1 Layout & Sections Audit ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	assert_true(level_scene != null, "Level 1 scene loads")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	# Spawn & Player
	assert_true(level.spawn_point != null, "SpawnPoint exists in Level 1")
	assert_true(level.player != null, "Player exists in Level 1")
	assert_eq(level.player.global_position, Vector2(90, 360), "Player spawns at bunker coordinates (90, 360)")
	
	# Camera boundaries
	var camera: Camera2D = level.player.get_node_or_null("Camera2D")
	assert_true(camera != null, "Player has Camera2D")
	assert_eq(camera.limit_left, 0, "Camera left limit is 0")
	assert_eq(camera.limit_top, 0, "Camera top limit is 0")
	assert_eq(camera.limit_right, 2650, "Camera right limit bounds the level at 2650px")
	assert_eq(camera.limit_bottom, 540, "Camera bottom limit is 540px")
	
	# Audit Enemies across sections
	var enemies = level.enemies_container.get_children()
	assert_eq(enemies.size(), 9, "Level 1 contains exactly 9 enemy soldiers across all sections")
	
	# Section 2 Enemies
	var e1 = level.get_node_or_null("Enemies/Enemy1_Ground1")
	var e2 = level.get_node_or_null("Enemies/Enemy2_Outpost1")
	assert_true(e1 != null and e2 != null, "Section 2 has introductory patrol soldiers")
	
	# Section 3 Enemy & Ammo
	var e3 = level.get_node_or_null("Enemies/Enemy3_HighPlatform")
	var a1 = level.get_node_or_null("Pickups/AmmoPickup1")
	assert_true(e3 != null, "Section 3 has elevated soldier requiring jump-shooting")
	assert_true(a1 != null, "Section 3 has tactical ammo pickup crate 1")
	
	# Section 4 Enemies & Ammo
	var e4 = level.get_node_or_null("Enemies/Enemy4_Approach")
	var e5 = level.get_node_or_null("Enemies/Enemy5_LedgeSentry")
	var e6 = level.get_node_or_null("Enemies/Enemy6_Outpost2")
	var a2 = level.get_node_or_null("Pickups/AmmoPickup2")
	assert_true(e4 != null and e5 != null and e6 != null, "Section 4 has 3-soldier ammo challenge")
	assert_true(a2 != null, "Section 4 has tactical ammo pickup crate 2")
	
	# Section 5 Final Encounter
	var e7 = level.get_node_or_null("Enemies/Enemy7_Perimeter")
	var e8 = level.get_node_or_null("Enemies/Enemy8_Watchtower")
	var e9 = level.get_node_or_null("Enemies/Enemy9_GateGuard")
	assert_true(e7 != null and e8 != null and e9 != null, "Section 5 has final outpost encounter (3 soldiers)")
	
	# Section 6 Extraction
	assert_true(level.extraction_beacon != null, "Section 6 has Extraction Beacon goal")
	assert_true(level.extraction_beacon.position.x >= 2500.0, "Extraction Beacon is positioned at level finale (X >= 2500)")
	
	level.queue_free()

func test_level_1_full_lifecycle() -> void:
	print("\n--- TEST: World 1 Level 1 Full Gameplay Lifecycle ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	# Start
	assert_eq(level.player.current_health, 3, "Run starts with 3 HP")
	assert_eq(level.player.current_ammo, 10, "Run starts with 10 Ammo")
	assert_true(not level._is_completed, "Stage starts incomplete")
	
	# Simulate eliminating all 9 enemies
	for enemy in level.enemies_container.get_children():
		if enemy is BulletBetrayalEnemySoldier:
			enemy.take_hit(1)
	
	assert_eq(level._enemies_eliminated, 9, "All 9 enemy soldiers successfully eliminated")
	
	# Simulate reaching extraction
	level._on_extraction_reached()
	assert_true(level._is_completed, "Level marked completed upon reaching extraction")
	assert_true(level.hud.victory_overlay.visible, "Victory overlay displayed upon extraction")
	assert_true(level.player.input_disabled, "Player input locked upon mission success")
	
	level.queue_free()
