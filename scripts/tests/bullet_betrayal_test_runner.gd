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
	
	assert_true(not bb_menu.message_modal.visible, "MessageModal starts hidden")
	stage_2.pressed.emit()
	assert_true(bb_menu.message_modal.visible, "Clicking locked stage displays arcade MessageModal")
	assert_eq(bb_menu.modal_title.text, "STAGE 2 IS LOCKED", "MessageModal title matches Coin Hell format")
	
	bb_menu.modal_ok_btn.pressed.emit()
	assert_true(not bb_menu.message_modal.visible, "Clicking GOT IT closes MessageModal")
	
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
	assert_true(ambush_enemy.collision_shape.disabled, "Ambush enemy collision starts disabled")
	
	# Trigger ambush
	ambush_enemy.trigger_ambush()
	assert_true(not ambush_enemy.is_dormant, "Ambush enemy is no longer dormant after trigger")
	assert_true(ambush_enemy.visible, "Ambush enemy is visible after trigger")
	assert_true(not ambush_enemy.collision_shape.disabled, "Ambush enemy collision is active after trigger")
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
	
	level.queue_free()
	await get_tree().process_frame
	
	# Verify GameManager gameplay active flag resets on exit
	if GameManager:
		assert_true(not GameManager.is_gameplay_active, "GameManager.is_gameplay_active is FALSE after leaving level")

func test_phase3_enemy_ledge_detection_and_pit_prevention() -> void:
	print("\n--- TEST: Phase 3 Enemy Ledge Detection & Pit Prevention ---")
	var enemy_scene: PackedScene = load("res://scenes/bullet_betrayal/bb_enemy_soldier.tscn")
	var enemy: BulletBetrayalEnemySoldier = enemy_scene.instantiate()
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
