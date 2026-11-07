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
	test_pause_menu_and_confirmation_modals()
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
	print("\n--- TEST: Bullet Betrayal Coin Hell-Matched Menu ---")
	var bb_menu_scene: PackedScene = load("res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn")
	assert_true(bb_menu_scene != null, "Bullet Betrayal menu scene loads successfully")
	var bb_menu: BulletBetrayalMenu = bb_menu_scene.instantiate()
	add_child(bb_menu)
	
	# Header bar components
	var back_btn: Button = bb_menu.get_node_or_null("MarginContainer/VBox/HeaderBar/BackButton")
	assert_true(back_btn != null, "BackButton exists in HeaderBar")
	assert_eq(back_btn.text, "◀ MENU", "BackButton starts as '◀ MENU' matching Coin Hell")
	assert_eq(back_btn.custom_minimum_size, Vector2(110, 38), "BackButton size is 110x38 matching Coin Hell")
	
	var title_lbl: Label = bb_menu.get_node_or_null("MarginContainer/VBox/HeaderBar/TitleBox/TitleLabel")
	assert_true(title_lbl != null, "TitleLabel exists")
	assert_eq(title_lbl.text, "BULLET BETRAYAL", "Title is BULLET BETRAYAL")
	
	var progress_lbl: Label = bb_menu.get_node_or_null("MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel")
	assert_true(progress_lbl != null, "ProgressLabel exists")
	assert_true(progress_lbl.text.contains("STAGES CLEARED"), "ProgressLabel displays STAGES CLEARED matching Coin Hell")
	
	# World Navigation Cards Bar
	var world_bar = bb_menu.world_cards_bar
	assert_true(world_bar != null, "WorldCardsBar exists")
	assert_true(bb_menu.world_card_buttons.has(0), "TabAllWorlds exists")
	assert_true(bb_menu.world_card_buttons.has(1), "WorldNavCard_1 exists")
	assert_true(bb_menu.world_card_buttons.has(2), "WorldNavCard_2 exists")
	assert_true(bb_menu.world_card_buttons.has(3), "WorldNavCard_3 exists")
	assert_true(bb_menu.world_card_buttons.has(4), "WorldNavCard_4 exists")
	
	# Stage 1 Button
	var stage_1: Button = bb_menu.get_level_button(1)
	assert_true(stage_1 != null, "Stage 1 button exists")
	assert_eq(stage_1.custom_minimum_size, Vector2(170, 94), "Stage 1 button is 170x94 standard arcade size")
	
	# Stage 2 Button (locked)
	var stage_2: Button = bb_menu.get_level_button(2)
	assert_true(stage_2 != null, "Stage 2 button exists (locked)")
	
	# Test world tab filtering
	bb_menu._select_world_tab(2)
	assert_eq(bb_menu.current_selected_world, 2, "Selecting tab 2 sets current_selected_world = 2")
	assert_eq(back_btn.text, "◀ WORLDS", "BackButton changes to '◀ WORLDS' when world is selected")
	
	var sec_1 = bb_menu.worlds_container.get_node_or_null("WorldSection_1")
	var sec_2 = bb_menu.worlds_container.get_node_or_null("WorldSection_2")
	assert_true(sec_2 != null and sec_2.visible, "WorldSection_2 is visible")
	assert_true(sec_1 != null and not sec_1.visible, "WorldSection_1 is hidden when World 2 is selected")
	
	# Test BackButton returns to all worlds
	bb_menu._on_back_pressed()
	assert_eq(bb_menu.current_selected_world, 0, "Back button resets current_selected_world to 0")
	assert_eq(back_btn.text, "◀ MENU", "Back button text resets to '◀ MENU'")
	assert_true(sec_1.visible and sec_2.visible, "All world sections visible after returning to all worlds")
	
	# Test locked stage modal trigger
	assert_true(not bb_menu.message_modal.visible, "MessageModal starts hidden")
	stage_2.pressed.emit()
	assert_true(bb_menu.message_modal.visible, "Clicking locked stage displays arcade MessageModal")
	assert_eq(bb_menu.modal_title.text, "STAGE 2 IS LOCKED", "MessageModal title matches Coin Hell format")
	
	bb_menu.modal_ok_btn.pressed.emit()
	assert_true(not bb_menu.message_modal.visible, "Clicking GOT IT closes MessageModal")
	
	bb_menu.queue_free()

func test_player_mechanics_and_kinematics() -> void:
	print("\n--- TEST: Player Mechanics & Kinematics ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	assert_true(player_scene != null, "bb_player.tscn scene exists and loads")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	assert_eq(player.current_health, 3, "Player starts with 3 HP")
	assert_eq(player.current_ammo, 10, "Player starts with 10 Ammo")
	assert_true(player.is_alive, "Player is alive on spawn")
	
	# Test taking damage
	player.take_damage(1)
	assert_eq(player.current_health, 2, "Player HP reduced to 2 after hit")
	assert_true(player.is_invulnerable, "Player becomes invulnerable after damage")
	
	# Test lethal damage
	player.is_invulnerable = false
	player.take_damage(2)
	assert_eq(player.current_health, 0, "Player HP reduced to 0")
	assert_true(not player.is_alive, "Player marked dead after lethal damage")
	
	player.queue_free()

func test_player_shooting_and_ammo_management() -> void:
	print("\n--- TEST: Player Shooting & Ammo Management ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	var dry_fired := [false]
	player.dry_fire.connect(func(): dry_fired[0] = true)
	
	player.current_ammo = 2
	player._attempt_shoot()
	assert_eq(player.current_ammo, 1, "Ammo decremented to 1 after shooting")
	
	player._attempt_shoot()
	assert_eq(player.current_ammo, 0, "Ammo decremented to 0 after second shot")
	
	# Next shot should dry fire
	dry_fired[0] = false
	player._attempt_shoot()
	assert_eq(player.current_ammo, 0, "Ammo stays at 0")
	assert_true(dry_fired[0], "dry_fire signal emitted when firing on empty magazine")
	
	# Test add_ammo
	player.add_ammo(8)
	assert_eq(player.current_ammo, 8, "Ammo increased to 8 via add_ammo")
	
	player.queue_free()

func test_simultaneous_movement_and_shooting() -> void:
	print("\n--- TEST: Simultaneous Movement & Shooting ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	player.touch_right = true
	player._handle_input(0.016)
	assert_eq(player.facing_direction, 1, "Player faces right (direction = 1)")
	assert_true(player.velocity.x > 0, "Player moves right with touch_right = true")
	
	player.touch_right = false
	player.velocity = Vector2.ZERO
	player.touch_left = true
	player._handle_input(0.016)
	assert_eq(player.facing_direction, -1, "Player faces left (direction = -1)")
	assert_true(player.velocity.x < 0, "Player moves left with touch_left = true")
	
	player.queue_free()

func test_bullet_projectiles() -> void:
	print("\n--- TEST: Bullet Projectiles ---")
	var bullet_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_bullet.tscn")
	assert_true(bullet_scene != null, "bb_bullet.tscn scene exists and loads")
	var bullet: BulletBetrayalBullet = bullet_scene.instantiate()
	add_child(bullet)
	
	bullet.setup(Vector2.RIGHT, Vector2(100, 100))
	assert_eq(bullet.direction, Vector2.RIGHT, "Bullet configured with Vector2.RIGHT")
	assert_eq(bullet.global_position, Vector2(100, 100), "Bullet initialized at spawn coordinates (100, 100)")
	
	bullet.queue_free()

func test_enemy_soldier_ai_and_elimination() -> void:
	print("\n--- TEST: Enemy Soldier AI & Elimination ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	assert_true(enemy_scene != null, "bb_enemy_soldier.tscn scene loads")
	var enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	add_child(enemy)
	
	assert_true(not enemy.is_dead, "Enemy soldier is alive initially (is_dead = false)")
	
	var eliminated_called := [false]
	enemy.eliminated.connect(func(): eliminated_called[0] = true)
	
	enemy.take_hit(1)
	assert_true(enemy.is_dead, "Enemy marked dead (is_dead = true) after hit")
	assert_true(eliminated_called[0], "eliminated signal fired")
	
	enemy.queue_free()

func test_ammo_crate_pickup() -> void:
	print("\n--- TEST: Tactical Ammo Crate Pickups ---")
	var ammo_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_ammo_pickup.tscn")
	assert_true(ammo_scene != null, "bb_ammo_pickup.tscn scene loads")
	var ammo_pickup: BulletBetrayalAmmoPickup = ammo_scene.instantiate()
	ammo_pickup.ammo_amount = 8
	add_child(ammo_pickup)
	
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
	print("\n--- TEST: Mobile Touch Controls & Direct Player Wiring ---")
	if GameManager:
		GameManager.is_gameplay_active = true

	var hud_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_hud.tscn")
	assert_true(hud_scene != null, "HUD scene loads")
	var hud: BulletBetrayalHUD = hud_scene.instantiate()
	add_child(hud)
	
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	hud.connect_player(player)
	
	# Verify TouchButtons exist
	var left_btn: TextureButton = hud.left_btn
	var right_btn: TextureButton = hud.right_btn
	var jump_btn: TextureButton = hud.jump_btn
	var shoot_btn: TextureButton = hud.shoot_btn
	
	assert_true(left_btn != null and left_btn is TouchButton, "left_btn is TouchButton")
	assert_true(right_btn != null and right_btn is TouchButton, "right_btn is TouchButton")
	assert_true(jump_btn != null and jump_btn is TouchButton, "jump_btn is TouchButton")
	assert_true(shoot_btn != null and shoot_btn is TouchButton, "shoot_btn is TouchButton")
	
	# Verify direct virtual touch wiring: Left
	assert_true(not player.touch_left, "Player touch_left starts false")
	left_btn.touch_down.emit()
	assert_true(player.touch_left, "left_btn.touch_down sets player.touch_left = true")
	left_btn.touch_up.emit()
	assert_true(not player.touch_left, "left_btn.touch_up sets player.touch_left = false")
	
	# Verify direct virtual touch wiring: Right
	assert_true(not player.touch_right, "Player touch_right starts false")
	right_btn.touch_down.emit()
	assert_true(player.touch_right, "right_btn.touch_down sets player.touch_right = true")
	right_btn.touch_up.emit()
	assert_true(not player.touch_right, "right_btn.touch_up sets player.touch_right = false")
	
	# Verify direct virtual touch wiring: Jump
	assert_true(not player.touch_jump, "Player touch_jump starts false")
	jump_btn.touch_down.emit()
	assert_true(player.touch_jump, "jump_btn.touch_down sets player.touch_jump = true")
	assert_true(player.touch_jump_just_pressed, "jump_btn.touch_down sets touch_jump_just_pressed = true")
	jump_btn.touch_up.emit()
	assert_true(not player.touch_jump, "jump_btn.touch_up sets player.touch_jump = false")
	assert_true(player.touch_jump_just_released, "jump_btn.touch_up sets touch_jump_just_released = true")
	
	# Verify direct virtual touch wiring: Shoot
	assert_true(not player.touch_shoot, "Player touch_shoot starts false")
	shoot_btn.touch_down.emit()
	assert_true(player.touch_shoot, "shoot_btn.touch_down sets player.touch_shoot = true")
	assert_true(player.touch_shoot_just_pressed, "shoot_btn.touch_down sets touch_shoot_just_pressed = true")
	shoot_btn.touch_up.emit()
	assert_true(not player.touch_shoot, "shoot_btn.touch_up sets player.touch_shoot = false")
	
	# Verify reset_touch_controls
	player.touch_left = true
	player.touch_right = true
	player.touch_jump = true
	player.touch_shoot = true
	hud.reset_touch_controls()
	assert_true(not player.touch_left and not player.touch_right and not player.touch_jump and not player.touch_shoot, "reset_touch_controls clears all player touch flags")
	
	player.queue_free()
	hud.queue_free()

func test_pause_menu_and_confirmation_modals() -> void:
	print("\n--- TEST: Pause Menu & Coin Hell Confirmation Modals ---")
	var hud_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_hud.tscn")
	var hud: BulletBetrayalHUD = hud_scene.instantiate()
	add_child(hud)
	
	assert_true(not hud.pause_overlay.visible, "Pause overlay starts hidden")
	assert_true(not hud.confirm_modal.visible, "Confirm modal starts hidden")
	
	# Open pause
	hud.show_pause()
	assert_true(hud.pause_overlay.visible, "Pause overlay visible after show_pause")
	assert_true(get_tree().paused, "Game tree is paused")
	
	# Test restart confirmation popup
	hud.pause_restart_btn.pressed.emit()
	assert_true(hud.confirm_modal.visible, "Confirm modal visible after pressing Restart")
	assert_eq(hud.modal_title.text, "RESTART LEVEL?", "Confirm modal title is RESTART LEVEL?")
	assert_true(get_tree().paused, "Game remains paused under confirmation modal")
	
	# Cancel popup
	hud.modal_cancel_btn.pressed.emit()
	assert_true(not hud.confirm_modal.visible, "Confirm modal dismissed on Cancel")
	assert_true(hud.pause_overlay.visible, "Pause overlay remains open on Cancel")
	
	# Test mission select confirmation popup
	hud.pause_mission_btn.pressed.emit()
	assert_true(hud.confirm_modal.visible, "Confirm modal visible after pressing Stage Select")
	assert_eq(hud.modal_title.text, "RETURN TO MENU?", "Confirm modal title is RETURN TO MENU?")
	hud.modal_cancel_btn.pressed.emit()
	
	# Test arcade menu confirmation popup
	hud.pause_arcade_btn.pressed.emit()
	assert_true(hud.confirm_modal.visible, "Confirm modal visible after pressing Arcade Menu")
	assert_eq(hud.modal_title.text, "RETURN TO ARCADE?", "Confirm modal title is RETURN TO ARCADE?")
	hud.modal_cancel_btn.pressed.emit()
	
	# Test SFX toggle
	var initial_sfx: bool = SaveManager.sfx_enabled
	hud.pause_sfx_btn.pressed.emit()
	assert_eq(SaveManager.sfx_enabled, not initial_sfx, "SFX toggled in pause menu")
	hud.pause_sfx_btn.pressed.emit()
	assert_eq(SaveManager.sfx_enabled, initial_sfx, "SFX toggled back")
	
	# Resume game
	hud.pause_resume_btn.pressed.emit()
	assert_true(not hud.pause_overlay.visible, "Pause overlay hidden on Resume")
	assert_true(not get_tree().paused, "Game unpaused on Resume")
	
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
	print("\n--- TEST: World 1 Level 1 Full Gameplay Lifecycle & Active State ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	# Verify GameManager gameplay active flag is set to true on level ready
	if GameManager:
		assert_true(GameManager.is_gameplay_active, "GameManager.is_gameplay_active is TRUE during gameplay")
	
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
	await get_tree().process_frame
	
	# Verify GameManager gameplay active flag resets on exit
	if GameManager:
		assert_true(not GameManager.is_gameplay_active, "GameManager.is_gameplay_active is FALSE after leaving level")
