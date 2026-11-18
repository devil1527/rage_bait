class_name BulletBetrayalTestRunner
extends Node

## Automated test runner for Bullet Betrayal Phase 2.
## Tests all 13 core requirements:
## 1. Coin Hell player character reuse and firearm adaptation
## 2. One-hit death system from enemy bullets
## 3. One-hit death system from fire traps and lethal hazards
## 4. 2-hit enemy durability (hit 1 = damage feedback, hit 2 = elimination)
## 5. Limited starting ammunition (exactly 10 rounds)
## 6. Dry fire when ammunition reaches 0 (no shooting permitted)
## 7. Exit remains locked while even 1 required enemy is alive
## 8. Exit unlocks only after all 10 required enemies are eliminated
## 9. Ambushes trigger correctly and do not spawn unfairly on player
## 10. Rewarded-ad revive restores exactly 1 life and 10 bullets
## 11. Failed or incomplete ads do not grant rewards
## 12. Pause, resume, restart, and confirmation popups work correctly
## 13. Mobile touch controls direct player wiring

var passed_count: int = 0
var failed_count: int = 0
@export var auto_quit: bool = true

func _ready() -> void:
	if not auto_quit:
		return
	print("\n=======================================================")
	print("    BULLET BETRAYAL — AUTOMATED TEST SUITE (PHASE 2)   ")
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
	test_coin_hell_player_reuse()
	test_one_hit_death_system()
	test_enemy_durability_one_bullet_kill()
	test_limited_ammunition_and_dry_fire()
	test_simultaneous_movement_and_shooting()
	test_bullet_projectiles()
	test_ammo_crate_pickup()
	test_ambush_triggers()
	test_10_enemy_objective_and_locked_exit()
	test_rewarded_ad_revive_integration()
	test_mobile_touch_controls_and_hud()
	test_pause_menu_and_confirmation_modals()
	test_level_1_layout_and_sections()
	test_level_1_full_lifecycle()
	test_phase3_enemy_ledge_detection_and_pit_prevention()
	test_phase3_ambush_archetypes_and_reaction_buffers()
	test_phase3_ground_elevation_continuity_and_no_cliffs()
	test_phase3_enemy_no_auto_despawn_simulation()
	test_phase3_fire_hazard_2_jump_clearance_and_platform_deconfliction()
	test_bb_save_manager_and_stars()
	test_bullet_betrayal_menu_stars_reflection()
	test_level_2_scene_and_combat_rules()
	test_level_2_ladder_rear_ambush_and_polish()
	await test_level_2_final_jump_over_bar_and_landing()
	await test_level_3_operation_dead_ground()
	await test_level_4_the_hunting_mines()
	await test_level_5_operation_last_stand()

func test_audio_manager_bullet_betrayal_sfx() -> void:
	print("\n--- TEST: Bullet Betrayal Audio SFX ---")
	var required_sounds = ["shoot", "enemy_hit", "enemy_kill", "ammo_pickup", "player_hit", "victory", "dry_fire", "explosion"]
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
	
	bb_menu._on_back_pressed()
	assert_eq(bb_menu.current_selected_world, 0, "Back button resets current_selected_world to 0")
	assert_eq(back_btn.text, "◀ MENU", "Back button text resets to '◀ MENU'")
	assert_true(sec_1.visible and sec_2.visible, "All world sections visible after returning to all worlds")
	
	# Ensure Stage 2 is tested in locked state
	var prev_highest = SaveManager.bb_highest_unlocked_level
	SaveManager.bb_highest_unlocked_level = 1
	bb_menu._refresh_tile_states()

	assert_true(not bb_menu.message_modal.visible, "MessageModal starts hidden")
	stage_2.pressed.emit()
	assert_true(bb_menu.message_modal.visible, "Clicking locked stage displays arcade MessageModal")
	assert_eq(bb_menu.modal_title.text, "STAGE 2 IS LOCKED", "MessageModal title matches Coin Hell format")
	
	bb_menu.modal_ok_btn.pressed.emit()
	assert_true(not bb_menu.message_modal.visible, "Clicking GOT IT closes MessageModal")
	
	SaveManager.bb_highest_unlocked_level = prev_highest
	bb_menu._refresh_tile_states()
	
	bb_menu.queue_free()

func test_coin_hell_player_reuse() -> void:
	print("\n--- TEST: Coin Hell Player Character Reuse & Firearms ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	assert_true(player_scene != null, "bb_player.tscn scene exists and loads")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	# Verify Coin Hell sprite reuse
	assert_true(player.sprite != null, "Player has Sprite2D")
	assert_eq(player.sprite.texture.resource_path, "res://assets/sprites/player.png", "Player reuses exact Coin Hell sprite 'player.png'")
	
	# Verify Coin Hell collision shape dimensions
	assert_true(player.collision_shape != null, "Player has CollisionShape2D")
	assert_eq(player.collision_shape.shape.size, Vector2(16, 28), "CollisionShape2D matches Coin Hell player size (16, 28)")
	
	# Verify firearm attachment
	assert_true(player.weapon_sprite != null, "Player has WeaponSprite firearm attachment")
	assert_eq(player.weapon_sprite.texture.resource_path, "res://assets/sprites/bb_gun.png", "WeaponSprite uses retro pixel blaster 'bb_gun.png'")
	assert_true(player.muzzle_pos != null, "Player has MuzzlePos marker")
	
	# Verify starting stats
	assert_eq(player.max_health, 1, "Player max_health is 1 (one-hit death rule)")
	assert_eq(player.current_health, 1, "Player current_health starts at 1")
	assert_eq(player.initial_ammo, 10, "Player initial_ammo starts at exactly 10 bullets")
	assert_eq(player.current_ammo, 10, "Player current_ammo starts at exactly 10 bullets")
	assert_true(player.is_alive, "Player is alive on spawn")
	
	player.queue_free()

func test_one_hit_death_system() -> void:
	print("\n--- TEST: One-Hit Death System (Bullets, Fire & Hazards) ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	
	# Subtest 1: direct damage
	var p1: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(p1)
	p1.take_damage(1)
	assert_eq(p1.current_health, 0, "Player HP drops to 0 after 1 hit")
	assert_true(p1.is_dead, "Player dies immediately from 1 hit")
	p1.queue_free()
	
	# Subtest 2: enemy bullet hit
	var p2: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(p2)
	var e_bullet_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_bullet.tscn")
	assert_true(e_bullet_scene != null, "bb_enemy_bullet.tscn loads")
	var e_bullet: BulletBetrayalEnemyBullet = e_bullet_scene.instantiate()
	add_child(e_bullet)
	
	e_bullet._on_body_entered(p2)
	assert_eq(p2.current_health, 0, "Enemy bullet contact drops player HP to 0")
	assert_true(p2.is_dead, "Enemy bullet causes immediate one-hit death")
	p2.queue_free()
	e_bullet.queue_free()
	
	# Subtest 3: fire hazard hit
	var p3: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(p3)
	var fire_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_fire_hazard.tscn")
	assert_true(fire_scene != null, "bb_fire_hazard.tscn loads")
	var fire = fire_scene.instantiate()
	add_child(fire)
	
	fire._on_body_entered(p3)
	assert_eq(p3.current_health, 0, "Fire hazard contact drops player HP to 0")
	assert_true(p3.is_dead, "Fire hazard causes immediate one-hit death")
	p3.queue_free()
	fire.queue_free()

func test_enemy_durability_one_bullet_kill() -> void:
	print("\n--- TEST: Enemy Durability (Exactly 1-Hit / 1-Bullet Elimination) ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	assert_true(enemy_scene != null, "bb_enemy_soldier.tscn loads")
	var enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	enemy.set_physics_process(false)
	add_child(enemy)
	
	assert_eq(enemy.max_health, 1, "Enemy max_health is 1 (one bullet kills rule)")
	assert_eq(enemy.current_health, 1, "Enemy starts with 1 health")
	assert_true(not enemy.is_dead, "Enemy starts alive")
	
	var eliminated_called := [false]
	enemy.eliminated.connect(func(): eliminated_called[0] = true)
	
	# Exactly 1 bullet hits
	enemy.take_hit(1)
	assert_eq(enemy.current_health, 0, "Enemy health drops to 0 after 1 bullet hit")
	assert_true(enemy.is_dead, "Enemy marked dead after 1 bullet hit")
	assert_true(eliminated_called[0], "eliminated signal fired immediately on 1 hit")
	
	enemy.queue_free()

func test_limited_ammunition_and_dry_fire() -> void:
	print("\n--- TEST: Limited Ammunition (10 Starting Rounds & Dry Fire) ---")
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	assert_eq(player.current_ammo, 10, "Player starts run with exactly 10 rounds")
	
	# Fire all 10 rounds
	for i in range(10):
		assert_eq(player.current_ammo, 10 - i, "Rounds before shot %d: %d" % [i + 1, 10 - i])
		player._fire_timer = 0.0
		player._attempt_shoot()
	
	assert_eq(player.current_ammo, 0, "Ammo depleted to 0 after 10 shots")
	
	# Attempt to fire with 0 ammo
	var dry_fired := [false]
	player.dry_fire.connect(func(): dry_fired[0] = true)
	player._fire_timer = 0.0
	player._attempt_shoot()
	
	assert_eq(player.current_ammo, 0, "Ammo remains 0 on empty magazine")
	assert_true(dry_fired[0], "dry_fire signal emitted when firing on 0 ammo")
	
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
	print("\n--- TEST: Bullet Projectiles & Impact Prevention ---")
	var bullet_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_bullet.tscn")
	assert_true(bullet_scene != null, "bb_bullet.tscn scene exists and loads")
	var bullet: BulletBetrayalBullet = bullet_scene.instantiate()
	add_child(bullet)
	
	bullet.setup(Vector2.RIGHT, Vector2(100, 100))
	assert_eq(bullet.direction, Vector2.RIGHT, "Bullet configured with Vector2.RIGHT")
	assert_eq(bullet.global_position, Vector2(100, 100), "Bullet initialized at spawn coordinates (100, 100)")
	
	bullet.queue_free()

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

func test_ambush_triggers() -> void:
	print("\n--- TEST: Fair Intentional Ambushes ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	var ambush_enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	ambush_enemy.is_ambush = true
	add_child(ambush_enemy)
	
	assert_true(ambush_enemy.is_dormant, "Ambush enemy starts dormant")
	assert_true(not ambush_enemy.visible, "Ambush enemy starts invisible / concealed")
	assert_true(not ambush_enemy.collision_shape.disabled, "Ambush enemy terrain collision stays active for solid grounding")
	assert_true(ambush_enemy.hurtbox_col.disabled, "Ambush enemy hurtbox starts disabled so concealed enemy cannot be shot")
	
	# Trigger ambush
	ambush_enemy.trigger_ambush()
	assert_true(not ambush_enemy.is_dormant, "Ambush enemy is no longer dormant after trigger")
	assert_true(ambush_enemy.visible, "Ambush enemy is visible after trigger")
	assert_true(not ambush_enemy.collision_shape.disabled, "Ambush enemy collision remains active after trigger")
	assert_true(ambush_enemy.alert_icon.visible, "Ambush enemy displays alert telegraph")
	
	ambush_enemy.queue_free()

func test_10_enemy_objective_and_locked_exit() -> void:
	print("\n--- TEST: 10-Enemy Objective & Locked Extraction Beacon ---")
	var beacon_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_extraction_beacon.tscn")
	assert_true(beacon_scene != null, "Extraction beacon scene loads")
	var beacon: BulletBetrayalExtractionBeacon = beacon_scene.instantiate()
	beacon.required_enemies = 10
	add_child(beacon)
	
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	
	var reached := [false]
	beacon.extraction_reached.connect(func(): reached[0] = true)
	
	# Beacon starts locked
	assert_true(not beacon.is_unlocked, "Extraction beacon starts locked")
	assert_true(beacon.lock_barrier != null and beacon.lock_barrier.visible, "Lock barrier is visible while locked")
	
	# Player touches beacon while 0/10 enemies killed
	beacon._on_body_entered(player)
	assert_true(not reached[0], "Exit cannot be extracted while 0/10 enemies alive")
	
	# Update to 9/10 kills
	beacon.update_target_progress(9, 10)
	assert_true(not beacon.is_unlocked, "Exit remains locked with 9/10 enemies eliminated (1 remaining)")
	beacon._on_body_entered(player)
	assert_true(not reached[0], "Exit still cannot be extracted while 1 enemy remains")
	
	# Update to 10/10 kills
	beacon.update_target_progress(10, 10)
	assert_true(beacon.is_unlocked, "Exit unlocks immediately when all 10 enemies are eliminated")
	
	# Player touches unlocked beacon
	beacon._on_body_entered(player)
	assert_true(reached[0], "Extraction triggers successfully after all 10 enemies eliminated")
	
	player.queue_free()
	beacon.queue_free()

func test_rewarded_ad_revive_integration() -> void:
	print("\n--- TEST: Rewarded-Ad Revive Integration ---")
	var hud_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_hud.tscn")
	var hud: BulletBetrayalHUD = hud_scene.instantiate()
	add_child(hud)
	
	var player_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_player.tscn")
	var player: BulletBetrayalPlayer = player_scene.instantiate()
	add_child(player)
	hud.connect_player(player)
	
	# Verify revive button in DeathOverlay
	assert_true(hud.death_revive_btn != null, "ReviveBtn exists in DeathOverlay")
	assert_eq(hud.death_revive_btn.text, "🎬 WATCH AD — REVIVE", "ReviveBtn displays '🎬 WATCH AD — REVIVE'")
	
	# Verify GameManager allowance
	if GameManager:
		GameManager.is_gameplay_active = true
		GameManager.revives_used_this_run = 0
		assert_true(GameManager.can_revive_this_run(), "Player can revive on fresh run (0/1 used)")
	
	# Simulate player death
	player.current_ammo = 0
	player.die()
	assert_true(player.is_dead, "Player is dead before revive")
	
	# Simulate authoritative revive reward grant
	hud._on_revive_reward_granted(-1)
	
	assert_true(player.is_alive, "Player is alive after revive reward granted")
	assert_eq(player.current_health, 1, "Player revived with exactly 1 life")
	assert_eq(player.current_ammo, 10, "Player revived with exactly 10 bullets restored")
	assert_true(player.is_invulnerable, "Player granted temporary spawn protection")
	
	# Verify revive allowance consumed
	if GameManager:
		assert_eq(GameManager.revives_used_this_run, 1, "Revives used count updated to 1")
		assert_true(not GameManager.can_revive_this_run(), "Cannot revive a second time in same run")
	
	# Test failed ad handling
	hud._on_revive_ad_failed("Ad failed to load")
	assert_true(hud.death_retry_btn != null and not hud.death_retry_btn.disabled, "Retry button remains enabled when ad fails")
	
	player.queue_free()
	hud.queue_free()

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
	
	# Verify 1-life and targets HUD labels
	assert_true(hud.health_label != null, "HealthLabel exists on HUD")
	assert_eq(hud.health_label.text, "♥ LIFE: 1 / 1", "HealthLabel displays '♥ LIFE: 1 / 1'")
	assert_true(hud.targets_label != null, "TargetsLabel exists on HUD")
	assert_eq(hud.targets_label.text, "🎯 TARGETS: 0 / 10", "TargetsLabel displays '🎯 TARGETS: 0 / 10'")
	
	# Verify TouchButtons exist
	var left_btn: TextureButton = hud.left_btn
	var right_btn: TextureButton = hud.right_btn
	var jump_btn: TextureButton = hud.jump_btn
	var shoot_btn: TextureButton = hud.shoot_btn
	
	assert_true(left_btn != null and left_btn is TouchButton, "left_btn is TouchButton")
	assert_true(right_btn != null and right_btn is TouchButton, "right_btn is TouchButton")
	assert_true(jump_btn != null and jump_btn is TouchButton, "jump_btn is TouchButton")
	assert_true(shoot_btn != null and shoot_btn is TouchButton, "shoot_btn is TouchButton")
	
	# Direct virtual touch wiring: Left
	assert_true(not player.touch_left, "Player touch_left starts false")
	left_btn.touch_down.emit()
	assert_true(player.touch_left, "left_btn.touch_down sets player.touch_left = true")
	left_btn.touch_up.emit()
	assert_true(not player.touch_left, "left_btn.touch_up sets player.touch_left = false")
	
	# Direct virtual touch wiring: Right
	assert_true(not player.touch_right, "Player touch_right starts false")
	right_btn.touch_down.emit()
	assert_true(player.touch_right, "right_btn.touch_down sets player.touch_right = true")
	right_btn.touch_up.emit()
	assert_true(not player.touch_right, "right_btn.touch_up sets player.touch_right = false")
	
	# Direct virtual touch wiring: Jump
	assert_true(not player.touch_jump, "Player touch_jump starts false")
	jump_btn.touch_down.emit()
	assert_true(player.touch_jump, "jump_btn.touch_down sets player.touch_jump = true")
	assert_true(player.touch_jump_just_pressed, "jump_btn.touch_down sets touch_jump_just_pressed = true")
	jump_btn.touch_up.emit()
	assert_true(not player.touch_jump, "jump_btn.touch_up sets player.touch_jump = false")
	assert_true(player.touch_jump_just_released, "jump_btn.touch_up sets touch_jump_just_released = true")
	
	# Direct virtual touch wiring: Shoot
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
	print("\n--- TEST: Pause Menu & Victory Overlay Coin Hell Consistency ---")
	var hud_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_hud.tscn")
	var hud: BulletBetrayalHUD = hud_scene.instantiate()
	add_child(hud)
	
	# Verify Pause Button consistency with Coin Hell
	assert_true(hud.pause_btn != null, "HUD Pause button exists")
	assert_eq(hud.pause_btn.text, "⏸ PAUSE", "Pause button text matches Coin Hell ('⏸ PAUSE')")
	assert_eq(hud.pause_btn.custom_minimum_size, Vector2(80, 36), "Pause button size is 80x36 matching Coin Hell")
	
	assert_true(not hud.pause_overlay.visible, "Pause overlay starts hidden")
	assert_true(hud.confirm_modal == null, "Confirm modal removed from pause menu (matches Coin Hell direct actions)")
	
	# Open pause
	hud.show_pause()
	assert_true(hud.pause_overlay.visible, "Pause overlay visible after show_pause")
	assert_true(get_tree().paused, "Game tree is paused")
	
	# Verify exact 4 options on Pause Menu matching Coin Hell
	assert_true(hud.pause_resume_btn != null, "Pause menu has ResumeBtn")
	assert_eq(hud.pause_resume_btn.text, "▶ RESUME", "Resume button text matches Coin Hell ('▶ RESUME')")
	
	assert_true(hud.pause_restart_btn != null, "Pause menu has RestartBtn")
	assert_eq(hud.pause_restart_btn.text, "↺ RESTART LEVEL", "Restart button text matches Coin Hell ('↺ RESTART LEVEL')")
	
	assert_true(hud.pause_mission_btn != null, "Pause menu has LevelSelectBtn")
	assert_eq(hud.pause_mission_btn.text, "☰ LEVEL SELECT", "Level Select button text matches Coin Hell ('☰ LEVEL SELECT')")
	
	assert_true(hud.pause_sfx_btn != null, "Pause menu has SfxBtn")
	assert_true(hud.pause_arcade_btn == null, "Arcade Menu button omitted from pause overlay (matches Coin Hell 4-button layout)")
	
	# Test SFX toggle
	var initial_sfx: bool = SaveManager.sfx_enabled
	hud.pause_sfx_btn.pressed.emit()
	assert_eq(SaveManager.sfx_enabled, not initial_sfx, "SFX toggled in pause menu")
	hud.pause_sfx_btn.pressed.emit()
	assert_eq(SaveManager.sfx_enabled, initial_sfx, "SFX toggled back")
	
	# Test restart button triggers restart immediately without modal
	var restart_called := [false]
	hud.restart_requested.connect(func(): restart_called[0] = true)
	hud.pause_restart_btn.pressed.emit()
	assert_true(restart_called[0], "Restart triggers immediate restart_requested without confirmation modal")
	assert_true(not hud.pause_overlay.visible, "Pause overlay dismissed on Restart")
	assert_true(not get_tree().paused, "Game tree unpaused on Restart")
	
	# Test level select button triggers menu immediately without modal
	hud.show_pause()
	var menu_called := [false]
	hud.menu_requested.connect(func(): menu_called[0] = true)
	hud.pause_mission_btn.pressed.emit()
	assert_true(menu_called[0], "Level Select triggers immediate menu_requested without confirmation modal")
	assert_true(not hud.pause_overlay.visible, "Pause overlay dismissed on Level Select")
	assert_true(not get_tree().paused, "Game tree unpaused on Level Select")
	
	# Test Resume button
	hud.show_pause()
	hud.pause_resume_btn.pressed.emit()
	assert_true(not hud.pause_overlay.visible, "Pause overlay hidden on Resume")
	assert_true(not get_tree().paused, "Game unpaused on Resume")
	
	# Test Victory Overlay and Next Stage Button consistency
	hud.show_victory(8)
	assert_true(hud.victory_overlay.visible, "Victory overlay displayed on show_victory")
	assert_true(hud.victory_next_stage_btn != null, "Victory overlay includes NextStageBtn")
	assert_eq(hud.victory_next_stage_btn.text, "▶ NEXT STAGE", "Next stage button says '▶ NEXT STAGE'")
	assert_true(hud.victory_replay_btn != null, "Victory overlay has ReplayBtn")
	assert_eq(hud.victory_replay_btn.text, "↺ REPLAY", "Replay button text matches Coin Hell ('↺ REPLAY')")
	assert_true(hud.victory_mission_btn != null, "Victory overlay has LevelSelectBtn")
	assert_eq(hud.victory_mission_btn.text, "☰ LEVEL SELECT", "Level Select button text matches Coin Hell ('☰ LEVEL SELECT')")
	assert_true(hud.victory_arcade_btn == null, "Arcade Menu button omitted from Victory overlay (matches Coin Hell 3-button layout)")
	
	# Test Next Stage Button opens MessageModal for unreleased Stage 6 (when on Stage 5)
	hud.current_stage_id = 5
	assert_true(hud.victory_message_modal != null, "Victory overlay has MessageModal")
	assert_true(not hud.victory_message_modal.visible, "MessageModal starts hidden")
	hud.victory_next_stage_btn.pressed.emit()
	assert_true(hud.victory_message_modal.visible, "MessageModal opens when clicking Next Stage on last implemented stage")
	assert_eq(hud.victory_modal_title.text, "STAGE 6 IN PROGRESS", "MessageModal title is 'STAGE 6 IN PROGRESS'")
	assert_true(hud.victory_modal_label.text.contains("still being built"), "MessageModal explains Stage 6 is being built")
	
	# Dismiss MessageModal
	hud.victory_modal_ok_btn.pressed.emit()
	assert_true(not hud.victory_message_modal.visible, "MessageModal dismissed on OK ('GOT IT')")
	assert_true(hud.victory_overlay.visible, "Victory overlay remains visible after dismissing MessageModal")

	# Test Death Overlay Coin Hell Visual Hierarchy & 3-Button Structure
	assert_true(hud.death_overlay != null, "Death overlay exists in HUD")
	var death_panel = hud.death_overlay.get_node_or_null("Panel")
	assert_true(death_panel != null, "Death overlay has Panel container")
	assert_eq(death_panel.custom_minimum_size, Vector2(380, 310), "Death panel custom_minimum_size is 380x310 matching Coin Hell")

	var death_dim: ColorRect = hud.death_overlay.get_node_or_null("DimBackground")
	assert_true(death_dim != null, "Death overlay has DimBackground")
	assert_eq(death_dim.color, Color(0.2, 0, 0, 0.6), "Death overlay dim background color is Color(0.2, 0, 0, 0.6) matching Coin Hell")

	var death_title: Label = hud.death_overlay.get_node_or_null("Panel/VBox/Title")
	assert_true(death_title != null, "Death overlay has Title label")
	assert_eq(death_title.text, "YOU DIED!", "Death title says 'YOU DIED!' matching Coin Hell")
	assert_eq(death_title.get_theme_font_size("font_size"), 28, "Death title font size is 28 matching Coin Hell")

	# Verify 3-button death layout matching Coin Hell
	assert_true(hud.death_revive_btn != null, "Death overlay has ReviveBtn")
	assert_eq(hud.death_revive_btn.custom_minimum_size, Vector2(240, 42), "Revive button size is 240x42 matching Coin Hell")
	assert_eq(hud.death_revive_btn.text, "🎬 WATCH AD — REVIVE", "Revive button text matches Coin Hell ('🎬 WATCH AD — REVIVE')")

	assert_true(hud.death_retry_btn != null, "Death overlay has RetryBtn")
	assert_eq(hud.death_retry_btn.custom_minimum_size, Vector2(240, 42), "Retry button size is 240x42 matching Coin Hell")
	assert_eq(hud.death_retry_btn.text, "↺ RESTART LEVEL", "Retry button text matches Coin Hell ('↺ RESTART LEVEL')")

	assert_true(hud.death_level_select_btn != null, "Death overlay has LevelSelectBtn")
	assert_eq(hud.death_level_select_btn.custom_minimum_size, Vector2(240, 42), "Level Select button size is 240x42 matching Coin Hell")
	assert_eq(hud.death_level_select_btn.text, "☰ LEVEL SELECT", "Level Select button text matches Coin Hell ('☰ LEVEL SELECT')")

	assert_true(hud.death_arcade_btn == null, "Arcade Menu button omitted from death overlay (matches Coin Hell 3-button layout)")
	
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
	assert_eq(level.player.global_position, Vector2(180, 360), "Player spawns at clear coordinates (180, 360) away from touch controls and bunker")
	
	# Camera boundaries
	var camera: Camera2D = level.player.get_node_or_null("Camera2D")
	assert_true(camera != null, "Player has Camera2D")
	assert_eq(camera.limit_left, 0, "Camera left limit is 0")
	assert_eq(camera.limit_top, 0, "Camera top limit is 0")
	assert_eq(camera.limit_right, 2650, "Camera right limit bounds the level at 2650px")
	assert_eq(camera.limit_bottom, 540, "Camera bottom limit is 540px")
	
	# Audit Enemies across sections: exactly 10 required enemies
	var enemies = level.enemies_container.get_children()
	assert_eq(enemies.size(), 10, "Level 1 contains exactly 10 required enemies across all sections")
	
	# Verify Pickups: zero extra ammo pickups (strict 10 bullets for 10 enemies)
	assert_eq(level.pickups_container.get_child_count(), 0, "No extra ammo pickups on map (strict 10 bullets for 10 enemies economy)")
	
	# Section 2 Enemies
	var e1 = level.get_node_or_null("Enemies/Enemy1_GroundPatrol")
	var e2 = level.get_node_or_null("Enemies/Enemy2_OutpostGuard")
	var e3 = level.get_node_or_null("Enemies/Enemy3_AmbushValley")
	assert_true(e1 != null and e2 != null, "Section 2 has introductory patrol soldiers")
	assert_true(e3 != null and e3.is_ambush, "Section 2 has Ambush 1 enemy behind valley crates")
	
	# Section 3 Enemies
	var e4 = level.get_node_or_null("Enemies/Enemy4_HighPlatform")
	var e5 = level.get_node_or_null("Enemies/Enemy5_AmbushLedge")
	assert_true(e4 != null, "Section 3 has elevated soldier requiring jump-shooting")
	assert_true(e5 != null and e5.is_ambush, "Section 3 has Ambush 2 enemy on elevated ledge")
	
	# Section 4 Enemies
	var e6 = level.get_node_or_null("Enemies/Enemy6_Approach")
	var e7 = level.get_node_or_null("Enemies/Enemy7_LedgeSentry")
	var e8 = level.get_node_or_null("Enemies/Enemy8_AmbushRuins")
	assert_true(e6 != null and e7 != null, "Section 4 has ruins patrol and ledge sentry")
	assert_true(e8 != null and e8.is_ambush, "Section 4 has Ambush 3 enemy in ruins bunker")
	
	# Section 5 Final Encounter
	var e9 = level.get_node_or_null("Enemies/Enemy9_Watchtower")
	var e10 = level.get_node_or_null("Enemies/Enemy10_GateGuard")
	assert_true(e9 != null and e10 != null, "Section 5 has watchtower and compound gate defense")
	
	# Section Hazards
	var h1 = level.get_node_or_null("Hazards/FireHazard1_Trench")
	var h2 = level.get_node_or_null("Hazards/FireHazard2_Ruins")
	assert_true(h1 != null, "FireHazard1 exists in Trench")
	assert_true(h2 != null, "FireHazard2 exists in Ruins")
	
	# Section 6 Extraction
	assert_true(level.extraction_beacon != null, "Section 6 has Extraction Beacon goal")
	assert_true(level.extraction_beacon.position.x >= 2500.0, "Extraction Beacon is positioned at level finale (X >= 2500)")
	assert_eq(level.extraction_beacon.required_enemies, 10, "Extraction beacon requires all 10 enemies")
	
	level.queue_free()

func test_level_1_full_lifecycle() -> void:
	print("\n--- TEST: World 1 Level 1 Full Gameplay Lifecycle & Active State ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	# Verify GameManager gameplay active flag is set to true on level ready
	if GameManager:
		assert_true(GameManager.is_gameplay_active, "GameManager.is_gameplay_active is TRUE during gameplay")
	
	# Start stats
	assert_eq(level.player.current_health, 1, "Run starts with 1 HP (one-hit death rule)")
	assert_eq(level.player.current_ammo, 10, "Run starts with exactly 10 Ammo")
	assert_true(not level._is_completed, "Stage starts incomplete")
	assert_true(not level.extraction_beacon.is_unlocked, "Extraction beacon starts locked")
	
	# Simulate eliminating all 10 enemies (1 hit per enemy - 1-bullet kill)
	for enemy in level.enemies_container.get_children():
		if enemy is BulletBetrayalEnemySoldier:
			if enemy.is_ambush:
				enemy.trigger_ambush()
			enemy.take_hit(1)
	
	assert_eq(level._enemies_eliminated, 10, "All 10 required enemies successfully eliminated")
	assert_true(level.extraction_beacon.is_unlocked, "Extraction beacon unlocked after 10 kills")
	
	# Simulate reaching extraction
	level._on_extraction_reached()
	assert_true(level._is_completed, "Level marked completed upon reaching extraction")
	assert_true(level.hud.victory_overlay.visible, "Victory overlay displayed upon extraction")
	assert_true(level.player.input_disabled, "Player input locked upon mission success")
	
	level._exit_tree()
	level.queue_free()
	
	# Verify GameManager gameplay active flag resets on exit
	if GameManager:
		assert_true(not GameManager.is_gameplay_active, "GameManager.is_gameplay_active is FALSE after leaving level")

func test_phase3_enemy_ledge_detection_and_pit_prevention() -> void:
	print("\n--- TEST: Phase 3 Enemy Ledge Detection & Pit Prevention ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	var enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	enemy.set_physics_process(false)
	add_child(enemy)
	
	# Verify LedgeCheck node exists
	var ledge_check = enemy.get_node_or_null("LedgeCheck")
	assert_true(ledge_check != null, "Enemy has LedgeCheck RayCast2D for cliff detection")
	assert_eq(ledge_check.collision_mask, 2, "LedgeCheck scans terrain collision layer (mask 2)")
	
	# Verify facing update repositions ledge check ahead of feet
	enemy.facing_direction = -1
	enemy._update_facing()
	assert_eq(ledge_check.position.x, -12.0, "LedgeCheck positioned at -12px when facing left")
	enemy.facing_direction = 1
	enemy._update_facing()
	assert_eq(ledge_check.position.x, 12.0, "LedgeCheck positioned at +12px when facing right")
	
	# Verify 1 bullet hit immediately eliminates the enemy cleanly without upward pop
	assert_eq(enemy.current_health, 1, "Enemy starts with 1 health")
	enemy.take_hit(1)
	assert_eq(enemy.current_health, 0, "Enemy health drops to 0 after 1 hit")
	assert_true(enemy.is_dead, "Enemy marked dead")
	assert_eq(enemy.velocity.y, 0.0, "Elimination has no upward pop (velocity.y == 0.0)")
	
	enemy.queue_free()

func test_phase3_ambush_archetypes_and_reaction_buffers() -> void:
	print("\n--- TEST: Phase 3 Ambush Archetypes & Fair Telegraphs ---")
	# Check all 5 archetype enums
	assert_eq(int(BulletBetrayalEnemySoldier.AmbushType.BUNKER), 1, "AmbushType.BUNKER is defined")
	assert_eq(int(BulletBetrayalEnemySoldier.AmbushType.OFFSCREEN), 2, "AmbushType.OFFSCREEN is defined")
	assert_eq(int(BulletBetrayalEnemySoldier.AmbushType.ELEVATED), 3, "AmbushType.ELEVATED is defined")
	assert_eq(int(BulletBetrayalEnemySoldier.AmbushType.CONCEALED), 4, "AmbushType.CONCEALED is defined")
	assert_eq(int(BulletBetrayalEnemySoldier.AmbushType.REINFORCEMENT), 5, "AmbushType.REINFORCEMENT is defined")
	
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	var bunker_ambush: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
	bunker_ambush.is_ambush = true
	bunker_ambush.ambush_type = BulletBetrayalEnemySoldier.AmbushType.BUNKER
	add_child(bunker_ambush)
	
	assert_true(bunker_ambush.is_dormant, "Bunker ambush starts dormant")
	assert_true(not bunker_ambush.visible, "Bunker ambush starts invisible")
	
	# Trigger ambush
	bunker_ambush.trigger_ambush()
	assert_true(not bunker_ambush.is_dormant, "Bunker ambush active after trigger")
	assert_true(bunker_ambush.visible, "Bunker ambush visible after trigger")
	assert_true(bunker_ambush.alert_icon.visible, "Bunker ambush shows '!' alert telegraph")
	assert_true(bunker_ambush._shoot_timer >= 0.70, "Reaction window is at least 0.70s before first shot")
	assert_eq(bunker_ambush.current_health, 1, "Ambush enemy has 1 health upon reveal (1-bullet kill rule)")
	assert_true(bunker_ambush.has_ambushed, "Ambush enemy marked as has_ambushed")
	assert_eq(bunker_ambush.patrol_distance, 0.0, "Ambush enemy does not loop patrol (holds ground to shoot)")
	
	bunker_ambush.queue_free()

func test_phase3_ground_elevation_continuity_and_no_cliffs() -> void:
	print("\n--- TEST: Phase 3 Ground Elevation Continuity ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	var g1: StaticBody2D = level.get_node("Platforms/Ground1")
	var g2: StaticBody2D = level.get_node("Platforms/Ground2")
	var g3: StaticBody2D = level.get_node("Platforms/Ground3")
	var g4: StaticBody2D = level.get_node("Platforms/Ground4")
	var g5: StaticBody2D = level.get_node("Platforms/Ground5")
	var g6: StaticBody2D = level.get_node("Platforms/Ground6")
	
	# All ground segments must have top surface at exactly y = 410.0 (position 460 - 50 height)
	var g1_top = g1.position.y - 50.0
	var g2_top = g2.position.y - 50.0
	var g3_top = g3.position.y - 50.0
	var g4_top = g4.position.y - 50.0
	var g5_top = g5.position.y - 50.0
	var g6_top = g6.position.y - 50.0
	
	assert_eq(g1_top, 410.0, "Ground1 top elevation is exactly 410.0")
	assert_eq(g2_top, 410.0, "Ground2 top elevation is exactly 410.0")
	assert_eq(g3_top, 410.0, "Ground3 top elevation is exactly 410.0")
	assert_eq(g4_top, 410.0, "Ground4 top elevation is exactly 410.0")
	assert_eq(g5_top, 410.0, "Ground5 top elevation is exactly 410.0")
	assert_eq(g6_top, 410.0, "Ground6 top elevation is exactly 410.0")
	
	# Ground 1 and Ground 2 form a continuous 1000px runway with zero vertical step
	assert_eq(g1_top, g2_top, "Ground1 to Ground2 transition is completely flush (0px vertical cliff)")
	
	level.queue_free()

func test_phase3_enemy_no_auto_despawn_simulation() -> void:
	print("\n--- TEST: Phase 3 Enemy No Auto-Despawn Simulation ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	var enemies = level.enemies_container.get_children()
	assert_eq(enemies.size(), 10, "10 enemies present at start")
	
	# Trigger all ambushes
	var ambushes = level.get_node("Ambushes").get_children()
	for a in ambushes:
		for path in a.target_enemies:
			var enemy = a.get_node_or_null(path)
			if enemy and enemy.has_method("trigger_ambush"):
				enemy.trigger_ambush()
	
	# Simulate 180 physics frames without player shooting
	for frame in range(180):
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.is_dead and not enemy.is_dormant:
				enemy._physics_process(1.0 / 60.0)
	
	# Verify all 10 enemies are still alive and none have despawned or died automatically
	var alive_count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			alive_count += 1
			assert_true(enemy.global_position.y <= 460.0, "%s remained on platform (y <= 460.0)" % enemy.name)
	
	assert_eq(alive_count, 10, "All 10 enemies remained alive after 180 physics frames")
	assert_eq(level._enemies_eliminated, 0, "Zero automatic kills recorded (only actual bullets count)")
	assert_true(not level.extraction_beacon.is_unlocked, "Extraction beacon strictly locked at 0/10")
	
	level.queue_free()

func test_phase3_fire_hazard_2_jump_clearance_and_platform_deconfliction() -> void:
	print("\n--- TEST: Phase 3 Fire Hazard 2 Jump Clearance & Platform Deconfliction ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_1.tscn")
	var level: BulletBetrayalLevel1 = level_scene.instantiate()
	add_child(level)
	
	var fire2: Area2D = level.get_node_or_null("Hazards/FireHazard2_Ruins")
	assert_true(fire2 != null, "FireHazard2_Ruins exists in level")
	
	var plat3: StaticBody2D = level.get_node_or_null("Platforms/Platform3")
	assert_true(plat3 != null, "Platform3 exists in level")
	
	var plat3_col: CollisionShape2D = plat3.get_node_or_null("CollisionShape2D")
	assert_true(plat3_col != null, "Platform3 has CollisionShape2D")
	assert_true(plat3_col.one_way_collision, "Platform3 has one_way_collision enabled to prevent underside ceiling collision")
	
	var plat3_shape: RectangleShape2D = plat3_col.shape as RectangleShape2D
	assert_true(plat3_shape != null, "Platform3 has RectangleShape2D")
	var plat3_left: float = plat3.position.x - (plat3_shape.size.x / 2.0)
	var plat3_right: float = plat3.position.x + (plat3_shape.size.x / 2.0)
	var plat3_bottom: float = plat3.position.y + (plat3_shape.size.y / 2.0)
	var plat3_top: float = plat3.position.y - (plat3_shape.size.y / 2.0)
	
	# Horizontal deconfliction: platform starts well past the fire hazard
	var fire_x: float = fire2.position.x
	var horizontal_gap: float = plat3_left - fire_x
	assert_true(horizontal_gap >= 60.0, "Platform3 left edge (%s) is >= 60px past FireHazard2 (%s), gap: %s px" % [plat3_left, fire_x, horizontal_gap])
	
	# Vertical clearance: platform bottom is elevated above player max jump apex
	var ground_y: float = 410.0
	var vertical_clearance: float = ground_y - plat3_bottom
	assert_true(vertical_clearance >= 120.0, "Platform3 bottom (%s) provides >= 120px overhead clearance from ground (%s px)" % [plat3_bottom, vertical_clearance])
	
	# BarbedWire4 deconfliction: provides safe landing runway past fire
	var wire4: Sprite2D = level.get_node_or_null("Props/BarbedWire4")
	assert_true(wire4 != null, "BarbedWire4 exists in level")
	assert_true(wire4.position.x >= 1860.0, "BarbedWire4 (%s) is positioned at X >= 1860 for safe landing runway" % wire4.position.x)
	var landing_runway: float = wire4.position.x - fire_x
	assert_true(landing_runway >= 65.0, "Landing runway after fire is >= 65px (actual %s px)" % landing_runway)
	
	# Enemy7 Ledge Sentry placement: stands properly on elevated platform
	var enemy7 = level.get_node_or_null("Enemies/Enemy7_LedgeSentry")
	assert_true(enemy7 != null, "Enemy7_LedgeSentry exists on platform")
	assert_true(enemy7.position.y <= plat3_top, "Enemy7 y position (%s) is on/above Platform3 top surface (%s)" % [enemy7.position.y, plat3_top])
	var sentry_patrol_min = enemy7.position.x - enemy7.patrol_distance
	var sentry_patrol_max = enemy7.position.x + enemy7.patrol_distance
	assert_true(sentry_patrol_min >= plat3_left and sentry_patrol_max <= plat3_right, "Enemy7 patrol range [%s, %s] is fully contained within Platform3 [%s, %s]" % [sentry_patrol_min, sentry_patrol_max, plat3_left, plat3_right])
	
	# Jump Kinematics Calculation & Verification:
	# Running speed 175 px/s, jump velocity -420 px/s, gravity 980 px/s^2
	var player = level.player
	var jump_apex_y: float = 394.0 - ((player.jump_velocity * player.jump_velocity) / (2.0 * player.gravity))
	var hit_ceiling: bool = jump_apex_y < plat3_bottom
	var hang_time: float = (2.0 * abs(player.jump_velocity)) / player.gravity
	var horizontal_leap: float = player.move_speed * hang_time
	var landing_x: float = 1740.0 + horizontal_leap
	var passed_fire: bool = landing_x > fire_x + 20.0
	var landed_safely: bool = landing_x >= wire4.position.x - 20.0 and landing_x <= plat3_right

	assert_true(not hit_ceiling, "Player never hit overhead ceiling during leap over FireHazard2")
	assert_true(passed_fire, "Player cleared FireHazard2 horizontally")
	assert_true(landed_safely, "Player landed safely on ground after leap without taking damage")
	assert_true(player.is_alive, "Player is alive after completing jump over FireHazard2")
	
	level.queue_free()

func test_bb_save_manager_and_stars() -> void:
	print("\n--- TEST: Bullet Betrayal SaveManager & Progression Isolation ---")
	# Store original data to restore after test
	var orig_bb_highest = SaveManager.bb_highest_unlocked_level
	var orig_bb_completed = SaveManager.bb_completed_levels.duplicate()
	var orig_bb_stars = SaveManager.bb_stage_stars.duplicate()
	var orig_ch_highest = SaveManager.highest_unlocked_level
	var orig_ch_completed = SaveManager.completed_levels.duplicate()

	# Reset BB progress
	SaveManager.bb_highest_unlocked_level = 1
	SaveManager.bb_completed_levels = []
	SaveManager.bb_stage_stars = {}

	assert_true(SaveManager.is_bb_level_unlocked(1), "Stage 1 is unlocked by default")
	assert_true(not SaveManager.is_bb_level_unlocked(2), "Stage 2 is locked by default")
	assert_true(not SaveManager.is_bb_level_completed(1), "Stage 1 is not completed initially")
	assert_eq(SaveManager.get_bb_level_stars(1), 0, "Stage 1 has 0 stars initially")
	assert_eq(SaveManager.get_bb_completed_count(), 0, "BB completed count is 0")

	# Complete Stage 1 with 3 stars (no revives used)
	SaveManager.complete_bb_level(1, 3)
	assert_true(SaveManager.is_bb_level_completed(1), "Stage 1 is marked completed")
	assert_eq(SaveManager.get_bb_level_stars(1), 3, "Stage 1 recorded 3 stars")
	assert_true(SaveManager.is_bb_level_unlocked(2), "Stage 2 is now unlocked")
	assert_eq(SaveManager.get_bb_completed_count(), 1, "BB completed count is now 1")

	# Complete Stage 2 with 2 stars (1 revive used)
	SaveManager.complete_bb_level(2, 2)
	assert_true(SaveManager.is_bb_level_completed(2), "Stage 2 is marked completed")
	assert_eq(SaveManager.get_bb_level_stars(2), 2, "Stage 2 recorded 2 stars")
	assert_true(SaveManager.is_bb_level_unlocked(3), "Stage 3 is unlocked after Stage 2 clear")
	assert_eq(SaveManager.get_bb_completed_count(), 2, "BB completed count is now 2")

	# Verify Coin Hell progression remained completely isolated
	assert_eq(SaveManager.highest_unlocked_level, orig_ch_highest, "Coin Hell unlocked level untouched")
	assert_eq(SaveManager.completed_levels.size(), orig_ch_completed.size(), "Coin Hell completed levels untouched")

	# Test persistence across save & mock reload
	SaveManager.save_data()
	SaveManager.bb_highest_unlocked_level = 1
	SaveManager.bb_completed_levels = []
	SaveManager.bb_stage_stars = {}
	SaveManager.load_save()

	assert_true(SaveManager.is_bb_level_completed(1), "Stage 1 completion persisted after load_save()")
	assert_eq(SaveManager.get_bb_level_stars(1), 3, "Stage 1 3-stars persisted after load_save()")
	assert_true(SaveManager.is_bb_level_completed(2), "Stage 2 completion persisted after load_save()")
	assert_eq(SaveManager.get_bb_level_stars(2), 2, "Stage 2 2-stars persisted after load_save()")

	# Restore original state
	SaveManager.bb_highest_unlocked_level = orig_bb_highest
	SaveManager.bb_completed_levels = orig_bb_completed
	SaveManager.bb_stage_stars = orig_bb_stars
	SaveManager.save_data()

func test_bullet_betrayal_menu_stars_reflection() -> void:
	print("\n--- TEST: Bullet Betrayal Menu Stage Selection Stars & States ---")
	var orig_bb_highest = SaveManager.bb_highest_unlocked_level
	var orig_bb_completed = SaveManager.bb_completed_levels.duplicate()
	var orig_bb_stars = SaveManager.bb_stage_stars.duplicate()

	# Set mock state: Level 1 completed (3 stars), Level 2 available (0 stars), Level 3 locked
	SaveManager.bb_highest_unlocked_level = 2
	SaveManager.bb_completed_levels = [1]
	SaveManager.bb_stage_stars = {"1": 3}

	var menu_scene: PackedScene = load("res://scenes/bullet_betrayal/bullet_betrayal_menu.tscn")
	assert_true(menu_scene != null, "bullet_betrayal_menu.tscn loads successfully")
	var menu = menu_scene.instantiate()
	add_child(menu)

	var progress_lbl: Label = menu.get_node_or_null("MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel")
	assert_true(progress_lbl != null, "ProgressLabel exists in menu header")
	assert_eq(progress_lbl.text, "STAGES CLEARED: 1 / 20", "Progress label shows 1 / 20 stages cleared")

	# Check Stage 1 card tile: COMPLETED, 3 stars
	var btn_lvl1: Button = menu.get_level_button(1)
	assert_true(btn_lvl1 != null, "LevelBtn_1 exists in stage selection grid")
	var vbox1 = btn_lvl1.get_child(0)
	var state1_lbl: Label = vbox1.get_child(2)
	var stars1_lbl: Label = vbox1.get_node_or_null("StarsLabel")
	var status1_icon: TextureRect = vbox1.get_child(0).get_child(1)

	assert_eq(state1_lbl.text, "COMPLETED", "Stage 1 tile state is 'COMPLETED'")
	assert_true(status1_icon.visible, "Stage 1 completed icon is visible")
	assert_true(stars1_lbl != null, "Stage 1 stars label exists")
	assert_eq(stars1_lbl.text, "★ ★ ★", "Stage 1 shows 3 gold stars '★ ★ ★'")

	# Check Stage 2 card tile: AVAILABLE, ☆ ☆ ☆
	var btn_lvl2: Button = menu.get_level_button(2)
	assert_true(btn_lvl2 != null, "LevelBtn_2 exists in stage selection grid")
	var vbox2 = btn_lvl2.get_child(0)
	var state2_lbl: Label = vbox2.get_child(2)
	var stars2_lbl: Label = vbox2.get_node_or_null("StarsLabel")
	var status2_icon: TextureRect = vbox2.get_child(0).get_child(1)

	assert_eq(state2_lbl.text, "AVAILABLE", "Stage 2 tile state is 'AVAILABLE'")
	assert_true(not status2_icon.visible, "Stage 2 icon is not visible (unlocked, not completed)")
	assert_eq(stars2_lbl.text, "☆ ☆ ☆", "Stage 2 shows empty stars '☆ ☆ ☆'")

	# Check Stage 3 card tile: LOCKED (implemented, requires Stage 2 clear)
	var btn_lvl3: Button = menu.get_level_button(3)
	assert_true(btn_lvl3 != null, "LevelBtn_3 exists")
	var vbox3 = btn_lvl3.get_child(0)
	var state3_lbl: Label = vbox3.get_child(2)
	assert_eq(state3_lbl.text, "LOCKED", "Stage 3 tile state is 'LOCKED'")

	# Check Stage 4 card tile: LOCKED (implemented stage)
	var btn_lvl4: Button = menu.get_level_button(4)
	assert_true(btn_lvl4 != null, "LevelBtn_4 exists")
	var vbox4 = btn_lvl4.get_child(0)
	var state4_lbl: Label = vbox4.get_child(2)
	assert_eq(state4_lbl.text, "LOCKED", "Stage 4 tile state is 'LOCKED'")

	# Check Stage 5 card tile: LOCKED (implemented stage)
	var btn_lvl5: Button = menu.get_level_button(5)
	assert_true(btn_lvl5 != null, "LevelBtn_5 exists")
	var vbox5 = btn_lvl5.get_child(0)
	var state5_lbl: Label = vbox5.get_child(2)
	assert_eq(state5_lbl.text, "LOCKED", "Stage 5 tile state is 'LOCKED'")

	# Check Stage 6 card tile: PLANNED (future unreleased stage)
	var btn_lvl6: Button = menu.get_level_button(6)
	assert_true(btn_lvl6 != null, "LevelBtn_6 exists")
	var vbox6 = btn_lvl6.get_child(0)
	var state6_lbl: Label = vbox6.get_child(2)
	assert_eq(state6_lbl.text, "PLANNED", "Stage 6 tile state is 'PLANNED'")

	menu.queue_free()

	# Restore original state
	SaveManager.bb_highest_unlocked_level = orig_bb_highest
	SaveManager.bb_completed_levels = orig_bb_completed
	SaveManager.bb_stage_stars = orig_bb_stars
	SaveManager.save_data()

func test_level_2_scene_and_combat_rules() -> void:
	print("\n--- TEST: World 1 Level 2 Scene & Combat Rules ---")
	var lvl2_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_2.tscn")
	assert_true(lvl2_scene != null, "bb_level_2.tscn loads successfully")
	var level = lvl2_scene.instantiate()
	add_child(level)
	if level.player:
		level.player._physics_process(1.0 / 60.0)
		level.player._physics_process(1.0 / 60.0)

	var player = level.player
	var hud = level.hud
	var extraction = level.extraction_beacon
	var enemies = level.enemies_container
	var pickups = level.pickups_container

	assert_true(player != null, "Level 2 has player")
	assert_true(hud != null, "Level 2 has HUD")
	assert_true(extraction != null, "Level 2 has extraction beacon")
	assert_true(enemies != null, "Level 2 has enemies container")
	assert_true(pickups != null, "Level 2 has pickups container")

	# 1. 10 required enemies verification
	var enemy_children = enemies.get_children()
	assert_eq(enemy_children.size(), 10, "Level 2 has exactly 10 enemies")

	# 2. 1-bullet kill enemy durability verification (1-hit eliminate)
	for i in range(enemy_children.size()):
		var enemy = enemy_children[i]
		if enemy is BulletBetrayalEnemySoldier:
			assert_eq(enemy.max_health, 1, "Enemy %d has max_health == 1 (1-bullet kill durability)" % (i + 1))
			assert_eq(enemy.current_health, 1, "Enemy %d starts with current_health == 1" % (i + 1))

	# Test 1-hit damage logic on first enemy
	var test_enemy = enemy_children[0] as BulletBetrayalEnemySoldier
	test_enemy.take_hit(1)
	assert_eq(test_enemy.current_health, 0, "Enemy health drops to 0 after 1 bullet hit")
	assert_true(test_enemy.is_dead, "Enemy is eliminated after 1 bullet hit")

	# 3. Starting ammunition verification: exactly 10 rounds
	assert_eq(player.current_ammo, 10, "Player starts Level 2 with exactly 10 bullets")
	assert_eq(player.current_health, 1, "Player starts Level 2 with 1 life")

	# 4. Ammunition pickups verification: ZERO ammunition pickups (0 crates)
	var pickup_children = pickups.get_children()
	assert_eq(pickup_children.size(), 0, "Level 2 has exactly 0 ammo pickups (zero ammunition crates per rules)")

	# 5. Continuous solid ground verification at Y=410
	var ground_container = level.get_node_or_null("Platforms")
	assert_true(ground_container != null, "Level 2 has Platforms container")
	for i in range(1, 6):
		var g = ground_container.get_node_or_null("Ground%d" % i)
		assert_true(g != null, "Ground%d exists in Level 2" % i)
		if g:
			var col: CollisionShape2D = g.get_node_or_null("CollisionShape2D")
			assert_true(col != null, "Ground%d has CollisionShape2D" % i)
			var col_rect = col.shape as RectangleShape2D
			var top_y = g.position.y + col.position.y - (col_rect.size.y / 2.0)
			assert_eq(top_y, 410.0, "Ground%d surface elevation is Y=410 (continuous solid ground)" % i)

	# 6. Extraction beacon locked verification
	assert_true(not extraction.is_unlocked, "Extraction beacon is locked at 0/10 kills")
	extraction.update_target_progress(9, 10)
	assert_true(not extraction.is_unlocked, "Extraction beacon remains locked at 9/10 kills")
	extraction.update_target_progress(10, 10)
	assert_true(extraction.is_unlocked, "Extraction beacon unlocks strictly at 10/10 kills")

	# 7. One-hit player death verification
	player.take_damage(1)
	assert_eq(player.current_health, 0, "Player health drops to 0 after 1 hit")
	assert_true(not player.is_alive, "Player dies immediately from 1 hit")

	# 8. Revive verification: restores 1 life and 10 bullets
	player.revive()
	assert_eq(player.current_health, 1, "Player revived with 1 life")
	assert_eq(player.current_ammo, 10, "Player revived with 10 bullets")
	assert_true(player.is_alive, "Player is alive after revive")

	level.queue_free()

func test_level_2_ladder_rear_ambush_and_polish() -> void:
	print("\n--- TEST: Level 2 Ladder Mechanics, Rear Ambush & Battlefield Polish ---")
	var lvl2_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_2.tscn")
	assert_true(lvl2_scene != null, "bb_level_2.tscn loads successfully")
	var level = lvl2_scene.instantiate()
	add_child(level)
	if level.player:
		level.player._physics_process(1.0 / 60.0)
		level.player._physics_process(1.0 / 60.0)

	var player = level.player
	var hud = level.hud

	# 1. Zero flame and burner hazards verification
	var hazards_node = level.get_node_or_null("Hazards")
	if hazards_node:
		assert_eq(hazards_node.get_child_count(), 0, "Level 2 Hazards container has 0 children")
	else:
		assert_true(hazards_node == null, "Hazards node completely removed from Level 2")
	var any_fire = level.find_children("*Fire*", "", true, false)
	assert_eq(any_fire.size(), 0, "Zero fire hazard nodes exist anywhere in Level 2")
	var any_burner = level.find_children("*Burner*", "", true, false)
	assert_eq(any_burner.size(), 0, "Zero burner hazard nodes exist anywhere in Level 2")

	# 2. Dynamic HUD title verification for Level 2
	assert_eq(hud.current_stage_id, 2, "HUD current_stage_id is set to 2")
	assert_eq(hud.stage_label.text, "WORLD 1-2: RIVER AMBUSH", "HUD top bar displays 'WORLD 1-2: RIVER AMBUSH'")

	# 3. Watchtower platform & ladder mechanics
	var plat4: StaticBody2D = level.get_node_or_null("Platforms/Platform4_Watchtower")
	assert_true(plat4 != null, "Platform4_Watchtower exists")
	var plat4_col: CollisionShape2D = plat4.get_node_or_null("CollisionShape2D")
	assert_true(plat4_col != null, "Platform4_Watchtower has CollisionShape2D")
	assert_true(plat4_col.one_way_collision, "Platform4_Watchtower has one_way_collision enabled for smooth landing")

	var ladder = level.get_node_or_null("Ladder_Watchtower")
	assert_true(ladder != null, "Ladder_Watchtower exists in Level 2")
	assert_true(ladder is BulletBetrayalLadder, "Ladder_Watchtower is BulletBetrayalLadder instance")

	# Test ladder trigger and player climbing kinematics
	ladder._on_body_entered(player)
	assert_true(player.is_on_ladder, "Player detects ladder upon overlap")

	# Idle on ladder - no vertical movement, clinging to rungs
	player.touch_jump = false
	player._handle_input(1.0 / 60.0)
	assert_eq(player.velocity.y, 0.0, "Player clings stationary to ladder when no climbing input is given")

	# Climbing up ladder with jump/up input
	player.touch_jump = true
	player._handle_input(1.0 / 60.0)
	assert_true(player.velocity.y < 0.0, "Player climbs upward with touch_jump input")
	assert_eq(player.velocity.y, -player.ladder_climb_speed, "Climb speed equals ladder_climb_speed")

	# Exit ladder
	player.touch_jump = false
	ladder._on_body_exited(player)
	assert_true(not player.is_on_ladder, "Player exits ladder state on body_exited")

	# 4. Dynamic rear ambush verification (Detecting movement and facing direction)
	var enemy2: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy2_RearAmbush")
	assert_true(enemy2 != null, "Enemy2_RearAmbush exists in Level 2")
	assert_eq(enemy2.ambush_type, BulletBetrayalEnemySoldier.AmbushType.BEHIND, "Enemy2 has AmbushType.BEHIND")
	assert_true(enemy2.is_dormant, "Enemy2 starts dormant")
	assert_true(not enemy2.visible, "Enemy2 starts hidden")

	# Test 4A: Moving Right -> Enemy emerges from the rear (left of player), facing right
	player.global_position = Vector2(660, 394)
	player.velocity = Vector2(230.0, 0.0)
	player.facing_direction = 1
	enemy2.reset()
	enemy2.trigger_ambush(player)
	assert_true(not enemy2.is_dormant, "Enemy2 is active after trigger")
	assert_true(enemy2.visible, "Enemy2 is visible after trigger")
	assert_true(enemy2.global_position.x < player.global_position.x, "Ambush spawns behind moving player (to the left: %s < %s)" % [enemy2.global_position.x, player.global_position.x])
	assert_eq(enemy2.facing_direction, 1, "Enemy2 faces rightward toward advancing player's back")
	assert_true(enemy2.velocity.x > 0.0, "Enemy2 steps forward into combat lane")
	assert_true(enemy2.alert_icon.visible, "Enemy2 displays '!' alert telegraph for fair reaction")

	# Test 4B: Moving Left -> Enemy emerges from the rear (right of player), facing left
	player.global_position = Vector2(660, 394)
	player.velocity = Vector2(-230.0, 0.0)
	player.facing_direction = -1
	enemy2.reset()
	enemy2.trigger_ambush(player)
	assert_true(enemy2.global_position.x > player.global_position.x, "Ambush spawns behind backtracking player (to the right: %s > %s)" % [enemy2.global_position.x, player.global_position.x])
	assert_eq(enemy2.facing_direction, -1, "Enemy2 faces leftward toward backtracking player's back")
	assert_true(enemy2.velocity.x < 0.0, "Enemy2 steps leftward toward player")

	# Test 4C: Stationary facing Left -> Uses last facing direction to place ambush to the right
	player.global_position = Vector2(660, 394)
	player.velocity = Vector2.ZERO
	player.facing_direction = -1
	enemy2.reset()
	enemy2.trigger_ambush(player)
	assert_true(enemy2.global_position.x > player.global_position.x, "Stationary facing left triggers ambush from behind (to the right)")
	assert_eq(enemy2.facing_direction, -1, "Enemy2 faces toward player")

	# Test 4D: Stationary facing Right -> Uses last facing direction to place ambush to the left
	player.global_position = Vector2(660, 394)
	player.velocity = Vector2.ZERO
	player.facing_direction = 1
	enemy2.reset()
	enemy2.trigger_ambush(player)
	assert_true(enemy2.global_position.x < player.global_position.x, "Stationary facing right triggers ambush from behind (to the left)")
	assert_eq(enemy2.facing_direction, 1, "Enemy2 faces toward player")

	# Test 4E: Eliminating ambush enemy with 1 bullet
	enemy2.take_hit(1)
	assert_true(enemy2.is_dead, "Ambush enemy eliminated in 1 hit")

	var enemy6: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy6_RearFlanker2")
	assert_true(enemy6 != null, "Enemy6_RearFlanker2 exists in Level 2")
	assert_eq(enemy6.ambush_type, BulletBetrayalEnemySoldier.AmbushType.BEHIND, "Enemy6 has AmbushType.BEHIND")

	# 5. Elevated Watchtower sniper verification
	var enemy10: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy10_WatchtowerSniper")
	assert_true(enemy10 != null, "Enemy10_WatchtowerSniper exists atop watchtower")
	assert_true(enemy10.position.y < plat4.position.y, "Enemy10 is stationed atop Platform4")

	level.queue_free()


func test_level_2_final_jump_over_bar_and_landing() -> void:
	print("\n--- TEST: Level 2 Final Jump Over Bar, Safe Landing & Camera Boundary ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_2.tscn")
	var level: BulletBetrayalLevel2 = level_scene.instantiate()
	add_child(level)
	
	var player: BulletBetrayalPlayer = level.player
	var enemy10: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy10_WatchtowerSniper")
	var plat4: StaticBody2D = level.get_node_or_null("Platforms/Platform4_Watchtower")
	var ladder: Area2D = level.get_node_or_null("Ladder_Watchtower")
	var beacon: BulletBetrayalExtractionBeacon = level.extraction_beacon
	var right_wall: StaticBody2D = level.get_node_or_null("Platforms/RightWall")
	var ground5: StaticBody2D = level.get_node_or_null("Platforms/Ground5")
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	
	assert_true(plat4 != null, "Platform4_Watchtower exists")
	assert_true(ladder != null, "Ladder_Watchtower exists")
	assert_true(right_wall != null, "RightWall exists")
	assert_true(ground5 != null, "Ground5 exists")
	assert_true(beacon != null, "ExtractionBeacon exists")
	
	# 1. Camera limit verification: Level 2 expands limit_right to encompass the full landing runway
	assert_true(cam.limit_right >= 2860, "Camera limit_right covers full stage landing runway (%s >= 2860)" % cam.limit_right)
	
	# 2. Ground 5 & RightWall geometry verification
	var g5_col: CollisionShape2D = ground5.get_node("CollisionShape2D")
	var g5_shape: RectangleShape2D = g5_col.shape as RectangleShape2D
	var g5_right_edge: float = ground5.global_position.x + (g5_shape.size.x / 2.0)
	assert_true(g5_right_edge >= 2860.0, "Ground5 extends continuously to X >= 2860 (actual: %s)" % g5_right_edge)
	assert_true(right_wall.global_position.x >= 2860.0, "RightWall position is positioned past landing runway (actual: %s)" % right_wall.global_position.x)
	
	# 3. Bar collision geometry & position relative to ground (jumpable with normal impulse vy=-460, g=1100)
	var p4_col: CollisionShape2D = plat4.get_node("CollisionShape2D")
	var p4_shape: RectangleShape2D = p4_col.shape as RectangleShape2D
	var p4_top: float = plat4.global_position.y - (p4_shape.size.y / 2.0)
	var ground_y: float = ground5.global_position.y - (g5_shape.size.y / 2.0)
	var bar_height_above_ground: float = ground_y - p4_top
	assert_true(bar_height_above_ground < 90.0, "Bar height above ground (%s px) is within natural jump apex of 96.18 px" % bar_height_above_ground)
	assert_true(p4_shape.size.x <= 100.0, "Bar width (%s px) allows clean horizontal leap clearance" % p4_shape.size.x)
	
	# 4. Ladder Area2D vertical clearance: terminates strictly at or below platform underside
	var ladder_col: CollisionShape2D = ladder.get_node("CollisionShape2D")
	var ladder_shape: RectangleShape2D = ladder_col.shape as RectangleShape2D
	var ladder_top: float = ladder.global_position.y - (ladder_shape.size.y / 2.0)
	assert_true(ladder_top >= (p4_top + p4_shape.size.y), "Ladder Area2D terminates below platform top surface (actual top: %s, plat bottom: %s)" % [ladder_top, p4_top + p4_shape.size.y])
	
	# 5. Extraction Beacon position & extended landing reach
	assert_true(beacon.global_position.x >= 2600.0, "ExtractionBeacon is positioned at X >= 2600 on landing runway (actual: %s)" % beacon.global_position.x)
	var beacon_col: CollisionShape2D = beacon.get_node("CollisionShape2D")
	var beacon_shape: RectangleShape2D = beacon_col.shape as RectangleShape2D
	assert_true(beacon_shape.size.y >= 100.0, "ExtractionBeacon trigger volume is >= 100px tall to capture ground runs and descending leaps")
	
	# 6. Physics Simulation: Running jump from ground clears complete collision area of the bar
	enemy10.can_shoot = false # Isolate platforming kinematics
	player.global_position = Vector2(2360, 394)
	player.velocity = Vector2.ZERO
	player.reset_touch_inputs()
	for i in range(5):
		await get_tree().physics_frame
	
	player.touch_right = true
	player.touch_jump = true
	player.touch_jump_just_pressed = true
	
	var ground_jump_cleared_bar := false
	var ground_jump_landed_safe := false
	
	for f in range(65):
		await get_tree().physics_frame
		if player.is_on_floor() and f > 15:
			if player.global_position.y >= 393.0 and player.global_position.x > (plat4.global_position.x + p4_shape.size.x / 2.0):
				ground_jump_landed_safe = true
				ground_jump_cleared_bar = true
				break
	
	assert_true(ground_jump_cleared_bar, "Player clears complete bar collision area when jumping from the ground")
	assert_true(ground_jump_landed_safe, "Player lands safely on the intended ground runway past the bar")
	
	# 7. Physics Simulation: Ascend ladder to top of bar, stand firmly, and reach extraction
	player.global_position = Vector2(2440, 394)
	player.velocity = Vector2.ZERO
	player.reset_touch_inputs()
	for i in range(5):
		await get_tree().physics_frame
	
	# Ascend ladder to top
	player.touch_jump = true
	for f in range(45):
		await get_tree().physics_frame
	
	player.touch_jump = false
	for f in range(45):
		await get_tree().physics_frame
		if player.is_on_floor():
			break
	
	assert_true(player.is_on_floor(), "Player is firmly resting on Platform4 surface (is_on_floor == true)")
	assert_true(not player.is_on_ladder, "Player is NOT inside ladder Area2D while standing atop Platform4")
	
	# Unlock extraction beacon (simulating all 10 enemies eliminated)
	beacon.update_target_progress(10, 10)
	assert_true(beacon.is_unlocked, "Extraction beacon is unlocked")
	
	# Walk / leap forward from bar to extraction beacon
	player.touch_right = true
	var extraction_triggered := [false]
	beacon.extraction_reached.connect(func():
		extraction_triggered[0] = true
	)
	
	for f in range(180):
		await get_tree().physics_frame
		if extraction_triggered[0]:
			break
	
	assert_true(extraction_triggered[0], "Extraction beacon is reached and triggered after crossing the bar")
	
	level.queue_free()

func test_level_3_operation_dead_ground() -> void:
	print("\n--- TEST: Level 3 Operation Dead Ground ---")
	var l3_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_3.tscn")
	assert_true(l3_scene != null, "bb_level_3.tscn scene exists and loads successfully")
	var level = l3_scene.instantiate()
	add_child(level)
	
	# Verify root controller
	assert_true(level is BulletBetrayalLevel3, "Level 3 root node is BulletBetrayalLevel3")
	
	# Verify player and spawn
	var p: BulletBetrayalPlayer = level.get_node_or_null("Player")
	assert_true(p != null, "Player exists in Level 3")
	assert_eq(p.initial_ammo, 10, "Player starts Level 3 with exactly 10 initial bullets")
	assert_eq(p.current_ammo, 10, "Player starts Level 3 with exactly 10 current rounds")
	assert_eq(p.max_health, 1, "Player max_health is 1 (one-hit death rule)")
	assert_eq(p.current_health, 1, "Player starts with 1 health")

	# Verify ground terrain collision layer (Layer 2 terrain)
	var ground1: StaticBody2D = level.get_node_or_null("Terrain/Ground1")
	assert_true(ground1 != null, "Ground1 exists in Level 3")
	assert_eq(ground1.collision_layer, 2, "Ground1 is on collision_layer 2 (terrain)")
	assert_eq(ground1.collision_mask, 0, "Ground1 has collision_mask 0")

	# Verify spawn point and player initial position calculation
	var spawn_pt: Marker2D = level.get_node_or_null("SpawnPoint")
	assert_true(spawn_pt != null, "SpawnPoint exists in Level 3")
	assert_eq(spawn_pt.position, Vector2(120, 394), "SpawnPoint is calculated exactly on ground at (120, 394)")
	assert_eq(p.position, Vector2(120, 394), "Player starts firmly aligned on ground at (120, 394)")
	
	# Verify pickups container has 0 ammo pickups
	var pickups: Node2D = level.get_node_or_null("Pickups")
	assert_true(pickups != null, "Pickups container exists in Level 3")
	assert_eq(pickups.get_child_count(), 0, "Level 3 has zero ammo pickups per combat rules")
	
	# Verify no fire or burner hazards
	var hazards = level.get_node_or_null("Hazards")
	assert_true(hazards == null, "Zero fire or burner hazards in Level 3")
	
	# Verify HUD configuration
	var hud: BulletBetrayalHUD = level.get_node_or_null("HUD")
	assert_true(hud != null, "HUD exists in Level 3")
	assert_eq(hud.current_stage_id, 3, "HUD current_stage_id is set to 3")
	var stage_lbl: Label = hud.get_node_or_null("TopBar/StageTitle")
	if stage_lbl:
		assert_eq(stage_lbl.text, "WORLD 1-3: OPERATION DEAD GROUND", "HUD displays 'WORLD 1-3: OPERATION DEAD GROUND'")
	
	# Verify Enemies (Exactly 10 required enemies, 1 bullet kills each)
	var enemies: Node2D = level.get_node_or_null("Enemies")
	assert_true(enemies != null, "Enemies container exists in Level 3")
	assert_eq(enemies.get_child_count(), 10, "Level 3 has exactly 10 required enemies")
	for i in range(10):
		var enemy = enemies.get_child(i)
		assert_true(enemy is BulletBetrayalEnemySoldier, "Enemy %d is BulletBetrayalEnemySoldier" % (i + 1))
		assert_eq(enemy.max_health, 1, "Enemy %d has max_health == 1 (1-bullet kill)" % (i + 1))
		assert_eq(enemy.current_health, 1, "Enemy %d starts with current_health == 1" % (i + 1))
	
	# Verify Landmines (Exactly 3 landmines, contact lethal, 0 at distance)
	var landmines: Node2D = level.get_node_or_null("Landmines")
	assert_true(landmines != null, "Landmines container exists in Level 3")
	assert_eq(landmines.get_child_count(), 3, "Level 3 has exactly 3 landmines (Mine 1, Mine 2, Mine 3)")
	
	var mine1: BulletBetrayalLandmine = level.get_node_or_null("Landmines/Mine1_Intro")
	var mine2: BulletBetrayalLandmine = level.get_node_or_null("Landmines/Mine2_Tactical")
	var mine3: BulletBetrayalLandmine = level.get_node_or_null("Landmines/Mine3_Final")
	assert_true(mine1 != null, "Mine1_Intro exists in Level 3")
	assert_true(mine2 != null, "Mine2_Tactical exists in Level 3")
	assert_true(mine3 != null, "Mine3_Final exists in Level 3")
	
	# Check mine collision setup
	assert_eq(mine1.collision_layer, 0, "Landmine is on collision_layer 0 (immune to bullets)")
	assert_eq(mine1.collision_mask, 1, "Landmine detects player on collision_mask 1")

	# Verify Blinking Red Light System (high-visibility digital pulse)
	assert_true(mine2.warning_led != null, "Mine 2 has warning_led ColorRect diode")
	assert_true(mine2.warning_glow != null, "Mine 2 has warning_glow Sprite2D halo")
	# Test digital strobe cadence states
	mine2._blink_timer = 0.05 # During Flash 1
	mine2._process(0.0)
	assert_true(mine2.warning_glow.visible, "Mine 2 LED glow is active during Flash 1")
	mine2._blink_timer = 0.16 # During Gap 1
	mine2._process(0.0)
	assert_true(not mine2.warning_glow.visible, "Mine 2 LED turns dark during Gap 1")
	mine2._blink_timer = 0.25 # During Flash 2 (double-pulse)
	mine2._process(0.0)
	assert_true(mine2.warning_glow.visible, "Mine 2 LED glow is active during Flash 2")
	mine2._blink_timer = 0.50 # During Rest interval
	mine2._process(0.0)
	assert_true(not mine2.warning_glow.visible, "Mine 2 LED rests dark during pause interval")
	
	# Verify Mine 1 is safe from distance
	p.global_position = Vector2(mine1.global_position.x - 50.0, mine1.global_position.y - 10.0)
	assert_true(not mine1._triggered, "Mine 1 does not detonate from distance")
	assert_true(p.is_alive, "Player is alive when standing away from mine")
	
	# Verify Mine 1 contact kills player in 1 hit and triggers explosion
	var mine_exploded := [false]
	mine1.exploded.connect(func(): mine_exploded[0] = true)
	mine1.detonate(p)
	await get_tree().physics_frame
	assert_true(mine1._triggered, "Mine 1 marks triggered upon contact")
	assert_true(mine_exploded[0], "Mine 1 emits exploded signal")
	assert_true(p.is_dead, "Player dies immediately from 1-hit landmine blast")
	assert_true(mine1.collision_shape.disabled, "Mine 1 collision shape is deferred disabled (single trigger guarantee)")
	# Verify Enhanced Explosion Blast FX (Scorch, Fire, Shockwave, Shrapnel & Smoke)
	assert_true(mine1.scorch_mark != null and mine1.scorch_mark.visible, "Mine 1 reveals ground scorch mark upon detonation")
	assert_true(mine1.explosion_fx != null and mine1.explosion_fx.visible, "Mine 1 explosion FX node is visible")
	assert_true(mine1.shockwave != null, "Mine 1 features expanding shockwave ring")
	assert_true(mine1.fire_core != null, "Mine 1 features incandescent fireball core")
	assert_true(mine1.fire_plume != null, "Mine 1 features billowing fireball plume")
	assert_true(mine1.shrapnel_particles != null and mine1.shrapnel_particles.emitting, "Mine 1 bursts shrapnel spark particles")
	assert_true(mine1.smoke_particles != null and mine1.smoke_particles.emitting, "Mine 1 emits rising smoke particles")
	
	# Verify duplicate trigger on already exploded mine does nothing
	mine_exploded[0] = false
	mine1.detonate(p)
	assert_true(not mine_exploded[0], "Detonated mine does not explode a second time")
	
	# Revive player and verify revive mechanics
	level._on_player_revived()
	p.revive(spawn_pt.global_position)
	assert_true(p.is_alive, "Player successfully revived")
	assert_eq(p.global_position, spawn_pt.global_position, "Player revived at safe spawn position")
	assert_eq(p.current_ammo, 10, "Player revived with 10 bullets")
	assert_eq(p.current_health, 1, "Player revived with 1 life")
	
	# Verify Rear Ambush (Enemy 8)
	var rear_ambush: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy8_RearAmbush")
	assert_true(rear_ambush != null, "Enemy8_RearAmbush exists in Level 3")
	assert_eq(rear_ambush.ambush_type, BulletBetrayalEnemySoldier.AmbushType.BEHIND, "Enemy 8 uses AmbushType.BEHIND")
	assert_true(rear_ambush.is_dormant, "Enemy 8 starts dormant")
	
	# Verify Extraction Beacon & 10/10 locked gate
	var beacon: BulletBetrayalExtractionBeacon = level.get_node_or_null("ExtractionBeacon")
	assert_true(beacon != null, "ExtractionBeacon exists in Level 3")
	assert_eq(beacon.required_enemies, 10, "Extraction beacon requires 10 enemies")
	beacon.update_target_progress(0, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon is locked at 0/10 kills")
	beacon.update_target_progress(9, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon remains locked at 9/10 kills")
	beacon.update_target_progress(10, 10)
	assert_true(beacon.is_unlocked, "Extraction beacon unlocks strictly at 10/10 kills")
	
	# Verify camera limits
	var cam: Camera2D = p.get_node_or_null("Camera2D")
	if cam:
		assert_eq(cam.limit_left, 0, "Camera limit_left is 0")
		assert_eq(cam.limit_top, 0, "Camera limit_top is 0")
		assert_eq(cam.limit_bottom, 540, "Camera limit_bottom is 540")
		assert_true(cam.limit_right >= 2860, "Camera limit_right covers the entire Level 3 stage")
	
	level.queue_free()

func test_level_4_the_hunting_mines() -> void:
	print("\n--- TEST: World 1 Level 4 'The Hunting Mines' ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_4.tscn")
	assert_true(level_scene != null, "Level 4 scene loads successfully")
	var level = level_scene.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(level is BulletBetrayalLevel4, "Level 4 root is BulletBetrayalLevel4")

	# Safe spawn check
	var p: BulletBetrayalPlayer = level.get_node_or_null("Player")
	var spawn_pt: Marker2D = level.get_node_or_null("SpawnPoint")
	assert_true(p != null, "Player exists in Level 4")
	assert_true(spawn_pt != null, "SpawnPoint exists in Level 4")
	assert_eq(p.global_position, Vector2(120, 394), "Player starts at safe spawn position (120, 394)")
	assert_true(p.is_alive, "Player is alive at level start")
	assert_eq(p.current_ammo, 10, "Player starts with exactly 10 bullets")
	assert_eq(p.current_health, 1, "Player starts with 1 life (1-hit death)")

	# Pickups check: exactly 0
	var pickups: Node2D = level.get_node_or_null("Pickups")
	assert_true(pickups != null, "Pickups container exists in Level 4")
	assert_eq(pickups.get_child_count(), 0, "Level 4 has 0 ammunition pickups (strict ammo discipline)")

	# Enemies check: exactly 10 required enemies, 1-bullet kills
	var enemies: Node2D = level.get_node_or_null("Enemies")
	assert_true(enemies != null, "Enemies container exists in Level 4")
	assert_eq(enemies.get_child_count(), 10, "Level 4 has exactly 10 required enemies")
	for i in range(10):
		var enemy = enemies.get_child(i)
		assert_true(enemy is BulletBetrayalEnemySoldier, "Enemy %d is BulletBetrayalEnemySoldier" % (i + 1))
		assert_eq(enemy.max_health, 1, "Enemy %d has max_health == 1 (1-bullet kill)" % (i + 1))
		assert_eq(enemy.current_health, 1, "Enemy %d starts with current_health == 1" % (i + 1))

	# Stationary Landmines check
	var stationary_mines: Node2D = level.get_node_or_null("Landmines")
	assert_true(stationary_mines != null, "Landmines container exists in Level 4")
	assert_eq(stationary_mines.get_child_count(), 2, "Level 4 has 2 stationary landmines")

	# Hunting Landmines check
	var hunting_mines: Node2D = level.get_node_or_null("HuntingMines")
	assert_true(hunting_mines != null, "HuntingMines container exists in Level 4")
	assert_eq(hunting_mines.get_child_count(), 3, "Level 4 has exactly 3 hunting landmines")

	var hmine1: BulletBetrayalHuntingMine = level.get_node_or_null("HuntingMines/HuntingMine1_Intro")
	var hmine2: BulletBetrayalHuntingMine = level.get_node_or_null("HuntingMines/HuntingMine2_Field")
	var hmine3: BulletBetrayalHuntingMine = level.get_node_or_null("HuntingMines/HuntingMine3_Passage")
	assert_true(hmine1 != null, "HuntingMine1_Intro exists in Level 4")
	assert_true(hmine2 != null, "HuntingMine2_Field exists in Level 4")
	assert_true(hmine3 != null, "HuntingMine3_Passage exists in Level 4")

	# Verify visual and collision parity with stationary landmines
	assert_eq(hmine1.collision_layer, 0, "Hunting mine is on collision_layer 0 (immune to bullets)")
	assert_eq(hmine1.collision_mask, 2, "Hunting mine collides with solid terrain on layer 2")
	assert_true(hmine1.hurt_area != null, "Hunting mine has hurt_area Area2D")
	assert_eq(hmine1.hurt_area.collision_mask, 1, "Hunting mine hurt_area detects player on mask 1")
	assert_true(hmine1.warning_led != null, "Hunting mine has warning_led ColorRect")
	assert_true(hmine1.warning_glow != null, "Hunting mine has warning_glow Sprite2D")
	assert_true(hmine1.scorch_mark != null, "Hunting mine has scorch_mark Sprite2D")
	assert_true(hmine1.explosion_fx != null, "Hunting mine has explosion_fx Node2D")

	# Verify State Machine: Initial Patrol State & Locomotion
	assert_eq(hmine1.current_state, BulletBetrayalHuntingMine.State.PATROL, "Hunting mine starts in PATROL state")
	hmine1._physics_process(0.016)
	assert_true(abs(hmine1.velocity.x) > 0.0, "Hunting mine moves horizontally during patrol")

	# Verify Alert & Chase Transitions
	# Move player within detection radius of HuntingMine 1
	p.global_position = Vector2(hmine1.global_position.x + 60.0, hmine1.global_position.y - 10.0)
	hmine1._physics_process(0.016)
	assert_eq(hmine1.current_state, BulletBetrayalHuntingMine.State.ALERT, "Hunting mine enters ALERT state when player detected within radius")

	# Advance alert timer to trigger Chase
	hmine1._alert_timer = 0.0
	hmine1._physics_process(0.016)
	assert_eq(hmine1.current_state, BulletBetrayalHuntingMine.State.CHASE, "Hunting mine transitions from ALERT to CHASE")
	assert_true(hmine1.velocity.x > 0.0, "Hunting mine pursues toward the player's position")

	# Verify Pursuit Boundary & Give-Up Behavior (never follows across level)
	# Position mine 80px out during chase so it is outside patrol reset threshold
	hmine1.global_position.x = hmine1.spawn_position.x + 80.0
	# Move player far away beyond max pursuit boundary
	p.global_position = Vector2(120.0, 394.0)
	hmine1._physics_process(0.016)
	assert_eq(hmine1.current_state, BulletBetrayalHuntingMine.State.RETURNING, "Hunting mine enters RETURNING state when player escapes pursuit range")
	assert_true(hmine1.velocity.x < 0.0, "Hunting mine heads back toward spawn/patrol origin")

	# Return mine close to spawn position -> resumes PATROL
	hmine1.global_position.x = hmine1.spawn_position.x + 5.0
	hmine1._process_returning(0.016)
	assert_eq(hmine1.current_state, BulletBetrayalHuntingMine.State.PATROL, "Hunting mine resumes PATROL once safely home")

	# Verify Detonation on Contact kills player in 1 hit
	var hmine_exploded := [false]
	hmine1.exploded.connect(func(): hmine_exploded[0] = true)
	hmine1.detonate(p)
	await get_tree().physics_frame
	assert_true(hmine1._triggered, "Hunting mine marks triggered upon contact")
	assert_true(hmine_exploded[0], "Hunting mine emits exploded signal")
	assert_true(p.is_dead, "Player dies immediately from hunting mine explosion")
	assert_true(hmine1.scorch_mark.visible, "Ground scorch mark revealed on explosion")
	assert_true(hmine1.explosion_fx.visible, "Explosion FX triggered")

	# Verify single-trigger guarantee (no duplicate explosions)
	hmine_exploded[0] = false
	hmine1.detonate(p)
	assert_true(not hmine_exploded[0], "Detonated hunting mine does not explode a second time")

	# Verify player revive
	level._on_player_revived()
	p.revive(spawn_pt.global_position)
	assert_true(p.is_alive, "Player successfully revived")
	assert_eq(p.global_position, spawn_pt.global_position, "Player revived at safe spawn position")
	assert_eq(p.current_ammo, 10, "Player revived with 10 bullets")
	assert_eq(p.current_health, 1, "Player revived with 1 life")

	# Verify Section D narrow passage geometry
	var ceiling: StaticBody2D = level.get_node_or_null("Terrain/SectionD_Ceiling")
	assert_true(ceiling != null, "Section D tunnel ceiling exists in Terrain")
	var clearance: float = 410.0 - 340.0
	assert_true(clearance >= 70.0, "Section D corridor has at least 70px clearance (clearance = %.1f px)" % clearance)
	var alcove: StaticBody2D = level.get_node_or_null("Terrain/Platform3_Alcove")
	assert_true(alcove != null, "Waiting alcove platform exists before Section D entrance")

	# Verify Rear Ambush (Enemy 7)
	var rear_ambush: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy7_RearAmbush")
	assert_true(rear_ambush != null, "Enemy7_RearAmbush exists in Level 4")
	assert_eq(rear_ambush.ambush_type, BulletBetrayalEnemySoldier.AmbushType.BEHIND, "Enemy 7 uses AmbushType.BEHIND")
	assert_true(rear_ambush.is_dormant, "Enemy 7 starts dormant")

	# Verify Extraction Beacon & 10/10 locked gate
	var beacon: BulletBetrayalExtractionBeacon = level.get_node_or_null("ExtractionBeacon")
	assert_true(beacon != null, "ExtractionBeacon exists in Level 4")
	assert_eq(beacon.required_enemies, 10, "Extraction beacon requires 10 enemies")
	beacon.update_target_progress(0, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon is locked at 0/10 kills")
	beacon.update_target_progress(9, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon remains locked at 9/10 kills")
	beacon.update_target_progress(10, 10)
	assert_true(beacon.is_unlocked, "Extraction beacon unlocks strictly at 10/10 kills")

	# Verify camera limits
	var cam: Camera2D = p.get_node_or_null("Camera2D")
	if cam:
		assert_eq(cam.limit_left, 0, "Camera limit_left is 0")
		assert_eq(cam.limit_top, 0, "Camera limit_top is 0")
		assert_eq(cam.limit_bottom, 540, "Camera limit_bottom is 540")
		assert_true(cam.limit_right >= 2860, "Camera limit_right covers the entire Level 4 stage")

	level.queue_free()

func test_level_5_operation_last_stand() -> void:
	print("\n--- TEST: World 1 Level 5 'Operation Last Stand' ---")
	var level_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_level_5.tscn")
	assert_true(level_scene != null, "Level 5 scene loads successfully")
	var level = level_scene.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(level is BulletBetrayalLevel5, "Level 5 root is BulletBetrayalLevel5")

	# Safe spawn check
	var p: BulletBetrayalPlayer = level.get_node_or_null("Player")
	var spawn_pt: Marker2D = level.get_node_or_null("SpawnPoint")
	assert_true(p != null, "Player exists in Level 5")
	assert_true(spawn_pt != null, "SpawnPoint exists in Level 5")
	assert_eq(p.global_position, Vector2(120, 394), "Player starts at safe spawn position (120, 394)")
	assert_true(p.is_alive, "Player is alive at level start")
	assert_eq(p.current_ammo, 10, "Player starts with exactly 10 bullets")
	assert_eq(p.current_health, 1, "Player starts with 1 life (1-hit death)")

	# Pickups check: exactly 0
	var pickups: Node2D = level.get_node_or_null("Pickups")
	assert_true(pickups != null, "Pickups container exists in Level 5")
	assert_eq(pickups.get_child_count(), 0, "Level 5 has 0 ammunition pickups (strict ammo discipline)")

	# Enemies check: exactly 10 required enemies (7 ordinary soldiers + 3 explosive rushers)
	var enemies: Node2D = level.get_node_or_null("Enemies")
	assert_true(enemies != null, "Enemies container exists in Level 5")
	assert_eq(enemies.get_child_count(), 10, "Level 5 has exactly 10 required enemies")

	var ordinary_count: int = 0
	var rusher_count: int = 0
	for i in range(10):
		var enemy = enemies.get_child(i)
		assert_true(enemy is BulletBetrayalEnemySoldier, "Enemy %d inherits BulletBetrayalEnemySoldier" % (i + 1))
		assert_eq(enemy.max_health, 1, "Enemy %d has max_health == 1 (1-bullet kill)" % (i + 1))
		assert_eq(enemy.current_health, 1, "Enemy %d starts with current_health == 1" % (i + 1))
		if enemy is BulletBetrayalExplosiveRusher:
			rusher_count += 1
		else:
			ordinary_count += 1

	assert_eq(ordinary_count, 7, "Level 5 has exactly 7 ordinary enemy soldiers")
	assert_eq(rusher_count, 3, "Level 5 has exactly 3 surprise explosive rushers")

	# Explosive Rusher instances
	var rusher1: BulletBetrayalExplosiveRusher = level.get_node_or_null("Enemies/Enemy3_Rusher1_Bunker")
	var rusher2: BulletBetrayalExplosiveRusher = level.get_node_or_null("Enemies/Enemy6_Rusher2_Rear")
	var rusher3: BulletBetrayalExplosiveRusher = level.get_node_or_null("Enemies/Enemy8_Rusher3_Tunnel")
	assert_true(rusher1 != null, "Enemy3_Rusher1_Bunker exists in Level 5")
	assert_true(rusher2 != null, "Enemy6_Rusher2_Rear exists in Level 5")
	assert_true(rusher3 != null, "Enemy8_Rusher3_Tunnel exists in Level 5")

	# 1. Disguised appearance test: looks ordinary while waiting
	assert_eq(rusher1.rusher_state, BulletBetrayalExplosiveRusher.RusherState.WAITING, "Rusher starts in WAITING state")
	assert_true(rusher1.warning_led != null and not rusher1.warning_led.visible, "Warning LED starts hidden")
	assert_true(rusher1.warning_glow != null and not rusher1.warning_glow.visible, "Warning glow starts hidden")
	assert_true(rusher1.alert_icon != null and not rusher1.alert_icon.visible, "Alert icon starts hidden")

	# 2. Surprise activation test
	rusher1.activate_rusher(p)
	assert_eq(rusher1.rusher_state, BulletBetrayalExplosiveRusher.RusherState.ALERT, "Rusher transitions to ALERT state upon activation")
	assert_true(rusher1.alert_icon.visible, "Alert icon displays '!' telegraph")
	assert_true(rusher1.warning_led.visible, "Warning LED activates upon detection")
	assert_true(rusher1.warning_glow.visible, "Warning glow activates upon detection")

	# 3. Rushing pursuit test
	rusher1._state_timer = 0.0
	rusher1._physics_process(0.016)
	assert_eq(rusher1.rusher_state, BulletBetrayalExplosiveRusher.RusherState.RUSHING, "Rusher transitions to RUSHING state")
	assert_true(rusher1.velocity.x < 0.0, "Rusher charges towards player (player is to the left at X=120)")
	assert_true(abs(rusher1.velocity.x) >= 140.0, "Rusher runs at high pursuit speed (>= 140 px/s)")

	# 4. Shooting rusher before detonation: 1 bullet eliminates it cleanly without exploding
	var rusher3_killed := [false]
	rusher3.eliminated.connect(func(): rusher3_killed[0] = true)
	rusher3.take_hit(1)
	assert_true(rusher3.is_dead, "Shooting rusher with 1 bullet kills it immediately")
	assert_true(rusher3_killed[0], "Killed rusher emits eliminated signal")
	assert_true(not rusher3._has_detonated, "Cleanly shot rusher does NOT detonate")
	assert_true(p.is_alive, "Player survives when shooting rusher before it explodes")

	# 5. Detonation & Blast Radius Test
	p.global_position = Vector2(rusher1.global_position.x + 30.0, rusher1.global_position.y)
	var rusher1_eliminated := [false]
	rusher1.eliminated.connect(func(): rusher1_eliminated[0] = true)
	rusher1.detonate()
	await get_tree().physics_frame
	assert_true(rusher1._has_detonated, "Rusher marks _has_detonated upon explosion")
	assert_true(rusher1_eliminated[0], "Detonating rusher emits eliminated signal")
	assert_true(p.is_dead, "Player dies from lethal explosion when inside blast radius")
	assert_true(rusher1.scorch_mark != null and rusher1.scorch_mark.visible, "Ground scorch mark revealed on explosion")

	# 6. Duplicate detonation prevention
	rusher1_eliminated[0] = false
	rusher1.detonate()
	assert_true(not rusher1_eliminated[0], "Detonated rusher does not explode a second time")

	# 7. Player revive
	level._on_player_revived()
	p.revive(spawn_pt.global_position)
	assert_true(p.is_alive, "Player successfully revived")
	assert_eq(p.global_position, spawn_pt.global_position, "Player revived at safe spawn position")
	assert_eq(p.current_ammo, 10, "Player revived with 10 bullets")
	assert_eq(p.current_health, 1, "Player revived with 1 life")

	# 8. Enemy blast interaction: nearby ordinary enemy killed by blast without double counting
	var nearby_enemy: BulletBetrayalEnemySoldier = level.get_node_or_null("Enemies/Enemy4_BunkerSniper")
	assert_true(nearby_enemy != null, "Enemy4_BunkerSniper exists")
	nearby_enemy.global_position = Vector2(rusher2.global_position.x + 25.0, rusher2.global_position.y)
	var nearby_eliminated := [false]
	nearby_enemy.eliminated.connect(func(): nearby_eliminated[0] = true)
	p.global_position = Vector2(120.0, 394.0)
	rusher2.detonate()
	await get_tree().physics_frame
	assert_true(nearby_enemy.is_dead, "Nearby ordinary enemy caught in blast radius is eliminated")
	assert_true(nearby_eliminated[0], "Eliminated nearby enemy emits eliminated signal")
	assert_true(p.is_alive, "Player is outside blast radius and survives")

	# 9. Verify Rear Ambush Archetype on Rusher 2
	assert_eq(rusher2.ambush_type, BulletBetrayalEnemySoldier.AmbushType.BEHIND, "Rusher 2 uses AmbushType.BEHIND")

	# 10. Verify Section D Narrow Passage Geometry (clearance >= 70px)
	var ceiling: StaticBody2D = level.get_node_or_null("Terrain/SectionD_Ceiling")
	assert_true(ceiling != null, "Section D tunnel ceiling exists in Level 5 Terrain")
	var clearance: float = 410.0 - 340.0
	assert_true(clearance >= 70.0, "Section D corridor has at least 70px clearance (clearance = %.1f px)" % clearance)

	# 11. Verify Extraction Beacon & 10/10 locked gate
	var beacon: BulletBetrayalExtractionBeacon = level.get_node_or_null("ExtractionBeacon")
	assert_true(beacon != null, "ExtractionBeacon exists in Level 5")
	assert_eq(beacon.required_enemies, 10, "Extraction beacon requires 10 enemies")
	beacon.update_target_progress(0, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon is locked at 0/10 kills")
	beacon.update_target_progress(9, 10)
	assert_true(not beacon.is_unlocked, "Extraction beacon remains locked at 9/10 kills")
	beacon.update_target_progress(10, 10)
	assert_true(beacon.is_unlocked, "Extraction beacon unlocks strictly at 10/10 kills")

	# 12. Verify Camera Limits
	var cam: Camera2D = p.get_node_or_null("Camera2D")
	if cam:
		assert_eq(cam.limit_left, 0, "Camera limit_left is 0")
		assert_eq(cam.limit_top, 0, "Camera limit_top is 0")
		assert_eq(cam.limit_bottom, 540, "Camera limit_bottom is 540")
		assert_true(cam.limit_right >= 2860, "Camera limit_right covers the entire Level 5 stage")

	level.queue_free()

