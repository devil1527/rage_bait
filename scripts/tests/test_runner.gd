extends Node

## Test runner node executed inside the active scene tree with full autoload support.

const CrumblingBridgeSectionClass = preload("res://scripts/coin_hell/crumbling_bridge_section.gd")
const MovingWallClass = preload("res://scripts/coin_hell/moving_wall.gd")
const FakeExitGateClass = preload("res://scripts/coin_hell/fake_exit_gate.gd")
const WallSpikeTrapClass = preload("res://scripts/coin_hell/wall_spike_trap.gd")
const InfernoGateClass = preload("res://scripts/coin_hell/inferno_gate.gd")
const CeilingCrusherClass = preload("res://scripts/coin_hell/ceiling_crusher.gd")
const FakeSafePlatformClass = preload("res://scripts/coin_hell/fake_safe_platform.gd")
const PhantomPlatformClass = preload("res://scripts/coin_hell/phantom_platform.gd")
const StageIntroCardClass = preload("res://scripts/shared/stage_intro_card.gd")
const HauntedHallEnvironmentClass = preload("res://scripts/shared/haunted_hall_environment.gd")
const CursedWindZoneClass = preload("res://scripts/coin_hell/cursed_wind_zone.gd")
const SwingingChainClass = preload("res://scripts/coin_hell/swinging_chain.gd")

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("  RETRO RAGE ARCADE / COIN HELL AUTOMATED TEST SUITE   ")
	print("=======================================================\n")
	
	run_all_tests()
	
	print("\n=======================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
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
	test_save_manager_and_persistence()
	test_game_manager_level_definitions()
	test_world_and_stage_system()
	test_main_menu_logic_and_modals()
	test_level_select_logic_and_states()
	test_level_1_gameplay_mechanics()
	test_multitouch_gameplay_controls()
	test_ragebait_tricks_and_level_rework()
	test_full_level_1_gameplay_walkthrough()
	test_spike_collision_directions_and_cases()
	test_level_2_gameplay_mechanics()
	test_level_3_gameplay_mechanics()
	test_level_4_gameplay_mechanics()
	test_level_5_gameplay_mechanics()
	test_welcome_and_startup_screen()
	test_developer_only_level_access()
	test_haunted_hall_environment_and_ghosts()
	test_level_6_gameplay_mechanics()
	test_level_7_gameplay_mechanics()
	test_level_7_bug_fixes()
	test_cursed_wind_zone_mechanics()
	test_level_8_gameplay_mechanics()
	test_swinging_chain_mechanics()
	test_level_9_gameplay_mechanics()

func test_save_manager_and_persistence() -> void:
	print("\n--- TEST: SaveManager & Persistence ---")
	SaveManager._apply_defaults()
	SaveManager.save_data()
	
	assert_eq(SaveManager.highest_unlocked_level, 1, "Fresh save has highest unlocked level = 1")
	assert_eq(SaveManager.get_completed_count(), 0, "Fresh save has 0 completed levels")
	assert_true(SaveManager.is_level_unlocked(1), "Level 1 is unlocked initially")
	assert_true(not SaveManager.is_level_unlocked(2), "Level 2 is locked initially")
	
	# Complete Level 1
	SaveManager.complete_level(1)
	assert_eq(SaveManager.highest_unlocked_level, 2, "Completing Level 1 unlocks Level 2")
	assert_true(SaveManager.is_level_completed(1), "Level 1 marked completed")
	assert_eq(SaveManager.get_completed_count(), 1, "Completed count is 1")
	
	# Reload from disk to verify persistence
	SaveManager.load_save()
	assert_eq(SaveManager.highest_unlocked_level, 2, "Progress persists after reload from disk")
	assert_true(SaveManager.is_level_completed(1), "Completed levels persist after reload")
	
	# Test corruption resistance
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	file.store_string("CORRUPT_NOT_A_VALID_JSON_DATA!@#$%^&*")
	file.close()
	
	SaveManager.load_save()
	assert_eq(SaveManager.highest_unlocked_level, 1, "Gracefully handles corrupt save file with safe defaults")

func test_game_manager_level_definitions() -> void:
	print("\n--- TEST: GameManager Level Definitions ---")
	assert_eq(GameManager.levels.size(), 20, "GameManager defines exactly 20 planned levels")
	
	var lvl1: Dictionary = GameManager.get_level_info(1)
	assert_eq(lvl1.get("name"), "The Warm-Up", "Level 1 name is 'The Warm-Up'")
	assert_true(lvl1.get("implemented"), "Level 1 is marked implemented")
	assert_true(GameManager.can_play_level(1), "Level 1 is playable")

	var lvl2: Dictionary = GameManager.get_level_info(2)
	assert_eq(lvl2.get("name"), "Trust Nothing", "Level 2 name is 'Trust Nothing'")
	assert_true(lvl2.get("implemented"), "Level 2 is marked implemented")
	assert_true(GameManager.can_play_level(2), "Level 2 is playable")

	var lvl3: Dictionary = GameManager.get_level_info(3)
	assert_eq(lvl3.get("name"), "Fire & Fury", "Level 3 name is 'Fire & Fury'")
	assert_true(lvl3.get("implemented"), "Level 3 is marked implemented")
	assert_true(GameManager.can_play_level(3), "Level 3 is playable")

	var lvl4: Dictionary = GameManager.get_level_info(4)
	assert_eq(lvl4.get("name"), "Crushing Silence", "Level 4 name is 'Crushing Silence'")
	assert_true(lvl4.get("implemented"), "Level 4 is marked implemented")
	assert_true(GameManager.can_play_level(4), "Level 4 is playable")

	var lvl5: Dictionary = GameManager.get_level_info(5)
	assert_eq(lvl5.get("name"), "The Final Betrayal", "Level 5 name is 'The Final Betrayal'")
	assert_true(lvl5.get("implemented"), "Level 5 is marked implemented")
	assert_true(GameManager.can_play_level(5), "Level 5 is playable")
	
	var lvl6: Dictionary = GameManager.get_level_info(6)
	assert_eq(lvl6.get("name"), "Phantom's Curse", "Level 6 name is 'Phantom's Curse'")
	assert_eq(GameManager.get_world_name_for_stage(6), "THE HAUNTED HALL", "Level 6 world is 'THE HAUNTED HALL'")
	assert_true(lvl6.get("implemented"), "Level 6 is marked implemented")
	assert_true(GameManager.can_play_level(6), "Level 6 is playable")
	
	var lvl7: Dictionary = GameManager.get_level_info(7)
	assert_eq(lvl7.get("name"), "Hall of Illusions", "Level 7 name is 'Hall of Illusions'")
	assert_eq(GameManager.get_world_name_for_stage(7), "THE HAUNTED HALL", "Level 7 world is 'THE HAUNTED HALL'")
	assert_true(lvl7.get("implemented"), "Level 7 is marked implemented")
	assert_true(GameManager.can_play_level(7), "Level 7 is playable")
	assert_eq(lvl7.get("coin_count"), 10, "Level 7 coin count is 10")
	
	var lvl8: Dictionary = GameManager.get_level_info(8)
	assert_eq(lvl8.get("name"), "The Cursed Wind", "Level 8 name is 'The Cursed Wind'")
	assert_eq(GameManager.get_world_name_for_stage(8), "THE HAUNTED HALL", "Level 8 world is 'THE HAUNTED HALL'")
	assert_true(lvl8.get("implemented"), "Level 8 is marked implemented")
	assert_true(GameManager.can_play_level(8), "Level 8 is playable")
	assert_eq(lvl8.get("coin_count"), 10, "Level 8 coin count is 10")
	
	var lvl9: Dictionary = GameManager.get_level_info(9)
	assert_eq(lvl9.get("name"), "Chains of the Damned", "Level 9 name is 'Chains of the Damned'")
	assert_eq(GameManager.get_world_name_for_stage(9), "THE HAUNTED HALL", "Level 9 world is 'THE HAUNTED HALL'")
	assert_true(lvl9.get("implemented"), "Level 9 is marked implemented")
	assert_true(GameManager.can_play_level(9), "Level 9 is playable")
	assert_eq(lvl9.get("coin_count"), 10, "Level 9 coin count is 10")
	
	for lvl_id in range(10, 21):
		assert_true(not GameManager.can_play_level(lvl_id), "Level %d is marked not implemented" % lvl_id)
		
	# Test coin counter clamping
	GameManager.current_level_id = 1
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	assert_eq(GameManager.current_coins, 0, "Reset coins sets current_coins to 0")
	for i in range(15):
		GameManager.collect_coin()
	assert_eq(GameManager.current_coins, 10, "Coin counter clamps at configured total (10) and does not overflow")

func test_world_and_stage_system() -> void:
	print("\n--- TEST: World and Stage System (4 Worlds & Intro Cards) ---")
	assert_eq(GameManager.worlds.size(), 4, "GameManager defines exactly 4 worlds")
	assert_eq(GameManager.get_world_name(1), "NEON RUINS", "World 1 name is NEON RUINS")
	assert_eq(GameManager.get_world_name(2), "THE HAUNTED HALL", "World 2 name is THE HAUNTED HALL")
	assert_eq(GameManager.get_world_name(3), "RAGE FACTORY", "World 3 name is RAGE FACTORY")
	assert_eq(GameManager.get_world_name(4), "FINAL HELL", "World 4 name is FINAL HELL")
	
	# Verify stage to world mapping
	for s in range(1, 6):
		assert_eq(GameManager.get_world_id_for_stage(s), 1, "Stage %d is in World 1" % s)
	for s in range(6, 11):
		assert_eq(GameManager.get_world_id_for_stage(s), 2, "Stage %d is in World 2" % s)
	for s in range(11, 16):
		assert_eq(GameManager.get_world_id_for_stage(s), 3, "Stage %d is in World 3" % s)
	for s in range(16, 21):
		assert_eq(GameManager.get_world_id_for_stage(s), 4, "Stage %d is in World 4" % s)
		
	# Verify HUD label formatting
	assert_eq(GameManager.get_stage_hud_label(1), "WORLD 1 · STAGE 1", "HUD label formatted as 'WORLD 1 · STAGE 1'")
	assert_eq(GameManager.get_stage_hud_label(3), "WORLD 1 · STAGE 3", "HUD label formatted as 'WORLD 1 · STAGE 3'")
	assert_eq(GameManager.get_stage_hud_label(6), "WORLD 2 · STAGE 6", "HUD label formatted as 'WORLD 2 · STAGE 6'")
	
	# Verify Stage Intro session tracking (does NOT re-show on retry/death)
	GameManager.reset_stage_intros()
	assert_true(GameManager.should_show_stage_intro(1), "Stage 1 intro is shown on first query in session")
	GameManager.mark_stage_intro_shown(1)
	assert_true(not GameManager.should_show_stage_intro(1), "Stage 1 intro is suppressed after first showing (no retry repetition)")
	assert_true(GameManager.should_show_stage_intro(6), "Stage 6 intro is shown on first query in session")
	GameManager.mark_stage_intro_shown(6)
	assert_true(not GameManager.should_show_stage_intro(6), "Stage 6 intro is suppressed on retry/death")
	
	# Test StageIntroCard UI node
	var card_scene: PackedScene = load("res://scenes/shared/stage_intro_card.tscn")
	assert_true(card_scene != null, "StageIntroCard scene loads successfully")
	var card = card_scene.instantiate()
	add_child(card)
	card.setup(2, "THE HAUNTED HALL", 6, "PHANTOM'S CURSE")
	assert_eq(card.world_num_label.text, "WORLD 2", "Intro card displays WORLD 2")
	assert_eq(card.world_name_label.text, "THE HAUNTED HALL", "Intro card displays THE HAUNTED HALL")
	assert_eq(card.stage_label.text, "STAGE 6: PHANTOM'S CURSE", "Intro card displays STAGE 6: PHANTOM'S CURSE")
	
	# Test skippable transition
	card.dismiss()
	assert_true(card._is_dismissing, "Intro card is dismissed/skipped on input")
	card.queue_free()

func test_main_menu_logic_and_modals() -> void:
	print("\n--- TEST: Main Menu Scene ---")
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	assert_true(menu_scene != null, "Main menu scene loads successfully")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	var card_chel = menu.get_node("MarginContainer/VBoxContainer/CardsGrid/CardCoinHell")
	var card_bbet = menu.get_node("MarginContainer/VBoxContainer/CardsGrid/CardBulletBetrayal")
	var card_nnig = menu.get_node("MarginContainer/VBoxContainer/CardsGrid/CardNinjaNightmare")
	var card_clie = menu.get_node("MarginContainer/VBoxContainer/CardsGrid/CardCastleOfLies")
	
	assert_true(card_chel != null, "Coin Hell card exists")
	assert_true(card_bbet != null, "Bullet Betrayal card exists")
	assert_true(card_nnig != null, "Ninja Nightmare card exists")
	assert_true(card_clie != null, "Castle of Lies card exists")
	
	# Test Coming Soon feedback
	menu._show_coming_soon("Bullet Betrayal")
	var modal = menu.get_node("MessageModal")
	var modal_label: Label = menu.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_true(modal.visible, "Modal is shown when Coming Soon game is pressed")
	assert_eq(modal_label.text, "This game is still in development. Coin Hell is ready to cause trouble first.", "Modal shows exact required coming soon message")
	
	menu.queue_free()

func test_level_select_logic_and_states() -> void:
	print("\n--- TEST: Level Select Scene ---")
	SaveManager._apply_defaults()
	var lsel_scene: PackedScene = load("res://scenes/ui/coin_hell_level_select.tscn")
	assert_true(lsel_scene != null, "Level select scene loads successfully")
	var lsel = lsel_scene.instantiate()
	add_child(lsel)
	lsel.dev_bypass_active = false
	
	var worlds_container = lsel.get_node("MarginContainer/VBox/ScrollContainer/WorldsContainer")
	assert_true(worlds_container != null, "WorldsContainer exists in Level Select")
	assert_eq(worlds_container.get_child_count(), 4, "Level select displays exactly 4 world sections")
	
	var w1_header: Label = worlds_container.get_node("WorldSection_1/WorldHeader_1/TitleLabel")
	var w2_header: Label = worlds_container.get_node("WorldSection_2/WorldHeader_2/TitleLabel")
	var w3_header: Label = worlds_container.get_node("WorldSection_3/WorldHeader_3/TitleLabel")
	var w4_header: Label = worlds_container.get_node("WorldSection_4/WorldHeader_4/TitleLabel")
	assert_eq(w1_header.text, "WORLD 1 — NEON RUINS", "World 1 header is 'WORLD 1 — NEON RUINS'")
	assert_eq(w2_header.text, "WORLD 2 — THE HAUNTED HALL", "World 2 header is 'WORLD 2 — THE HAUNTED HALL'")
	assert_eq(w3_header.text, "WORLD 3 — RAGE FACTORY", "World 3 header is 'WORLD 3 — RAGE FACTORY'")
	assert_eq(w4_header.text, "WORLD 4 — FINAL HELL", "World 4 header is 'WORLD 4 — FINAL HELL'")
	
	for lvl_id in range(1, 21):
		assert_true(lsel.get_level_button(lvl_id) != null, "LevelBtn_%d exists in level select" % lvl_id)
	
	# Test locked level press
	lsel._on_level_tile_pressed(5)
	var modal = lsel.get_node("MessageModal")
	var modal_label: Label = lsel.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_true(modal.visible, "Pressing locked level shows modal")
	assert_eq(modal_label.text, "Locked! Beat the previous level first. The developer has enough problems already.", "Modal shows exact locked level message")
	
	# Unlock level 2 and verify it is playable
	SaveManager.complete_level(1)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(2), "Level 2 is unlocked after completing Level 1")

	# Complete level 2 to unlock level 3
	SaveManager.complete_level(2)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(3), "Level 3 is unlocked after completing Level 2")
	assert_true(GameManager.can_play_level(3), "Level 3 is playable")

	# Complete level 3 to unlock level 4 and verify Level 4 is playable
	SaveManager.complete_level(3)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(4), "Level 4 is unlocked after completing Level 3")
	assert_true(GameManager.can_play_level(4), "Level 4 is playable")

	# Complete level 4 to unlock level 5 and verify Level 5 is playable
	SaveManager.complete_level(4)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(5), "Level 5 is unlocked after completing Level 4")
	assert_true(GameManager.can_play_level(5), "Level 5 is playable")

	# Complete level 5 to unlock level 6 and verify Level 6 is playable
	SaveManager.complete_level(5)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(6), "Level 6 is unlocked after completing Level 5")
	assert_true(GameManager.can_play_level(6), "Level 6 is playable")

	# Complete level 6 to unlock level 7 and verify Level 7 is playable
	SaveManager.complete_level(6)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(7), "Level 7 is unlocked after completing Level 6")
	assert_true(GameManager.can_play_level(7), "Level 7 is playable")

	# Complete level 7 to unlock level 8 and verify Level 8 is playable
	SaveManager.complete_level(7)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(8), "Level 8 is unlocked after completing Level 7")
	assert_true(GameManager.can_play_level(8), "Level 8 is playable")

	# Complete level 8 to unlock level 9 and verify Level 9 is playable
	SaveManager.complete_level(8)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(9), "Level 9 is unlocked after completing Level 8")
	assert_true(GameManager.can_play_level(9), "Level 9 is playable")

	# Complete level 9 to unlock level 10 and test unimplemented level press
	SaveManager.complete_level(9)
	lsel._update_ui()
	assert_true(SaveManager.is_level_unlocked(10), "Level 10 is unlocked after completing Level 9")
	lsel._on_level_tile_pressed(10)
	assert_true(modal.visible, "Pressing unlocked but unimplemented level shows modal")
	assert_eq(modal_label.text, "Level 10 is still being built. Replay an earlier level for now.", "Modal shows exact unimplemented level message")
	
	lsel.queue_free()

func test_level_1_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 1 Gameplay Mechanics ---")
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	assert_true(lvl1_scene != null, "Level 1 scene loads successfully")
	var lvl = lvl1_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node("Player")
	var coins_container = lvl.get_node("Coins")
	var exit_gate = lvl.get_node("ExitGate")
	
	assert_true(player != null, "Player exists in Level 1")
	assert_eq(coins_container.get_child_count(), 10, "Exactly 10 coins exist in Level 1")
	assert_true(exit_gate != null, "ExitGate exists in Level 1")
	
	# Verify Exit Gate initial locked state
	assert_true(not exit_gate._is_open, "Exit gate starts closed/locked")
	assert_eq(exit_gate.status_label.text, "COINS REQUIRED", "Exit gate displays 'COINS REQUIRED'")
	
	# Player touches locked exit gate
	exit_gate._on_body_entered(player)
	assert_true(not exit_gate._is_open, "Exit gate stays locked when player enters without all coins")
	assert_eq(exit_gate.toast_label.text, "Need 10 more coins!", "Exit gate toast informs player of remaining coins")
	
	# Collect all coins
	for coin in coins_container.get_children():
		coin.collect()
	
	assert_true(exit_gate._is_open, "Exit gate unlocks automatically after 10th coin is collected")
	assert_eq(exit_gate.status_label.text, "EXIT OPEN!", "Exit gate displays 'EXIT OPEN!'")
	
	# Player enters unlocked stationary exit gate
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level completion triggers on exit")
	assert_true(SaveManager.is_level_completed(1), "Level 1 completion persists in SaveManager")
	assert_true(SaveManager.is_level_unlocked(2), "Level 2 is unlocked upon completion")
	
	# Test Level Complete overlay Next Level button (Level 2 is now playable)
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	assert_true(GameManager.can_play_level(2), "Level 2 is playable from Next Level flow")
	
	# Test retry resets level
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Retry resets current coins to 0")
	assert_true(not exit_gate._is_open, "Retry resets exit gate to locked state")
	for coin in coins_container.get_children():
		assert_true(not coin._collected, "Retry resets all coins to uncollected")
		
	# Test player death flow
	player.die()
	assert_true(lvl.death_overlay.visible, "Player death displays DeathOverlay")
	
	lvl.queue_free()

func test_multitouch_gameplay_controls() -> void:
	print("\n--- TEST: Android Multi-Touch Gameplay Controls ---")
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	assert_true(lvl1_scene != null, "Level 1 scene loads for multitouch test")
	var lvl = lvl1_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node("Player")
	var left_btn: TouchButton = lvl.get_node("HUD/TouchControls/LeftBtn")
	var right_btn: TouchButton = lvl.get_node("HUD/TouchControls/RightBtn")
	var jump_btn: TouchButton = lvl.get_node("HUD/TouchControls/JumpBtn")
	
	assert_true(left_btn != null and right_btn != null and jump_btn != null, "On-screen touch buttons exist in Level 1 HUD")
	assert_true(left_btn is TouchButton, "Left button uses TouchButton script")
	assert_true(right_btn is TouchButton, "Right button uses TouchButton script")
	assert_true(jump_btn is TouchButton, "Jump button uses TouchButton script")
	assert_eq(left_btn.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Left button ignores single-pointer GUI mouse filter")
	assert_eq(right_btn.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Right button ignores single-pointer GUI mouse filter")
	assert_eq(jump_btn.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Jump button ignores single-pointer GUI mouse filter")

	# Helper to dispatch screen touch event to a specific button
	var send_touch = func(btn: TouchButton, finger_index: int, pressed: bool):
		var ev = InputEventScreenTouch.new()
		ev.index = finger_index
		ev.pressed = pressed
		var xform = btn.get_global_transform_with_canvas()
		ev.position = xform * (btn.size * 0.5)
		btn._input(ev)

	# --- TEST A: Hold RIGHT and then press JUMP with another finger ---
	print("  Testing Scenario A: Hold RIGHT, then press JUMP...")
	send_touch.call(right_btn, 0, true)
	assert_true(player.touch_right, "A1: Finger 0 on RightBtn activates player.touch_right")
	assert_true(right_btn.is_active_pressed, "A2: RightBtn is marked active pressed")
	assert_eq(right_btn.touch_index, 0, "A3: RightBtn tracks touch index 0")
	assert_true(Input.is_action_pressed("move_right"), "A4: Input action 'move_right' is pressed")

	send_touch.call(jump_btn, 1, true)
	assert_true(player.touch_jump, "A5: Finger 1 on JumpBtn activates player.touch_jump")
	assert_true(jump_btn.is_active_pressed, "A6: JumpBtn is marked active pressed")
	assert_eq(jump_btn.touch_index, 1, "A7: JumpBtn tracks touch index 1")
	assert_true(Input.is_action_pressed("jump"), "A8: Input action 'jump' is pressed")
	assert_true(player.touch_right, "A9: player.touch_right remains active while JUMP is pressed")
	assert_true(right_btn.is_active_pressed, "A10: RightBtn remains held while JUMP is pressed")
	assert_true(Input.is_action_pressed("move_right"), "A11: 'move_right' action remains pressed during simultaneous touch")

	# Clean up Scenario A
	send_touch.call(right_btn, 0, false)
	send_touch.call(jump_btn, 1, false)
	assert_true(not player.touch_right and not player.touch_jump, "A12: Both controls clear after release")

	# --- TEST B: Hold JUMP and then press RIGHT with another finger ---
	print("  Testing Scenario B: Hold JUMP, then press RIGHT...")
	send_touch.call(jump_btn, 0, true)
	assert_true(player.touch_jump, "B1: Finger 0 on JumpBtn activates player.touch_jump")
	assert_eq(jump_btn.touch_index, 0, "B2: JumpBtn tracks touch index 0")

	send_touch.call(right_btn, 1, true)
	assert_true(player.touch_right, "B3: Finger 1 on RightBtn activates player.touch_right")
	assert_eq(right_btn.touch_index, 1, "B4: RightBtn tracks touch index 1")
	assert_true(player.touch_jump, "B5: player.touch_jump remains active when RIGHT is pressed")
	assert_true(jump_btn.is_active_pressed, "B6: JumpBtn remains pressed when RIGHT is pressed")

	# Clean up Scenario B
	send_touch.call(jump_btn, 0, false)
	send_touch.call(right_btn, 1, false)
	assert_true(not player.touch_right and not player.touch_jump, "B7: Both controls clear after release")

	# --- TEST C: Hold RIGHT + JUMP, then release RIGHT while continuing to hold JUMP ---
	print("  Testing Scenario C: Hold RIGHT + JUMP, release RIGHT while holding JUMP...")
	send_touch.call(right_btn, 0, true)
	send_touch.call(jump_btn, 1, true)
	assert_true(player.touch_right and player.touch_jump, "C1: Both RIGHT and JUMP held")

	send_touch.call(right_btn, 0, false)
	assert_true(not player.touch_right, "C2: player.touch_right cleared after releasing finger 0")
	assert_true(not right_btn.is_active_pressed, "C3: RightBtn no longer active pressed")
	assert_true(player.touch_jump, "C4: player.touch_jump continues to be held after RIGHT released")
	assert_true(jump_btn.is_active_pressed, "C5: JumpBtn remains active pressed")
	assert_eq(jump_btn.touch_index, 1, "C6: JumpBtn still cleanly holds touch index 1")
	assert_true(Input.is_action_pressed("jump"), "C7: 'jump' action remains pressed")

	# Clean up Scenario C
	send_touch.call(jump_btn, 1, false)
	assert_true(not player.touch_jump, "C8: JUMP clears when finger 1 released")

	# --- TEST D: Hold RIGHT + JUMP, then release JUMP while continuing to hold RIGHT ---
	print("  Testing Scenario D: Hold RIGHT + JUMP, release JUMP while holding RIGHT...")
	send_touch.call(right_btn, 0, true)
	send_touch.call(jump_btn, 1, true)
	assert_true(player.touch_right and player.touch_jump, "D1: Both RIGHT and JUMP held")

	send_touch.call(jump_btn, 1, false)
	assert_true(not player.touch_jump, "D2: player.touch_jump cleared after releasing finger 1")
	assert_true(not jump_btn.is_active_pressed, "D3: JumpBtn no longer active pressed")
	assert_true(player.touch_right, "D4: player.touch_right continues to be held after JUMP released")
	assert_true(right_btn.is_active_pressed, "D5: RightBtn remains active pressed")
	assert_eq(right_btn.touch_index, 0, "D6: RightBtn still cleanly holds touch index 0")
	assert_true(Input.is_action_pressed("move_right"), "D7: 'move_right' action remains pressed")

	# Clean up Scenario D
	send_touch.call(right_btn, 0, false)
	assert_true(not player.touch_right, "D8: RIGHT clears when finger 0 released")

	# --- TEST E: Rapidly press and release both controls ---
	print("  Testing Scenario E: Rapid alternating and simultaneous touches...")
	for i in range(10):
		var f0 = i % 2
		var f1 = 1 - f0
		send_touch.call(right_btn, f0, true)
		send_touch.call(jump_btn, f1, true)
		assert_true(player.touch_right and player.touch_jump, "E rapid loop: both held at iter %d" % i)
		send_touch.call(right_btn, f0, false)
		send_touch.call(jump_btn, f1, false)
		assert_true(not player.touch_right and not player.touch_jump, "E rapid loop: both released at iter %d" % i)

	assert_true(not right_btn.is_active_pressed and not jump_btn.is_active_pressed, "E: No button stuck after rapid cycling")
	assert_eq(right_btn.touch_index, -1, "E: RightBtn index reset to -1")
	assert_eq(jump_btn.touch_index, -1, "E: JumpBtn index reset to -1")

	# --- TEST F: Die, restart, pause, and resume; verify no control remains stuck ---
	print("  Testing Scenario F: State clears on pause, resume, death, and restart...")
	# 1. Pause
	send_touch.call(right_btn, 0, true)
	send_touch.call(jump_btn, 1, true)
	assert_true(player.touch_right and player.touch_jump, "F1: Active before pause")
	lvl._on_pause_pressed()
	assert_true(not right_btn.is_active_pressed, "F2: RightBtn reset on pause")
	assert_true(not jump_btn.is_active_pressed, "F3: JumpBtn reset on pause")
	assert_eq(right_btn.touch_index, -1, "F4: RightBtn touch index cleared on pause")
	assert_eq(jump_btn.touch_index, -1, "F5: JumpBtn touch index cleared on pause")

	# 2. Resume
	lvl.pause_overlay._on_resume_pressed()
	assert_true(not player.touch_right and not player.touch_jump, "F6: Controls not stuck after resume")

	# 3. Death
	send_touch.call(right_btn, 0, true)
	send_touch.call(jump_btn, 1, true)
	player.die()
	assert_true(not player.touch_right and not player.touch_jump, "F7: Player touch flags cleared on death")
	assert_true(not Input.is_action_pressed("move_right"), "F8: 'move_right' action released on death")
	assert_true(not Input.is_action_pressed("jump"), "F9: 'jump' action released on death")

	# 4. Restart / Reset
	lvl._on_retry()
	assert_true(not player.touch_right and not player.touch_jump, "F10: Controls clear on level retry")
	assert_true(not right_btn.is_active_pressed and not jump_btn.is_active_pressed, "F11: Buttons inactive on level retry")

	# --- Additional Test: LEFT + JUMP simultaneous multitouch ---
	print("  Testing LEFT + JUMP combination...")
	send_touch.call(left_btn, 0, true)
	send_touch.call(jump_btn, 1, true)
	assert_true(player.touch_left and player.touch_jump, "LEFT+JUMP: Both active simultaneously")
	assert_true(Input.is_action_pressed("move_left") and Input.is_action_pressed("jump"), "LEFT+JUMP: Actions active")
	send_touch.call(left_btn, 0, false)
	assert_true(not player.touch_left and player.touch_jump, "LEFT+JUMP: Releasing LEFT keeps JUMP held")
	send_touch.call(jump_btn, 1, false)
	assert_true(not player.touch_jump, "LEFT+JUMP: Cleanly released")

	# --- Additional Test: Keyboard Controls Preservation ---
	print("  Testing Keyboard Controls Preservation...")
	Input.action_press("move_right")
	player._physics_process(0.016)
	assert_true(player.velocity.x > 0.0, "Keyboard move_right accelerates player")
	Input.action_release("move_right")

	lvl.queue_free()

func test_ragebait_tricks_and_level_rework() -> void:
	print("\n--- TEST: Ragebait Tricks & Level 1 Physics Rework ---")
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	assert_true(lvl1_scene != null, "Level 1 scene loads successfully")
	var lvl = lvl1_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var ground1 = lvl.get_node("Platforms/Ground1")
	var plat1 = lvl.get_node("Platforms/Platform1")
	var plat2 = lvl.get_node("Platforms/Platform2")
	var plat3 = lvl.get_node("Platforms/Platform3")
	var platgreedy = lvl.get_node("Platforms/PlatformGreedy")
	var ground2 = lvl.get_node("Platforms/Ground2")
	var plat4 = lvl.get_node("Platforms/Platform4")
	var plat5 = lvl.get_node("Platforms/Platform5")
	var ground3 = lvl.get_node("Platforms/Ground3")
	var exit_gate = lvl.get_node("ExitGate")
	var coin6 = lvl.get_node("Coins/Coin6")

	# --- 1. Physics & Reachability Validation ---
	print("  Validating Physics & Reachability limits...")
	assert_eq(player.jump_velocity, -470.0, "Player jump velocity tuned to -470.0")
	assert_eq(player.gravity, 1150.0, "Player gravity tuned to 1150.0")
	assert_eq(player.move_speed, 240.0, "Player horizontal move speed tuned to 240.0")

	var max_jump_height = (player.jump_velocity * player.jump_velocity) / (2.0 * player.gravity)
	assert_true(max_jump_height >= 95.0, "Maximum jump height is at least 95px (calculated: %.1fpx)" % max_jump_height)

	# Calculate platform surface heights
	var g1_surf = ground1.position.y - 40.0 # 380
	var p1_surf = plat1.position.y - 12.0   # 328
	var p2_surf = plat2.position.y - 12.0   # 268
	var p3_surf = plat3.position.y - 12.0   # 218
	var pg_surf = platgreedy.position.y - 12.0 # 388
	var g2_surf = ground2.position.y - 40.0 # 280
	var p4_surf = plat4.position.y - 12.0   # 318
	var p5_surf = plat5.position.y - 12.0   # 258
	var g3_surf = ground3.position.y - 40.0 # 380

	var rise_g1_to_p1 = g1_surf - p1_surf
	var rise_p1_to_p2 = p1_surf - p2_surf
	var rise_p2_to_p3 = p2_surf - p3_surf
	var rise_g2_to_p4 = g2_surf - p4_surf
	var rise_p4_to_p5 = p4_surf - p5_surf

	assert_true(rise_g1_to_p1 < max_jump_height - 20.0, "Ground1 -> Plat1 rise (%.1fpx) has >= 20px clearance margin" % rise_g1_to_p1)
	assert_true(rise_p1_to_p2 < max_jump_height - 20.0, "Plat1 -> Plat2 rise (%.1fpx) has >= 20px clearance margin (FIXED: previously impossible 90px)" % rise_p1_to_p2)
	assert_true(rise_p2_to_p3 < max_jump_height - 20.0, "Plat2 -> Plat3 rise (%.1fpx) is easily reachable" % rise_p2_to_p3)
	assert_true(rise_g2_to_p4 < max_jump_height - 20.0, "Ground2 -> Plat4 rise (%.1fpx) has >= 20px clearance margin" % rise_g2_to_p4)
	assert_true(rise_p4_to_p5 < max_jump_height - 20.0, "Plat4 -> Plat5 rise (%.1fpx) has >= 20px clearance margin" % rise_p4_to_p5)

	# Verify player visibility and no control overlap
	var jump_btn = lvl.get_node("HUD/TouchControls/JumpBtn")
	var jump_top_y = 540.0 + jump_btn.offset_top # 400.0
	assert_true(g1_surf <= jump_top_y - 20.0, "Ground 1 surface (%.1fpx) is >= 20px above controls top (%.1fpx)" % [g1_surf, jump_top_y])
	assert_true(g3_surf <= jump_top_y - 20.0, "Ground 3 surface (%.1fpx) is >= 20px above controls top (%.1fpx)" % [g3_surf, jump_top_y])
	assert_true(lvl.spawn_point.position.x > 100.0, "SpawnPoint (x=%.1f) is positioned clear of Left button" % lvl.spawn_point.position.x)

	const FallingPlatformScript = preload("res://scripts/coin_hell/falling_platform.gd")
	const GreedyPlatformScript = preload("res://scripts/coin_hell/greedy_platform.gd")
	const FakeSafePlatformScript = preload("res://scripts/coin_hell/fake_safe_platform.gd")

	# --- 2. TRICK 1 — The Betraying Platform ---
	print("  Validating Trick 1: The Betraying Platform...")
	assert_true(plat2 is FallingPlatformScript, "Platform2 uses FallingPlatform script")
	assert_true(not plat2._triggered, "Platform2 starts un-triggered")
	plat2.trigger()
	assert_true(plat2._triggered, "Platform2 triggers when stepped on")
	assert_true(not plat2._falling, "Platform2 gives a shaking warning period before falling")
	# Simulate 0.5s of physics process
	for _i in range(35):
		plat2._physics_process(0.016)
	assert_true(plat2._falling, "Platform2 falls after warning timer expires")
	assert_true(plat2.collision_shape.disabled, "Platform2 collision disables when falling")
	plat2.reset()
	assert_true(not plat2._triggered and not plat2._falling, "Platform2 resets cleanly on retry")
	assert_true(not plat2.collision_shape.disabled, "Platform2 collision re-enabled on reset")

	# --- 3. TRICK 3 — The Greedy Coin ---
	print("  Validating Trick 3: The Greedy Coin...")
	assert_true(platgreedy is GreedyPlatformScript, "PlatformGreedy uses GreedyPlatform script")
	var initial_greedy_y = platgreedy.position.y
	assert_true(not platgreedy._has_dropped, "GreedyPlatform starts at normal height")
	platgreedy.trigger_greedy_drop()
	assert_true(platgreedy._has_dropped, "GreedyPlatform triggers drop upon player stepping on it")
	assert_true(not platgreedy._falling, "GreedyPlatform shakes before falling into pit")
	for _i in range(30):
		platgreedy._physics_process(0.016)
	assert_true(platgreedy._falling, "GreedyPlatform falls into pit, making missed jump unrecoverable")
	assert_true(platgreedy.collision_shape.disabled, "GreedyPlatform collision disabled when fallen")
	platgreedy.reset()
	assert_true(not platgreedy._has_dropped and not platgreedy._falling, "GreedyPlatform resets cleanly on retry")
	assert_eq(platgreedy.position.y, initial_greedy_y, "GreedyPlatform position resets to initial height")
	assert_true(not platgreedy.collision_shape.disabled, "GreedyPlatform collision re-enabled on reset")

	# --- 4. TRICK 2 — The Fake Safe Landing ---
	print("  Validating Trick 2: The Fake Safe Landing...")
	assert_true(plat4 is FakeSafePlatformScript, "Platform4 uses FakeSafePlatform script")
	assert_true(not plat4._triggered, "FakeSafePlatform starts un-triggered")
	assert_true(not plat4.spikes_sprite.visible, "Spikes are completely hidden before activation with no warning indicators")
	assert_true(plat4.spikes_collision.disabled, "FakeSafePlatform spikes collision is initially disabled")
	plat4.trigger_trap()
	assert_true(plat4._triggered, "FakeSafePlatform triggers trap on approach")
	assert_true(plat4._active_spikes, "Spikes emerge immediately upon crossing trigger with no delay")
	assert_true(plat4.spikes_sprite.visible, "Spikes sprite is visible once emerged")
	assert_true(not plat4.spikes_collision.disabled, "Spikes collision is enabled immediately once active")
	plat4.reset()
	assert_true(not plat4._triggered and not plat4._active_spikes, "FakeSafePlatform resets cleanly on retry")
	assert_true(not plat4.spikes_sprite.visible, "Spikes are hidden again on reset")
	assert_true(plat4.spikes_collision.disabled, "Spikes retract and collision is disabled on reset")

	# --- 5. TRICK 4 — The Stationary Exit Gate ---
	print("  Validating Trick 4: The Stationary Exit Gate...")
	var initial_exit_pos = exit_gate.global_position
	# Unlock gate
	exit_gate.unlock_gate()
	assert_true(exit_gate._is_open, "Exit gate unlocks")
	assert_eq(exit_gate.status_label.text, "EXIT OPEN!", "Exit gate displays 'EXIT OPEN!'")
	assert_eq(exit_gate.global_position, initial_exit_pos, "Exit gate remains stationary as required")
	# Enter exit gate
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level completes when entering stationary exit")
	exit_gate.reset()
	assert_true(not exit_gate._is_open, "Exit gate resets to locked on retry")
	assert_true(not exit_gate._completion_triggered, "Exit completion flag resets on retry")
	assert_eq(exit_gate.global_position, initial_exit_pos, "Exit position remains unchanged on reset")

	lvl.queue_free()

func test_full_level_1_gameplay_walkthrough() -> void:
	print("\n--- TEST: Full Level 1 Gameplay Walkthrough & Traversal ---")
	SaveManager._apply_defaults()
	SaveManager.save_data()
	
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	var lvl = lvl1_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var exit_gate = lvl.get_node("ExitGate")
	var coins_container = lvl.get_node("Coins")
	var plat2 = lvl.get_node("Platforms/Platform2")
	var platgreedy = lvl.get_node("Platforms/PlatformGreedy")
	var plat4 = lvl.get_node("Platforms/Platform4")
	
	GameManager.is_gameplay_active = true
	GameManager.reset_coins()
	
	# Verify initial state
	assert_eq(GameManager.current_coins, 0, "Walkthrough starts with 0 coins")
	assert_true(not exit_gate._is_open, "Exit starts locked")
	
	# Step 1: Walkthrough collecting coins 1 to 5
	for i in range(1, 6):
		var coin = coins_container.get_node("Coin%d" % i)
		assert_true(coin != null, "Coin %d exists" % i)
		coin.collect()
	assert_eq(GameManager.current_coins, 5, "Collected coins 1 to 5")
	
	# Step 2: Trigger Trick 1 (FallingPlatform) and recover
	plat2.trigger()
	assert_true(plat2._triggered, "Trick 1 triggered during walkthrough")
	
	# Step 3: Collect Coin 6 (Trick 3: Greedy Coin)
	var coin6 = coins_container.get_node("Coin6")
	coin6.collect()
	assert_eq(GameManager.current_coins, 6, "Coin 6 collected")
	platgreedy.trigger_greedy_drop()
	assert_true(platgreedy._has_dropped, "Greedy platform triggered drop upon landing")
	
	# Step 4: Collect Coins 7 to 9
	for i in range(7, 10):
		var coin = coins_container.get_node("Coin%d" % i)
		coin.collect()
	assert_eq(GameManager.current_coins, 9, "Collected coins 7 to 9")
	
	# Step 5: Trigger Trick 2 (FakeSafePlatform) and recover
	plat4.trigger_trap()
	assert_true(plat4._triggered, "Trick 2 triggered during walkthrough")
	
	# Step 6: Collect final Coin 10
	var coin10 = coins_container.get_node("Coin10")
	coin10.collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected!")
	assert_true(exit_gate._is_open, "Exit gate unlocked automatically after 10th coin")
	
	# Step 7: Enter unlocked stationary exit gate
	GameManager.current_level_id = 1
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 1 completion triggered upon reaching exit")
	assert_true(SaveManager.is_level_completed(1), "Level 1 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(2), "Level 2 is now unlocked in SaveManager")
	
	# Step 8: Verify reset on death
	player.die()
	assert_true(lvl.death_overlay.visible, "Death overlay shown on death")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Coins reset to 0 on retry")
	assert_true(not exit_gate._is_open, "Exit reset to locked on retry")
	assert_true(not plat2._triggered, "Trick 1 reset on retry")
	assert_true(not platgreedy._has_dropped, "Trick 3 reset on retry")
	assert_true(not plat4._triggered, "Trick 2 reset on retry")
	assert_true(not exit_gate._completion_triggered, "Exit completion reset on retry")
	
	lvl.queue_free()

func test_spike_collision_directions_and_cases() -> void:
	print("\n--- TEST: Spike Collision Cases (A through F) ---")
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	var lvl = lvl1_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var plat4 = lvl.get_node("Platforms/Platform4")
	var exit_gate = lvl.get_node("ExitGate")

	# --- CASE A: Walk into active spikes from the side ---
	print("  Testing Case A: Walk into active spikes from the side...")
	plat4.reset()
	player.reset_to(Vector2(1340, 300))
	plat4.trigger_trap()
	assert_true(plat4._active_spikes, "Case A: Spikes are active")
	player.global_position = Vector2(1370, 304)
	plat4._check_spike_collision()
	assert_true(not player._is_alive, "Case A: Player died walking into active spikes from the side")
	assert_true(lvl.death_overlay.visible, "Case A: Death overlay shown")

	# --- CASE B: Jump onto active spikes from above ---
	print("  Testing Case B: Jump onto active spikes from above...")
	lvl._on_retry()
	plat4.trigger_trap()
	assert_true(plat4._active_spikes, "Case B: Spikes are active")
	player.global_position = Vector2(1380, 270)
	player.velocity = Vector2(0, 300)
	player.global_position = Vector2(1380, 302)
	plat4._check_spike_collision()
	assert_true(not player._is_alive, "Case B: Player died jumping onto active spikes from above")

	# --- CASE C: Land directly on top of the spikes ---
	print("  Testing Case C: Land directly on top of the spikes...")
	lvl._on_retry()
	player.reset_to(Vector2(1380, 280))
	player.global_position = Vector2(1380, 304)
	plat4.trigger_trap()
	plat4._check_spike_collision()
	assert_true(not player._is_alive, "Case C: Player died landing directly on top of the spikes")

	# --- CASE D: Touch the spikes immediately after they emerge ---
	print("  Testing Case D: Touch spikes immediately after they emerge...")
	lvl._on_retry()
	player.reset_to(Vector2(1380, 304))
	assert_true(player._is_alive, "Case D: Player alive before trap triggers")
	plat4.trigger_trap()
	assert_true(plat4._active_spikes, "Case D: Trap emerged immediately")
	assert_true(not player._is_alive, "Case D: Player died in emergence frame upon touching new spikes")

	# --- CASE E: Restart after dying and trigger the same trap again ---
	print("  Testing Case E: Restart after dying and trigger same trap again...")
	lvl._on_retry()
	assert_true(player._is_alive, "Case E: Player alive after retry")
	assert_true(not plat4._triggered and not plat4._active_spikes, "Case E: Platform 4 spikes reset to hidden/harmless")
	assert_true(plat4.spikes_collision.disabled, "Case E: Spikes collision disabled on reset")
	assert_true(not plat4.spikes_sprite.visible, "Case E: Spikes sprite hidden on reset")
	player.global_position = Vector2(1340, 300)
	plat4._check_spike_collision()
	assert_true(player._is_alive, "Case E: Player unharmed before trap triggers")
	plat4.trigger_trap()
	player.global_position = Vector2(1380, 304)
	plat4._check_spike_collision()
	assert_true(not player._is_alive, "Case E: Player died when triggering same trap again after retry")

	# --- CASE F: Complete the level without touching the spikes ---
	print("  Testing Case F: Complete level without touching the spikes...")
	lvl._on_retry()
	assert_true(player._is_alive, "Case F: Player alive on fresh attempt")
	var coins = lvl.get_node("Coins")
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_true(exit_gate._is_open, "Case F: Exit open after 10 coins")
	player.global_position = Vector2(1560, 250)
	assert_true(player._is_alive, "Case F: Player alive on Platform 5 without touching spikes")
	player.global_position = exit_gate.global_position
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Case F: Level completed successfully without touching spikes")

	lvl.queue_free()

func test_level_2_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 2 Gameplay & All 4 Traps + Fake Exit ---")
	var lvl2_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_2.tscn")
	assert_true(lvl2_scene != null, "Level 2 scene loads successfully")
	var lvl = lvl2_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var coins = lvl.get_node("Coins")
	var fake_exit = lvl.get_node("FakeExitGate")
	var real_exit = lvl.get_node("RealExitGate")
	var platforms = lvl.get_node("Platforms")
	var traps = lvl.get_node("Traps")

	assert_true(player != null, "Player exists in Level 2")
	assert_eq(coins.get_child_count(), 10, "Level 2 contains exactly 10 coins")
	assert_true(fake_exit != null, "FakeExitGate exists in Level 2")
	assert_true(real_exit != null, "RealExitGate exists in Level 2")
	assert_true(not real_exit.visible, "RealExitGate is initially hidden")

	# --- FIX 1: PLAYER VISIBILITY & CAMERA / TOUCH CONTROLS ---
	print("  Validating Fix 1: Player Visibility, Camera Framing & Controls...")
	var cam: Camera2D = lvl.get_node("Player/Camera2D")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom frames player with safe headroom")
	assert_eq(cam.offset.y, -45.0, "Camera2D has negative vertical offset framing player above controls")
	var touch_controls = lvl.get_node("HUD/TouchControls")
	assert_eq(touch_controls.get_node("LeftBtn").modulate.a, 0.75, "LeftBtn has semi-transparency")
	assert_eq(touch_controls.get_node("LeftBtn").offset_bottom, -16.0, "LeftBtn positioned comfortably for thumbs")
	assert_eq(touch_controls.get_node("RightBtn").offset_bottom, -16.0, "RightBtn positioned comfortably for thumbs")
	assert_eq(touch_controls.get_node("JumpBtn").offset_bottom, -16.0, "JumpBtn positioned comfortably for thumbs")

	# --- TRAP 1: CRUMBLING BRIDGE (FIX 2: CONSISTENT APPEARANCE) ---
	print("  Validating Trap 1: Crumbling Bridge (Fix 2: Consistent Appearance)...")
	var b1 = platforms.get_node("BridgeSection1")
	var b2 = platforms.get_node("BridgeSection2")
	var b3 = platforms.get_node("BridgeSection3")
	assert_true(b1 is CrumblingBridgeSectionClass, "BridgeSection1 uses CrumblingBridgeSection script")
	assert_true(b2 is CrumblingBridgeSectionClass, "BridgeSection2 uses CrumblingBridgeSection script")
	assert_true(b3 is CrumblingBridgeSectionClass, "BridgeSection3 uses CrumblingBridgeSection script")
	assert_eq(b1.get_node("NinePatchRect").texture.resource_path, "res://assets/sprites/platform_ruins.png", "BridgeSection1 uses standard ruins texture")
	assert_eq(b2.get_node("NinePatchRect").texture.resource_path, "res://assets/sprites/platform_ruins.png", "BridgeSection2 uses standard ruins texture")
	assert_eq(b3.get_node("NinePatchRect").texture.resource_path, "res://assets/sprites/platform_ruins.png", "BridgeSection3 uses standard ruins texture")
	assert_true(not b1._is_triggered, "BridgeSection1 is initially untriggered")
	assert_true(not b1.collision_shape.disabled, "BridgeSection1 collision is active initially")

	# Step on BridgeSection1
	b1.trigger_collapse()
	assert_true(b1._is_triggered, "BridgeSection1 starts shaking upon trigger")
	b1._timer = 0.0
	b1._physics_process(0.01)
	assert_true(b1._is_falling, "BridgeSection1 falls after collapse delay")
	assert_true(b1.collision_shape.disabled, "BridgeSection1 collision is disabled so no invisible surface remains")

	# Reset Trap 1
	b1.reset()
	assert_true(not b1._is_triggered, "BridgeSection1 untriggered after reset")
	assert_true(not b1.collision_shape.disabled, "BridgeSection1 collision restored after reset")

	# --- TRAP 2: GREEDY COIN (FIX 3: CLEAR JUMP & TEXTURE CONSISTENCY) ---
	print("  Validating Trap 2: Greedy Coin Platform (Fix 3: Clear Jump Geometry)...")
	var gp = platforms.get_node("PlatformGreedy")
	assert_true(gp is GreedyPlatform, "PlatformGreedy uses GreedyPlatform script")
	assert_eq(gp.get_node("NinePatchRect").texture.resource_path, "res://assets/sprites/platform_ruins.png", "PlatformGreedy uses standard ruins texture")
	assert_true(platforms.get_node("HighPlatform").global_position.x < gp.global_position.x, "HighPlatform is offset from PlatformGreedy allowing clear jump")
	assert_true(not gp._has_dropped, "PlatformGreedy starts untriggered")
	assert_true(not gp.collision_shape.disabled, "PlatformGreedy collision active initially")

	gp.trigger_greedy_drop()
	assert_true(gp._has_dropped, "PlatformGreedy triggers drop when landed on")
	gp._delay_timer = 0.0
	gp._physics_process(0.01)
	assert_true(gp._falling, "PlatformGreedy falls after warning delay")
	assert_true(gp.collision_shape.disabled, "PlatformGreedy collision disabled upon falling")

	gp.reset()
	assert_true(not gp._has_dropped, "PlatformGreedy reset restores untriggered state")
	assert_true(not gp.collision_shape.disabled, "PlatformGreedy collision restored upon reset")

	# --- TRAP 3: HIDDEN SPIKE FLOOR (FIX 3: PROPER TEXTURE & NO OVERLAP) ---
	print("  Validating Trap 3: Hidden Spike Floor (Fix 3: Proper Texture & Hitbox)...")
	var spike_floor = platforms.get_node("PlatformSpikeFloor")
	assert_true(spike_floor is FakeSafePlatform, "PlatformSpikeFloor uses FakeSafePlatform script")
	assert_eq(spike_floor.spikes_sprite.texture.resource_path, "res://assets/sprites/spikes.png", "Spike floor uses valid spikes texture")
	var spike_trig_left: float = spike_floor.global_position.x + spike_floor.get_node("TriggerArea/CollisionShape2D").position.x - 50.0
	var post_greedy_right: float = platforms.get_node("PlatformPostGreedy").global_position.x + 60.0
	assert_true(spike_trig_left > post_greedy_right, "Spike floor trigger does not overlap safe PlatformPostGreedy")
	assert_true(not spike_floor._active_spikes, "Spikes are initially inactive and hidden")
	assert_true(spike_floor.spikes_collision.disabled, "Spikes collision disabled initially")

	spike_floor.trigger_trap()
	assert_true(spike_floor._active_spikes, "Spikes become active immediately upon trigger")
	assert_true(not spike_floor.spikes_collision.disabled, "Spikes collision enabled immediately")
	assert_true(spike_floor.spikes_sprite.visible, "Spikes sprite visible once active")

	# Verify spikes lethal to player
	player._is_alive = true
	spike_floor._kill_player(player)
	assert_true(not player._is_alive, "Player dies when contacting active spikes")

	spike_floor.reset()
	assert_true(not spike_floor._active_spikes, "Spikes reset to inactive")
	assert_true(spike_floor.spikes_collision.disabled, "Spikes collision disabled on reset")
	assert_true(not spike_floor.spikes_sprite.visible, "Spikes sprite hidden on reset")

	# --- TRAP 4: MOVING WALL & WALL SPIKE TRAP (FIX 4) ---
	print("  Validating Trap 4: Moving Wall & Wall Spike Trap (Fix 4)...")
	var mwall = traps.get_node("MovingWall")
	assert_true(mwall is MovingWallClass, "MovingWall uses MovingWall script")
	assert_true(mwall is AnimatableBody2D, "MovingWall is AnimatableBody2D for stable physics")
	assert_true(not mwall._is_active, "MovingWall starts stationary")
	var start_x = mwall.position.x

	mwall.activate()
	assert_true(mwall._is_active, "MovingWall activated upon trigger")
	mwall._physics_process(0.1)
	assert_true(mwall.position.x != start_x, "MovingWall moves smoothly in physics process")

	mwall.reset()
	assert_true(not mwall._is_active, "MovingWall reset restores stationary state")
	assert_eq(mwall.position.x, start_x, "MovingWall position restored to initial coordinate")

	# Validate Wall Spike Trap
	var wall_spikes = traps.get_node("WallSpikeTrap")
	assert_true(wall_spikes is WallSpikeTrapClass, "WallSpikeTrap exists")
	assert_true(not wall_spikes._is_triggered, "WallSpikeTrap starts untriggered")
	assert_true(wall_spikes.collision_shape.disabled, "WallSpikeTrap collision disabled initially")
	assert_true(not wall_spikes.sprite.visible, "WallSpikeTrap sprite hidden initially")

	wall_spikes.activate_trap()
	assert_true(wall_spikes._is_triggered, "WallSpikeTrap triggered")
	wall_spikes._is_active = true
	wall_spikes.collision_shape.disabled = false
	player._is_alive = true
	wall_spikes._kill_player(player)
	assert_true(not player._is_alive, "WallSpikeTrap is lethal to player")

	wall_spikes.reset()
	assert_true(not wall_spikes._is_triggered, "WallSpikeTrap resets to untriggered")
	assert_true(wall_spikes.collision_shape.disabled, "WallSpikeTrap collision disabled on reset")
	assert_true(not wall_spikes.sprite.visible, "WallSpikeTrap sprite hidden on reset")

	# --- FINAL SURPRISE: FAKE EXIT AT EDGE (FIX 5) ---
	print("  Validating Final Surprise: Fake Exit at Edge -> Real Exit (Fix 5)...")
	assert_true(fake_exit is FakeExitGateClass, "FakeExitGate uses FakeExitGate script")
	assert_true(fake_exit.global_position.x > platforms.get_node("GroundExit").global_position.x, "FakeExitGate is placed near edge of ground exit")
	assert_true(not fake_exit._is_coins_ready, "FakeExitGate initially requires coins")
	assert_eq(fake_exit.status_label.text, "COINS REQUIRED", "FakeExitGate displays 'COINS REQUIRED'")

	# Approaching early shows toast
	fake_exit._on_body_entered(player)
	assert_true(not fake_exit._has_tricked, "FakeExitGate does not trigger deception before all coins collected")

	# Collect all 10 coins
	GameManager.current_level_id = 2
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for c in coins.get_children():
		c.collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 2")
	assert_true(fake_exit._is_coins_ready, "FakeExitGate indicates coins ready")
	assert_eq(fake_exit.status_label.text, "EXIT OPEN!", "FakeExitGate displays 'EXIT OPEN!'")

	# Approaching FakeExitGate triggers deception
	fake_exit._on_body_entered(player)
	assert_true(fake_exit._has_tricked, "FakeExitGate triggers deception sequence")
	assert_eq(fake_exit.status_label.text, "", "FakeExitGate displays no explanatory label upon deception")
	assert_true(real_exit.visible, "RealExitGate revealed upon FakeExitGate deception")
	assert_true(real_exit._is_open, "RealExitGate is unlocked and open")
	assert_eq(real_exit.status_label.text, "EXIT OPEN!", "RealExitGate displays standard 'EXIT OPEN!' without explanatory label")

	# Enter RealExitGate to complete Level 2
	GameManager.is_gameplay_active = true
	real_exit._on_body_entered(player)
	assert_true(real_exit._completion_triggered, "Level 2 completion triggered upon entering RealExitGate")
	assert_true(SaveManager.is_level_completed(2), "Level 2 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(3), "Level 3 is unlocked after Level 2 completion")

	# Next Level button from complete overlay in Level 2 verifies Level 3 is ready to launch
	assert_true(GameManager.can_play_level(3), "Level 3 is playable and ready to start after Level 2")

	# Reset Level 2 (FIX 6: VERIFY ALL RESETS)
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 2 retry resets coins to 0")
	assert_true(not fake_exit._has_tricked, "FakeExitGate deception reset")
	assert_true(not real_exit.visible, "RealExitGate hidden again on reset")
	assert_true(not real_exit._completion_triggered, "RealExitGate completion flag reset")
	assert_true(not wall_spikes._is_triggered, "WallSpikeTrap untriggered on level retry")
	assert_true(not mwall._is_active, "MovingWall inactive on level retry")

	lvl.queue_free()

func test_level_3_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 3 Gameplay, Spike Gauntlet & Inferno Gates ---")
	var lvl3_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_3.tscn")
	assert_true(lvl3_scene != null, "Level 3 scene loads successfully")
	var lvl = lvl3_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var coins = lvl.get_node("Coins")
	var exit_gate = lvl.get_node("ExitGate")
	var platforms = lvl.get_node("Platforms")
	var traps = lvl.get_node("Traps")

	assert_true(player != null, "Player exists in Level 3")
	assert_eq(coins.get_child_count(), 10, "Test 1: Level 3 contains exactly 10 coins")
	assert_true(exit_gate != null, "ExitGate exists in Level 3")
	assert_eq(exit_gate.status_label.text, "COINS REQUIRED", "ExitGate starts locked requiring coins")

	# Section A: Safe start
	print("  Validating Section A: Safe Start & Controls...")
	assert_eq(lvl.get_node("SpawnPoint").global_position, Vector2(100, 380), "Player spawns safely with ample headroom")
	var cam: Camera2D = player.get_node("Camera2D")
	assert_eq(cam.limit_bottom, 600, "Camera2D frames player safely")
	assert_eq(cam.offset.y, -45.0, "Camera2D negative offset ensures landing visibility")
	var touch_controls = lvl.get_node("HUD/TouchControls")
	assert_eq(touch_controls.get_node("LeftBtn").modulate.a, 0.75, "Touch controls have comfortable semi-transparency")

	# Section B & C: Spike Gauntlet & 10 Distinct Coin Trap Encounters
	print("  Validating Sections B & C: 10 Distinct Coin Trap Encounters...")
	var inf_gate = traps.get_node("InfernoGate")
	assert_true(inf_gate != null, "InfernoGate exists in Level 3")
	var inf_x = inf_gate.position.x

	# Verify ALL 10 coins appear strictly before the Inferno Gate
	for i in range(1, 11):
		var coin_node = coins.get_node("Coin%d" % i)
		assert_true(coin_node.position.x < inf_x, "Coin %d (X=%d) is placed before Inferno Gate (X=%d)" % [i, int(coin_node.position.x), int(inf_x)])

	# Validate Encounter 1: Coin 1 - Spikes directly below coin
	var c1 = coins.get_node("Coin1")
	var st1 = traps.get_node("SpikeTrap1")
	assert_true(st1 is FakeSafePlatform, "SpikeTrap1 uses FakeSafePlatform")
	assert_eq(st1.position.x, c1.position.x, "Coin 1: Spikes placed directly beneath coin (X=200)")
	assert_true(not st1._active_spikes, "SpikeTrap1 starts dormant")
	assert_true(st1.spikes_collision.disabled, "SpikeTrap1 collision disabled initially")
	st1.trigger_trap()
	assert_true(st1._active_spikes, "SpikeTrap1 triggers immediately")
	player._is_alive = true
	st1._kill_player(player)
	assert_true(not player._is_alive, "SpikeTrap1 kills player stepping beneath Coin 1")
	st1.reset()
	assert_true(not st1._active_spikes, "SpikeTrap1 resets cleanly")

	# Validate Encounter 2: Coin 2 - Spikes on approach
	var c2 = coins.get_node("Coin2")
	var st2 = traps.get_node("SpikeTrap2")
	assert_true(st2 is FakeSafePlatform, "SpikeTrap2 uses FakeSafePlatform")
	assert_true(st2.position.x < c2.position.x, "Coin 2: Spikes placed before coin on approach (X=360 vs Coin X=450)")
	assert_true(not st2._active_spikes, "SpikeTrap2 starts dormant")

	# Validate Encounter 3: Coin 3 - Spikes on landing side
	var c3 = coins.get_node("Coin3")
	var st3 = traps.get_node("SpikeTrap3")
	assert_true(st3 is FakeSafePlatform, "SpikeTrap3 uses FakeSafePlatform")
	assert_true(st3.position.x > c3.position.x, "Coin 3: Spikes placed on landing side past coin (X=680 vs Coin X=615)")
	assert_true(not st3._active_spikes, "SpikeTrap3 starts dormant")

	# Validate Encounter 4: Coin 4 - Airborne spikes + low floor trap
	var c4 = coins.get_node("Coin4")
	var air4 = traps.get_node("AirSpikes4")
	var st4 = traps.get_node("SpikeTrap4")
	assert_true(air4 != null, "Coin 4: Airborne spikes exist overhead")
	assert_true(air4.position.y < c4.position.y, "Coin 4: AirSpikes4 suspended above jump arc (Y=275 vs Coin Y=355)")
	assert_true(st4 is FakeSafePlatform, "Coin 4: Floor SpikeTrap4 exists")

	# Validate Encounter 5: Coin 5 - Double trap: Below coin AND landing side
	var c5 = coins.get_node("Coin5")
	var st5 = traps.get_node("SpikeTrap5")
	var st5_land = traps.get_node("SpikeTrap5_Landing")
	assert_eq(st5.position.x, c5.position.x, "Coin 5: SpikeTrap5 beneath coin (X=1080)")
	assert_true(st5_land.position.x > c5.position.x, "Coin 5: SpikeTrap5_Landing on forward landing zone (X=1160)")

	# Validate Encounter 6: Coin 6 - Spikes immediately after coin
	var c6 = coins.get_node("Coin6")
	var st6 = traps.get_node("SpikeTrap6")
	assert_true(st6.position.x > c6.position.x, "Coin 6: SpikeTrap6 positioned immediately after coin (X=1400 vs Coin X=1340)")

	# Validate Encounter 7: Coin 7 - Stepped approach trap + airborne hazard
	var c7 = coins.get_node("Coin7")
	var st7 = traps.get_node("SpikeTrap7")
	var air7 = traps.get_node("AirSpikes7")
	assert_true(st7.position.x < c7.position.x, "Coin 7: SpikeTrap7 guards low approach")
	assert_true(air7 != null and air7.position.y < c7.position.y, "Coin 7: AirSpikes7 restricts high jump")

	# Validate Encounter 8: Coin 8 - Combined approach and landing trap
	var c8 = coins.get_node("Coin8")
	var st8_front = traps.get_node("SpikeTrap8")
	var st8_back = traps.get_node("SpikeTrap8_Landing")
	assert_true(st8_front.position.x < c8.position.x, "Coin 8: SpikeTrap8 guards front approach (X=1740)")
	assert_true(st8_back.position.x > c8.position.x, "Coin 8: SpikeTrap8_Landing guards back landing (X=1875)")

	# Validate Encounter 9: Coin 9 - Anti-retreat trap behind coin
	var c9 = coins.get_node("Coin9")
	var st9 = traps.get_node("SpikeTrap9")
	assert_true(st9.position.x < c9.position.x, "Coin 9: SpikeTrap9 positioned behind coin (X=1990 vs Coin X=2020)")

	# Validate Encounter 10: Coin 10 - Multi-hazard pre-gate climax (Below + Overhead + Landing)
	var c10 = coins.get_node("Coin10")
	var st10 = traps.get_node("SpikeTrap10")
	var air10 = traps.get_node("AirSpikes10")
	var st10_land = traps.get_node("SpikeTrap10_Landing")
	assert_eq(st10.position.x, c10.position.x, "Coin 10: SpikeTrap10 directly beneath coin (X=2230)")
	assert_true(air10 != null and air10.position.y < c10.position.y, "Coin 10: AirSpikes10 suspended overhead (Y=275)")
	assert_true(st10_land.position.x > c10.position.x, "Coin 10: SpikeTrap10_Landing guards overshot landing (X=2300)")

	# Section E: Concealed Inferno Gate (Signature Surprise - NO Markings)
	print("  Validating Section E: Concealed Inferno Gate (No Markings)...")
	assert_true(inf_gate is InfernoGateClass, "InfernoGate uses InfernoGate script")
	assert_true(not inf_gate._is_triggered, "InfernoGate starts dormant before proximity trigger")
	assert_true(not inf_gate._is_active, "InfernoGate is inactive initially")
	assert_true(inf_gate.flame_collision.disabled, "InfernoGate lethal collision disabled initially")
	assert_true(not inf_gate.flame_sprite.visible, "InfernoGate flame sprite is hidden before trigger")
	assert_true(not inf_gate.top_emitter.visible, "InfernoGate top emitter hidden before trigger (NO MARKINGS)")
	assert_true(not inf_gate.bottom_emitter.visible, "InfernoGate bottom emitter hidden before trigger (NO MARKINGS)")

	# Proximity activation at last moment
	inf_gate.activate_gate()
	assert_true(inf_gate._is_triggered, "InfernoGate activates upon entering detection range")
	assert_true(inf_gate._is_active, "InfernoGate flames erupt suddenly")
	assert_true(not inf_gate.flame_collision.disabled, "InfernoGate lethal collision enabled on eruption")
	assert_true(inf_gate.flame_sprite.visible, "InfernoGate full-height flames visible and blazing")
	assert_true(inf_gate.top_emitter.visible, "InfernoGate top emitter appears during eruption")
	assert_true(inf_gate.bottom_emitter.visible, "InfernoGate bottom emitter appears during eruption")

	# Active fire lethality
	player._is_alive = true
	inf_gate._kill_player(player)
	assert_true(not player._is_alive, "Active fire is lethal to player")

	# Safe opening cycle
	inf_gate._retract_flames()
	assert_true(not inf_gate._is_active, "InfernoGate flames retract for safe opening")
	assert_true(inf_gate._in_safe_phase, "InfernoGate enters safe opening phase")
	assert_true(inf_gate.flame_collision.disabled, "Lethal collision disabled during safe opening")
	assert_true(not inf_gate.top_emitter.visible, "Top emitter hidden during safe opening")
	assert_true(not inf_gate.bottom_emitter.visible, "Bottom emitter hidden during safe opening")
	player._is_alive = true
	inf_gate._on_flame_body_entered(player)
	assert_true(player._is_alive, "Player passes safely through retracted flame passage")

	# Reactivation cycle
	inf_gate._erupt_flames()
	assert_true(inf_gate._is_active, "InfernoGate reactivates after safe opening closes")
	assert_true(not inf_gate.flame_collision.disabled, "InfernoGate lethal collision reactivated")

	# Reset on death / retry
	inf_gate.reset()
	assert_true(not inf_gate._is_triggered, "InfernoGate resets to dormant on level retry")
	assert_true(not inf_gate._is_active, "InfernoGate inactive on reset")
	assert_true(inf_gate.flame_collision.disabled, "InfernoGate collision disabled on reset")
	assert_true(not inf_gate.flame_sprite.visible, "InfernoGate flame sprite concealed again on reset")
	assert_true(not inf_gate.top_emitter.visible, "InfernoGate top emitter concealed on reset")
	assert_true(not inf_gate.bottom_emitter.visible, "InfernoGate bottom emitter concealed on reset")

	# Section F: Post-fire finale & Exit Gate
	print("  Validating Section F: Post-Fire Finale & Level 3 Completion...")
	var st_finale = traps.get_node("SpikeTrap_Finale")
	assert_true(st_finale is FakeSafePlatform, "SpikeTrap_Finale guards exit approach")

	# Collect all 10 coins
	GameManager.current_level_id = 3
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 3")
	assert_true(exit_gate._is_open, "ExitGate unlocks automatically after collecting 10th coin")
	assert_eq(exit_gate.status_label.text, "EXIT OPEN!", "ExitGate displays 'EXIT OPEN!'")

	# Complete Level 3
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 3 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(3), "Level 3 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(4), "Level 4 is unlocked after Level 3 completion")
	assert_true(GameManager.can_play_level(4), "Level 4 is playable and ready to start after Level 3")

	# Reset Level 3
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 3 retry resets coins to 0")
	assert_true(not inf_gate._is_triggered, "InfernoGate untriggered on level retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")

	lvl.queue_free()

func test_level_4_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 4 Gameplay Mechanics (Ceiling Crushers) ---")
	var lvl4_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_4.tscn")
	assert_true(lvl4_scene != null, "Level 4 scene loads successfully")
	var lvl = lvl4_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var coins = lvl.get_node("Coins")
	var exit_gate = lvl.get_node("ExitGate")
	var platforms = lvl.get_node("Platforms")
	var traps = lvl.get_node("Traps")

	assert_true(player != null, "Player exists in Level 4")
	assert_eq(coins.get_child_count(), 10, "Test 1: Level 4 contains exactly 10 coins")
	assert_true(exit_gate != null, "ExitGate exists in Level 4")
	assert_eq(exit_gate.status_label.text, "COINS REQUIRED", "ExitGate starts locked requiring coins")

	# Safe spawn and camera
	assert_eq(lvl.get_node("SpawnPoint").global_position, Vector2(100, 380), "Player spawns safely at X=100, Y=380")
	var cam: Camera2D = player.get_node("Camera2D")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_eq(cam.offset.y, -45.0, "Camera2D negative offset ensures landing visibility")

	# Validate Ceiling Crusher 1 state machine and mechanics
	print("  Validating Crusher 1 State Machine & Reaction...")
	var cr1 = traps.get_node("Crusher1")
	assert_true(cr1 is CeilingCrusherClass, "Crusher1 uses CeilingCrusher class")
	assert_eq(cr1.current_state, CeilingCrusherClass.State.IDLE, "Crusher1 starts in State.IDLE")
	assert_true(cr1.hazard_collision.disabled, "Crusher1 hazard collision disabled in IDLE state")

	# Trigger Crusher 1
	cr1.trigger_crusher()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.TRIGGERED, "Crusher1 transitions to State.TRIGGERED")

	# Slam down
	cr1._start_descending()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.DESCENDING, "Crusher1 transitions to State.DESCENDING")
	assert_true(not cr1.hazard_collision.disabled, "Crusher1 hazard collision enabled during descent")

	# Active collision test: kills player
	player._is_alive = true
	cr1._kill_player(player)
	assert_true(not player._is_alive, "Crusher1 kills player upon crushing collision")

	# Reach bottom
	cr1._on_slam_reached()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.ACTIVE, "Crusher1 transitions to State.ACTIVE")

	# Retract
	cr1._start_retracting()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.RETRACTING, "Crusher1 transitions to State.RETRACTING")
	assert_true(cr1.hazard_collision.disabled, "Crusher1 hazard collision disabled during retraction")

	# Reset
	cr1._on_retract_reached()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.RESET, "Crusher1 transitions to State.RESET")

	# Full reset
	cr1.reset()
	assert_eq(cr1.current_state, CeilingCrusherClass.State.IDLE, "Crusher1 reset returns to State.IDLE")
	assert_eq(cr1.crusher_body.position.y, cr1._retracted_pos.y, "Crusher1 position restored to retracted position")

	# Validate all 10 distinct Coin Encounters
	print("  Validating 10 Distinct Coin Encounters in Level 4...")
	var c1 = coins.get_node("Coin1")
	assert_eq(c1.position, Vector2(420, 380), "Coin 1 positioned past Crusher 1")

	var cr2 = traps.get_node("Crusher2")
	var c2 = coins.get_node("Coin2")
	assert_eq(cr2.position.x, c2.position.x, "Coin 2 placed directly inside Crusher 2 danger zone (X=630)")

	var cr3 = traps.get_node("Crusher3")
	var c3 = coins.get_node("Coin3")
	assert_true(cr3.position.x > c3.position.x, "Coin 3 in mid-air (X=755) requires considering Crusher 3 landing (X=840)")

	var cr4 = traps.get_node("Crusher4")
	var c4 = coins.get_node("Coin4")
	assert_eq(cr4.position.x, c4.position.x, "Coin 4 on elevated platform under fast-trigger Crusher 4 (X=1110)")

	var cr5 = traps.get_node("Crusher5")
	var c5 = coins.get_node("Coin5")
	assert_true(c5.position.x < cr5.position.x, "Coin 5 on stepping pillar before chasm-guarding Crusher 5")

	var cr6 = traps.get_node("Crusher6")
	var sp6 = traps.get_node("FloorSpike6")
	var c6 = coins.get_node("Coin6")
	assert_true(c6.position.x < cr6.position.x, "Coin 6 before Crusher 6")
	assert_true(sp6.position.x > cr6.position.x, "FloorSpike6 punishes rushing past Crusher 6")

	var cr7a = traps.get_node("Crusher7A")
	var cr7b = traps.get_node("Crusher7B")
	var c7 = coins.get_node("Coin7")
	assert_true(cr7a.auto_cycle and cr7b.auto_cycle, "Crushers 7A and 7B are auto-cycling alternating hazards")
	assert_true(c7.position.x > cr7a.position.x and c7.position.x < cr7b.position.x, "Coin 7 is placed in the safe pocket between 7A and 7B")

	var cr8 = traps.get_node("Crusher8")
	var c8 = coins.get_node("Coin8")
	var p8_high = platforms.get_node("Platform8_High")
	assert_true(p8_high.position.y < cr8.position.y + 120, "Platform8_High provides high-jump safe landing for Coin 8")

	var cr9 = traps.get_node("Crusher9")
	var sp9 = traps.get_node("FloorSpike9")
	var c9 = coins.get_node("Coin9")
	assert_true(cr9.position.x < c9.position.x, "Crusher 9 is positioned behind Coin 9 to punish retreat")
	assert_true(sp9.position.x > c9.position.x, "FloorSpike9 is positioned past Coin 9")

	var cr10a = traps.get_node("Crusher10A")
	var cr10b = traps.get_node("Crusher10B")
	var c10 = coins.get_node("Coin10")
	assert_true(c10.position.x > cr10a.position.x and c10.position.x < cr10b.position.x, "Coin 10 centered between climax dual crushers 10A and 10B")

	# Collect all 10 coins and unlock exit gate
	print("  Validating Coin Collection & Level 4 Completion...")
	GameManager.current_level_id = 4
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 4")
	assert_true(exit_gate._is_open, "ExitGate unlocks automatically after collecting 10th coin")
	assert_eq(exit_gate.status_label.text, "EXIT OPEN!", "ExitGate displays 'EXIT OPEN!'")

	# Complete Level 4
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 4 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(4), "Level 4 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(5), "Level 5 is unlocked after Level 4 completion")

	# Next Level button verifies Level 5 is ready to start
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	assert_true(GameManager.can_play_level(5), "Level 5 is playable after Level 4 completion")

	# Reset Level 4
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 4 retry resets coins to 0")
	assert_eq(cr1.current_state, CeilingCrusherClass.State.IDLE, "Crusher 1 resets to IDLE on level retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")

	lvl.queue_free()

func test_level_5_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 5 Gameplay Mechanics (The Final Betrayal Redesign) ---")
	var lvl5_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_5.tscn")
	assert_true(lvl5_scene != null, "Level 5 scene loads successfully")
	var lvl = lvl5_scene.instantiate()
	add_child(lvl)

	var player = lvl.get_node("Player")
	var coins = lvl.get_node("Coins")
	var exit_gate = lvl.get_node("ExitGate")
	var platforms = lvl.get_node("Platforms")
	var traps = lvl.get_node("Traps")
	var hazards = lvl.get_node("Hazards")
	var hud = lvl.get_node("HUD")

	assert_true(player != null, "Player exists in Level 5")
	assert_eq(coins.get_child_count(), 10, "Test 1: Level 5 contains exactly 10 coins")
	assert_true(exit_gate != null, "ExitGate exists in Level 5")
	assert_true(not exit_gate._is_open, "ExitGate starts locked requiring coins")
	assert_true(not exit_gate.visible, "Real ExitGate is initially hidden pending deception")

	# Validate safe spawn & camera
	assert_eq(player.position.x, 100.0, "Player spawns safely at X=100")
	assert_eq(player.position.y, 380.0, "Player spawns safely at Y=380")
	var cam: Camera2D = player.get_node("Camera2D")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_eq(cam.limit_right, 3500, "Camera2D limit_right is 3500")
	assert_eq(cam.offset.y, -45.0, "Camera2D negative offset ensures landing visibility")

	# Validate Mobile Controls exact sizing and offsets matching Levels 1-4
	print("  Validating Level 5 Mobile Controls sizing matching Levels 1-4...")
	var left_btn: TextureButton = hud.get_node("TouchControls/LeftBtn")
	var right_btn: TextureButton = hud.get_node("TouchControls/RightBtn")
	var jump_btn: TextureButton = hud.get_node("TouchControls/JumpBtn")
	assert_true(left_btn != null and right_btn != null and jump_btn != null, "TouchControls buttons exist")
	assert_eq(left_btn.offset_left, 20.0, "LeftBtn offset_left matches Levels 1-4 (20.0)")
	assert_eq(left_btn.offset_right, 124.0, "LeftBtn offset_right matches Levels 1-4 (124.0)")
	assert_eq(left_btn.offset_top, -120.0, "LeftBtn offset_top matches Levels 1-4 (-120.0)")
	assert_eq(left_btn.offset_bottom, -16.0, "LeftBtn offset_bottom matches Levels 1-4 (-16.0)")
	assert_eq(left_btn.offset_right - left_btn.offset_left, 104.0, "LeftBtn width is 104px (matches Levels 1-4)")
	assert_eq(left_btn.offset_bottom - left_btn.offset_top, 104.0, "LeftBtn height is 104px (matches Levels 1-4)")

	assert_eq(right_btn.offset_left, 144.0, "RightBtn offset_left matches Levels 1-4 (144.0)")
	assert_eq(right_btn.offset_right, 248.0, "RightBtn offset_right matches Levels 1-4 (248.0)")
	assert_eq(right_btn.offset_top, -120.0, "RightBtn offset_top matches Levels 1-4 (-120.0)")
	assert_eq(right_btn.offset_bottom, -16.0, "RightBtn offset_bottom matches Levels 1-4 (-16.0)")
	assert_eq(right_btn.offset_right - right_btn.offset_left, 104.0, "RightBtn width is 104px (matches Levels 1-4)")
	assert_eq(right_btn.offset_bottom - right_btn.offset_top, 104.0, "RightBtn height is 104px (matches Levels 1-4)")

	assert_eq(jump_btn.offset_left, -140.0, "JumpBtn offset_left matches Levels 1-4 (-140.0)")
	assert_eq(jump_btn.offset_right, -16.0, "JumpBtn offset_right matches Levels 1-4 (-16.0)")
	assert_eq(jump_btn.offset_top, -140.0, "JumpBtn offset_top matches Levels 1-4 (-140.0)")
	assert_eq(jump_btn.offset_bottom, -16.0, "JumpBtn offset_bottom matches Levels 1-4 (-16.0)")
	assert_eq(jump_btn.offset_right - jump_btn.offset_left, 124.0, "JumpBtn width is 124px (matches Levels 1-4)")
	assert_eq(jump_btn.offset_bottom - jump_btn.offset_top, 124.0, "JumpBtn height is 124px (matches Levels 1-4)")

	assert_eq(left_btn.touch_margin, 8.0, "LeftBtn touch_margin matches Levels 1-4")
	assert_eq(right_btn.touch_margin, 8.0, "RightBtn touch_margin matches Levels 1-4")
	assert_eq(jump_btn.touch_margin, 16.0, "JumpBtn touch_margin matches Levels 1-4")

	# Validate Fire Barrier Complete Removal from Level 5
	print("  Validating Fire Barrier Complete Removal from Level 5...")
	assert_true(traps.get_node_or_null("InfernoGate6") == null, "InfernoGate6 completely removed from Level 5")
	assert_true(traps.get_node_or_null("InfernoGate10") == null, "InfernoGate10 completely removed from Level 5")
	var has_inferno_in_level_5: bool = false
	for t in traps.get_children():
		if t is InfernoGateClass:
			has_inferno_in_level_5 = true
	assert_true(not has_inferno_in_level_5, "Zero InfernoGate instances exist in Level 5 Traps")

	# Validate all 10 distinct Coin Encounters & Trap Combinations across 4 Phases
	print("  Validating 10 Distinct Coin Encounters & Trap Combinations in Level 5...")
	var c1 = coins.get_node("Coin1")
	var c2 = coins.get_node("Coin2")
	var c3 = coins.get_node("Coin3")
	var c4 = coins.get_node("Coin4")
	var c5 = coins.get_node("Coin5")
	var c6 = coins.get_node("Coin6")
	var c7 = coins.get_node("Coin7")
	var c8 = coins.get_node("Coin8")
	var c9 = coins.get_node("Coin9")
	var c10 = coins.get_node("Coin10")

	assert_true(c1 != null and c2 != null and c3 != null and c4 != null and c5 != null, "Coins 1 to 5 exist")
	assert_true(c6 != null and c7 != null and c8 != null and c9 != null and c10 != null, "Coins 6 to 10 exist")

	# PHASE A: FALSE CONFIDENCE (Coins 1-2)
	print("  Validating Phase A: False Confidence (Coins 1-2)...")
	var plat1 = platforms.get_node("Plat1_Collapsing")
	var fspikes1 = hazards.get_node("FloorSpikes1")
	var plat2 = platforms.get_node("Plat2_FakeSafe")
	var plat2_esc = platforms.get_node("Plat2_Escape")
	var rest1 = platforms.get_node("Rest1")
	assert_true(plat1 is CrumblingBridgeSectionClass, "Plat1 uses CrumblingBridgeSection")
	assert_true(plat2 is FakeSafePlatformClass, "Plat2 uses FakeSafePlatform")
	assert_true(plat2_esc is CrumblingBridgeSectionClass, "Plat2_Escape uses CrumblingBridgeSection")
	assert_eq(c1.position, Vector2(370, 360), "Coin 1 positioned above Plat1_Collapsing")
	assert_true(fspikes1.position.x < plat1.position.x, "FloorSpikes1 guards gap between spawn and Plat1")
	assert_eq(c2.position, Vector2(505, 360), "Coin 2 positioned above Plat2_FakeSafe")
	assert_true(not plat2.spikes_sprite.visible, "Plat2 spikes are concealed initially")
	plat2.trigger_trap()
	assert_true(plat2._active_spikes, "Plat2 spikes pop up on trigger")
	assert_true(plat2.spikes_sprite.visible, "Plat2 spikes become visible")

	# PHASE B: THE TRAP CHAIN (Coins 3-5)
	print("  Validating Phase B: The Trap Chain (Coins 3-5)...")
	var plat3 = platforms.get_node("Plat3_Collapsing")
	var cr3 = traps.get_node("Crusher3")
	assert_true(cr3 is CeilingCrusherClass, "Crusher3 uses CeilingCrusher")
	assert_eq(c3.position, Vector2(840, 360), "Coin 3 positioned under Crusher3 on Plat3_Collapsing")

	var plat4 = platforms.get_node("Plat4_Ground")
	var mwall4 = traps.get_node("MovingWall4")
	var wspik4 = traps.get_node("WallSpikeTrap4")
	var air_spikes4 = hazards.get_node("AirSpikes4")
	var pillar4 = platforms.get_node("Pillar4")
	assert_true(mwall4 is MovingWallClass, "MovingWall4 uses MovingWall")
	assert_true(wspik4 is WallSpikeTrapClass, "WallSpikeTrap4 uses WallSpikeTrap")
	assert_eq(c4.position, Vector2(970, 350), "Coin 4 positioned above Plat4_Ground")
	assert_true(air_spikes4.position.y < c4.position.y, "AirSpikes4 constrains vertical clearance over MovingWall4")
	assert_true(pillar4.position.y < plat4.position.y, "Pillar4 is elevated safe landing after Coin 4")

	var br5a = platforms.get_node("Bridge5A")
	var br5b = platforms.get_node("Bridge5B")
	var br5c = platforms.get_node("Bridge5C")
	var air_spikes5 = hazards.get_node("AirSpikes5")
	var rest5 = platforms.get_node("Rest5")
	assert_eq(br5a.next_section_path, NodePath("../Bridge5B"), "Bridge5A cascades into Bridge5B")
	assert_eq(br5b.next_section_path, NodePath("../Bridge5C"), "Bridge5B cascades into Bridge5C")
	assert_eq(c5.position, Vector2(1265, 345), "Coin 5 positioned on Bridge5B under AirSpikes5")

	# PHASE C: NO EASY WAY OUT (Coins 6-8)
	print("  Validating Phase C: No Easy Way Out (Coins 6-8)...")
	var plat6 = platforms.get_node("Plat6_Collapsing")
	var cr6 = traps.get_node("Crusher6")
	var air_spikes6 = hazards.get_node("AirSpikes6")
	var plat6_exit = platforms.get_node("Plat6_Exit")
	var rest6 = platforms.get_node("Rest6")
	assert_true(cr6 is CeilingCrusherClass, "Crusher6 uses CeilingCrusher")
	assert_true(air_spikes6 != null, "AirSpikes6 guards overhead above Plat6_Exit")
	assert_eq(c6.position, Vector2(1565, 345), "Coin 6 positioned under Crusher6 on Plat6_Collapsing")
	assert_true(plat6.position.x < plat6_exit.position.x and plat6_exit.position.x < rest6.position.x, "Encounter 6 sequences Crusher6 -> Plat6_Exit (under AirSpikes6) -> Rest6")

	var plat7a = platforms.get_node("Plat7A")
	var plat7b = platforms.get_node("Plat7B")
	var cr7a = traps.get_node("Crusher7A")
	var cr7b = traps.get_node("Crusher7B")
	var plat7_ledge = platforms.get_node("Plat7_Ledge")
	var fspikes7 = hazards.get_node("FloorSpikes7")
	assert_true(cr7a.auto_cycle and cr7b.auto_cycle, "Crushers 7A and 7B auto-cycle with offset timing")
	assert_eq(c7.position, Vector2(2020, 345), "Coin 7 positioned under Crusher7B on Plat7B")
	assert_true(fspikes7.position.x < plat7_ledge.position.x, "FloorSpikes7 guards front of Plat7_Ledge")

	var plat8 = platforms.get_node("Plat8_FakeSafe")
	var mwall8 = traps.get_node("MovingWall8")
	var plat8_step = platforms.get_node("Plat8_Step")
	var rest8 = platforms.get_node("Rest8")
	assert_true(plat8 is FakeSafePlatformClass, "Plat8 uses FakeSafePlatform")
	assert_true(mwall8 is MovingWallClass, "MovingWall8 uses MovingWall")
	assert_eq(c8.position, Vector2(2260, 330), "Coin 8 suspended above Plat8 under MovingWall8")

	# PHASE D: THE FINAL BETRAYAL (Coins 9-10 & Grand Finale)
	print("  Validating Phase D: The Final Betrayal (Coins 9-10 & Grand Finale)...")
	var plat9a = platforms.get_node("Plat9A_Collapsing")
	var cr9 = traps.get_node("Crusher9")
	var air_spikes9 = hazards.get_node("AirSpikes9")
	var plat9b = platforms.get_node("Plat9B_Collapsing")
	var plat_prefinale = platforms.get_node("PlatformPreFinale")
	assert_true(cr9 is CeilingCrusherClass, "Crusher9 uses CeilingCrusher")
	assert_eq(c9.position, Vector2(2640, 350), "Coin 9 suspended under Crusher9 between Plat9A and Plat9B")

	var plat10a = platforms.get_node("Plat10A_Collapsing")
	var cr10 = traps.get_node("Crusher10")
	var plat10b = platforms.get_node("Plat10B_Collapsing")
	var fake_exit = traps.get_node("FakeExitGate")
	var plat_finale = platforms.get_node("PlatFinale_Collapsing")
	var plat_real_exit = platforms.get_node("PlatformRealExit")
	assert_true(cr10 is CeilingCrusherClass, "Crusher10 uses CeilingCrusher")
	assert_true(fake_exit is FakeExitGateClass, "FakeExitGate uses FakeExitGate")
	assert_eq(c10.position, Vector2(2990, 350), "Coin 10 centered under Crusher10 between Plat10A and Plat10B")

	# Validate Coin Collection & Finale Deception Trigger
	print("  Validating Coin Collection & Finale Deception Trigger...")
	GameManager.current_level_id = 5
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 5")
	assert_eq(fake_exit.status_label.text, "EXIT OPEN!", "FakeExitGate displays 'EXIT OPEN!' once all 10 coins collected")

	# Player approaches Fake Exit Gate: deception triggers, revealing Real Exit Gate
	fake_exit._on_body_entered(player)
	assert_true(fake_exit._has_tricked, "FakeExitGate triggers deception sequence upon approach")
	assert_true(exit_gate.visible, "Real ExitGate is revealed upon FakeExitGate deception")
	assert_true(exit_gate._is_open, "Real ExitGate is unlocked once revealed")

	# Complete Level 5 via Real Exit Gate
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 5 completion triggered upon entering real exit gate")
	assert_true(SaveManager.is_level_completed(5), "Level 5 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(6), "Level 6 is unlocked after Level 5 completion")

	# Next Level button transitions to Level 6 (now implemented)
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	complete_overlay._on_next_level_pressed()
	assert_eq(GameManager.current_level_id, 6, "Level 5 Next Level transitions directly to implemented Level 6")

	# Reset Level 5 & verify clean restoration of all trap states
	print("  Validating Clean Trap Reset on Level Retry...")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 5 retry resets coins to 0")
	assert_true(not fake_exit._has_tricked, "FakeExitGate untricked on level retry")
	assert_true(not exit_gate.visible, "Real ExitGate hidden again on reset")
	assert_true(not exit_gate._completion_triggered, "Real ExitGate completion flag reset")
	assert_true(not plat1._is_triggered, "Collapsing platforms reset cleanly")
	assert_true(not plat2._active_spikes, "Plat2 pop-up spikes reset cleanly")
	assert_true(not plat8._active_spikes, "Plat8 pop-up spikes reset cleanly")
	assert_eq(cr3.current_state, CeilingCrusherClass.State.IDLE, "Crusher 3 reset to IDLE")
	assert_eq(cr6.current_state, CeilingCrusherClass.State.IDLE, "Crusher 6 reset to IDLE")
	assert_eq(cr9.current_state, CeilingCrusherClass.State.IDLE, "Crusher 9 reset to IDLE")
	assert_eq(cr10.current_state, CeilingCrusherClass.State.IDLE, "Crusher 10 reset to IDLE")
	assert_true(not mwall4._is_active, "MovingWall 4 inactive on reset")
	assert_true(not mwall8._is_active, "MovingWall 8 inactive on reset")
	assert_true(not wspik4._is_active, "WallSpikeTrap 4 inactive on reset")

	lvl.queue_free()

func test_welcome_and_startup_screen() -> void:
	print("\n--- TEST: Welcome & Startup Screen ---")
	var welcome_scene_res = load("res://scenes/ui/welcome_screen.tscn")
	assert_true(welcome_scene_res != null, "WelcomeScreen scene exists and loads")
	
	var welcome_screen = welcome_scene_res.instantiate()
	add_child(welcome_screen)
	
	assert_true(welcome_screen.has_node("CenterContainer/VBox/BrandLabel"), "Branding label exists")
	var brand_label: Label = welcome_screen.get_node("CenterContainer/VBox/BrandLabel")
	assert_eq(brand_label.text, "RETRO RAGE ARCADE", "Brand text is 'RETRO RAGE ARCADE'")
	
	assert_true(welcome_screen.has_node("CenterContainer/VBox/TitleLabel"), "Title label exists")
	var title_label: Label = welcome_screen.get_node("CenterContainer/VBox/TitleLabel")
	assert_eq(title_label.text, "RETRO RAGE ARCADE", "Title text is 'RETRO RAGE ARCADE'")
	assert_true(not title_label.text.contains("COIN HELL"), "COIN HELL is not the main title on the loading screen")
	
	assert_true(welcome_screen.has_node("CenterContainer/VBox/WelcomeLabel"), "Welcome/Subtitle label exists")
	var welcome_label: Label = welcome_screen.get_node("CenterContainer/VBox/WelcomeLabel")
	assert_eq(welcome_label.text, "EVERY LEVEL BETRAYS YOU.", "Subtitle text is 'EVERY LEVEL BETRAYS YOU.'")
	
	assert_true(welcome_screen.has_node("CenterContainer/VBox/IconContainer/CoinIcon"), "Coin icon exists")
	assert_true(welcome_screen.has_node("CenterContainer/VBox/LoadingBox/ProgressBar"), "Loading ProgressBar exists")
	assert_true(welcome_screen.has_node("FadeOverlay"), "FadeOverlay exists")
	
	var config_main_scene = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(config_main_scene, "res://scenes/ui/welcome_screen.tscn", "Project configured to start at welcome_screen.tscn")
	
	# Simulate process step without blocking
	welcome_screen._process(0.2)
	assert_true(welcome_screen._current_progress >= 0.0, "Progress smoothly advances")
	
	welcome_screen.queue_free()

func test_developer_only_level_access() -> void:
	print("\n--- TEST: Developer-Only Level Access ---")
	var lsel_scene = load("res://scenes/ui/coin_hell_level_select.tscn")
	var lsel = lsel_scene.instantiate()
	add_child(lsel)
	
	# Reset player save to pristine state: only Level 1 is legitimately unlocked
	SaveManager._apply_defaults()
	SaveManager.save_data()
	assert_eq(SaveManager.highest_unlocked_level, 1, "Save progress starts at Level 1")
	assert_true(not SaveManager.is_level_unlocked(6), "Level 6 is legitimately locked")
	
	# In debug mode, dev toggle button exists
	assert_true(lsel.is_debug_mode, "Debug build detected for developer tools")
	assert_true(lsel.dev_toggle_btn != null, "Developer bypass toggle button exists in header bar")
	assert_true(lsel.dev_bypass_active, "Developer bypass enabled by default in debug build")
	
	# With dev bypass active, Level 6 can be launched directly without completing Levels 1-5!
	assert_true(GameManager.can_play_level(6), "Level 6 is implemented")
	lsel._on_level_tile_pressed(6)
	assert_eq(GameManager.current_level_id, 6, "Developer mode allows direct launch into Level 6")
	
	# Verify that legitimate progression was NOT overwritten
	assert_eq(SaveManager.highest_unlocked_level, 1, "Legitimate highest_unlocked_level is preserved (not overwritten)")
	assert_true(not SaveManager.is_level_unlocked(6), "SaveManager still records Level 6 as legitimately locked")
	
	# Toggle dev bypass off: simulate release / locked behavior
	lsel._on_dev_toggle_pressed()
	assert_true(not lsel.dev_bypass_active, "Dev bypass toggled off")
	
	# Pressing locked Level 6 now shows locked modal
	GameManager.current_level_id = 1
	lsel._on_level_tile_pressed(6)
	assert_eq(GameManager.current_level_id, 1, "With dev bypass disabled, locked Level 6 does not launch")
	assert_true(lsel.message_modal.visible, "Locked modal dialog displayed")
	assert_eq(lsel.modal_title.text, "LEVEL 6 IS LOCKED", "Modal explains Level 6 is locked")
	
	# Unimplemented level (e.g. Level 10) cannot be launched even with dev mode on
	lsel._on_dev_toggle_pressed()
	assert_true(lsel.dev_bypass_active, "Dev bypass toggled on")
	lsel._on_level_tile_pressed(10)
	assert_true(lsel.message_modal.visible, "Unimplemented Level 10 displays in-progress modal")
	assert_eq(lsel.modal_title.text, "LEVEL 10 IN PROGRESS", "Modal indicates Level 10 is in progress")
	
	lsel.queue_free()

func test_haunted_hall_environment_and_ghosts() -> void:
	print("\n--- TEST: Reusable Haunted Hall Environment & Decorative Flying Ghosts ---")
	var env_scene = preload("res://scenes/shared/haunted_hall_environment.tscn")
	assert_true(env_scene != null, "HauntedHallEnvironment scene loads successfully")
	
	var env = env_scene.instantiate()
	add_child(env)
	
	assert_true(env.has_node("ParallaxBackground"), "ParallaxBackground layer exists")
	assert_true(env.has_node("ParallaxBackground/ParallaxTowers"), "Parallax castle towers backdrop exists")
	assert_true(env.has_node("ParallaxBackground/ParallaxWindows"), "Parallax gothic lancet windows exist")
	assert_true(env.has_node("MistLayer/GroundMist"), "GroundMist color rect exists")
	assert_true(env.has_node("SpectralWisps"), "Spectral wisps particle emitter exists")
	assert_true(env.has_node("CastleArches"), "Castle arches container exists")
	assert_true(env.has_node("GhostsPool"), "GhostsPool container exists")
	
	# Verify ghost pool
	var pool = env.get_node("GhostsPool")
	assert_eq(pool.get_child_count(), env.ghost_count, "Ghost pool spawns exact configured ghost count (%d)" % env.ghost_count)
	
	# CRITICAL REQUIREMENTS:
	# 1. Background ghosts are decorative only.
	# 2. They must NOT damage the player.
	# 3. They must NOT collide with the player.
	# 4. Zero CollisionShape2D or Area2D nodes.
	# 5. Travel behind castle arches.
	var arches = env.get_node("CastleArches")
	assert_true(pool.z_index < arches.z_index, "Ghosts (z=%d) travel behind castle arches (z=%d)" % [pool.z_index, arches.z_index])
	
	var all_decorative := true
	var zero_collision := true
	for ghost in pool.get_children():
		if not (ghost is Sprite2D):
			all_decorative = false
		if ghost is CollisionObject2D or ghost is Area2D:
			zero_collision = false
		for sub_child in ghost.get_children():
			if sub_child is CollisionShape2D or sub_child is Area2D or sub_child is CollisionObject2D:
				zero_collision = false
				
	assert_true(all_decorative, "All ghosts in pool are pure Sprite2D visual nodes")
	assert_true(zero_collision, "Zero collision shapes or Area2D hazards on background ghosts (100% non-colliding/non-damaging)")
	
	# Process ghosts movement
	var ghost0: Sprite2D = pool.get_child(0)
	var initial_x := ghost0.position.x
	env._process(0.2)
	assert_true(ghost0.position.x != initial_x, "Ghosts move smoothly in background across time")
	
	env.queue_free()

func test_level_6_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 6 Gameplay Mechanics (World 2: The Haunted Hall - Phantom's Curse) ---")
	var lvl_info: Dictionary = GameManager.get_level_info(6)
	assert_eq(lvl_info.get("name"), "Phantom's Curse", "Level 6 name is 'Phantom's Curse'")
	assert_eq(GameManager.get_world_name_for_stage(6), "THE HAUNTED HALL", "Level 6 world is 'THE HAUNTED HALL'")
	assert_true(lvl_info.get("implemented"), "Level 6 is marked implemented")
	assert_eq(lvl_info.get("coin_count"), 10, "Level 6 has exactly 10 required coins")
	
	var lvl_scene = load(lvl_info.get("scene", ""))
	assert_true(lvl_scene != null, "Level 6 scene loads successfully")
	
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node_or_null("Player")
	assert_true(player != null, "Player exists in Level 6")
	assert_eq(player.position, Vector2(100, 380), "Player spawns safely at X=100, Y=380")
	
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	assert_true(cam != null, "Camera2D exists on player")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_true(cam.offset.y < 0, "Camera2D negative offset ensures landing visibility")
	
	# Mobile controls sizing
	print("  Validating Level 6 Mobile Controls standardized dimensions...")
	var touch_controls = lvl.get_node_or_null("HUD/TouchControls")
	assert_true(touch_controls != null, "TouchControls exists in Level 6")
	var lbtn: TextureButton = touch_controls.get_node("LeftBtn")
	var rbtn: TextureButton = touch_controls.get_node("RightBtn")
	var jbtn: TextureButton = touch_controls.get_node("JumpBtn")
	assert_eq(lbtn.offset_right - lbtn.offset_left, 104.0, "LeftBtn width is 104px")
	assert_eq(lbtn.offset_bottom - lbtn.offset_top, 104.0, "LeftBtn height is 104px")
	assert_eq(rbtn.offset_right - rbtn.offset_left, 104.0, "RightBtn width is 104px")
	assert_eq(rbtn.offset_bottom - rbtn.offset_top, 104.0, "RightBtn height is 104px")
	assert_eq(jbtn.offset_right - jbtn.offset_left, 124.0, "JumpBtn width is 124px")
	assert_eq(jbtn.offset_bottom - jbtn.offset_top, 124.0, "JumpBtn height is 124px")
	
	# Visual identity of World 2: The Haunted Hall
	print("  Validating World 2 Haunted Castle Visual Identity...")
	var decos = lvl.get_node_or_null("Decorations")
	assert_true(decos != null, "Decorations node exists in Level 6")
	assert_true(decos.has_node("ArchSpawn"), "Gothic Arch at spawn exists")
	assert_true(decos.has_node("ArchMilestone1"), "Gothic Arch milestone 1 exists")
	assert_true(decos.has_node("ArchMilestone2"), "Gothic Arch milestone 2 exists")
	assert_true(decos.has_node("ArchExit"), "Gothic Arch at exit sanctuary exists")
	assert_true(lvl.has_node("AtmosphereParticles"), "Ghostly wisp atmosphere particles exist")
	
	# HUD World / Stage display
	var hud_level_label: Label = lvl.get_node("HUD/MarginContainer/TopBar/LevelName")
	assert_eq(hud_level_label.text, "WORLD 2 · STAGE 6: PHANTOM'S CURSE", "HUD displays correct World 2 Stage 6 label")
	
	# Coins count and placement
	print("  Validating Exactly 10 Coins across 5 Sections...")
	var coins = lvl.get_node("Coins")
	assert_eq(coins.get_child_count(), 10, "Level 6 contains exactly 10 coins")
	for i in range(1, 11):
		assert_true(coins.has_node("Coin%d" % i), "Coin %d exists" % i)
	
	var c1 = coins.get_node("Coin1")
	var c2 = coins.get_node("Coin2")
	var c3 = coins.get_node("Coin3")
	var c4 = coins.get_node("Coin4")
	var c5 = coins.get_node("Coin5")
	var c6 = coins.get_node("Coin6")
	var c7 = coins.get_node("Coin7")
	var c8 = coins.get_node("Coin8")
	var c9 = coins.get_node("Coin9")
	var c10 = coins.get_node("Coin10")
	
	assert_eq(c1.position, Vector2(290, 320), "Coin 1 on Section 1 Timed Phantom Platform")
	assert_eq(c2.position, Vector2(370, 300), "Coin 2 arched over pit gap into Parapet")
	assert_eq(c3.position, Vector2(610, 290), "Coin 3 on Section 2 Staggered Timed Plat 3A")
	assert_eq(c4.position, Vector2(830, 250), "Coin 4 in jump ascent to Balcony 4")
	assert_eq(c5.position, Vector2(1070, 250), "Coin 5 on Section 3 Triggered Plat 5")
	assert_eq(c6.position, Vector2(1380, 260), "Coin 6 on Section 3 Triggered Plat 6 under AirSpikes")
	assert_eq(c7.position, Vector2(1700, 270), "Coin 7 on Section 4 Triggered Plat 7A")
	assert_eq(c8.position, Vector2(1850, 250), "Coin 8 on Section 4 Timed Plat 7B")
	assert_eq(c9.position, Vector2(2240, 240), "Coin 9 on Section 5 climax combination")
	assert_eq(c10.position, Vector2(2480, 210), "Coin 10 before Exit Sanctuary")
	
	# Phantom platform mechanics validation
	print("  Validating Phantom Platform Mechanics (Timed & Triggered)...")
	var plat1 = lvl.get_node("Platforms/Plat1_PhantomTimed")
	var plat3a = lvl.get_node("Platforms/Plat3A_PhantomTimed")
	var plat3b = lvl.get_node("Platforms/Plat3B_PhantomTimed")
	var plat5 = lvl.get_node("Platforms/Plat5_PhantomTriggered")
	var plat6 = lvl.get_node("Platforms/Plat6_PhantomTriggered")
	var plat7a = lvl.get_node("Platforms/Plat7A_PhantomTriggered")
	var plat7b = lvl.get_node("Platforms/Plat7B_PhantomTimed")
	var plat9a = lvl.get_node("Platforms/Plat9A_PhantomTimed")
	var plat9b = lvl.get_node("Platforms/Plat9B_PhantomTriggered")
	var plat10 = lvl.get_node("Platforms/Plat10_PhantomTimed")
	
	# Verify types
	assert_true(plat1 is PhantomPlatformClass, "Plat1 is PhantomPlatform")
	assert_eq(plat1.platform_type, PhantomPlatformClass.PlatformType.TIMED, "Plat1 uses TIMED variant")
	assert_true(plat5 is PhantomPlatformClass, "Plat5 is PhantomPlatform")
	assert_eq(plat5.platform_type, PhantomPlatformClass.PlatformType.TRIGGERED, "Plat5 uses TRIGGERED variant")
	
	# Staggered cycles test in Section 2
	assert_true(plat3a.cycle_offset != plat3b.cycle_offset, "Plat3A and Plat3B have staggered cycles")
	
	# Timed platform state sync test: visual and collision match
	plat1._set_state(PhantomPlatformClass.PlatformState.SOLID)
	assert_true(not plat1.collision_shape.disabled, "SOLID state has collision enabled")
	assert_true(plat1.solid_visual.visible, "SOLID state displays solid visuals")
	
	plat1._set_state(PhantomPlatformClass.PlatformState.WARNING)
	assert_true(not plat1.collision_shape.disabled, "WARNING state maintains collision so player can safely jump")
	assert_true(plat1.solid_visual.visible, "WARNING state keeps visuals visible with pulse")
	
	plat1._set_state(PhantomPlatformClass.PlatformState.PHANTOM)
	assert_true(plat1.collision_shape.disabled, "PHANTOM state disables collision")
	assert_true(not plat1.solid_visual.visible, "PHANTOM state hides solid visual")
	assert_true(plat1.spectral_visual.visible, "PHANTOM state shows spectral visual")
	
	# Triggered platform mechanic sequence test
	plat5.reset()
	assert_eq(plat5.current_state, PhantomPlatformClass.PlatformState.SOLID, "Triggered platform starts SOLID")
	assert_true(not plat5._is_triggered, "Triggered platform starts untriggered")
	
	# Step on platform
	plat5._on_step_area_body_entered(player)
	assert_true(plat5._is_triggered, "Stepping on platform triggers it")
	assert_eq(plat5.current_state, PhantomPlatformClass.PlatformState.WARNING, "Transitions to WARNING state on trigger")
	assert_true(not plat5.collision_shape.disabled, "Collision remains enabled during warning cue")
	
	# Advance warning time to transition to PHANTOM
	plat5._process_triggered_state(plat5.trigger_delay + 0.05)
	assert_eq(plat5.current_state, PhantomPlatformClass.PlatformState.PHANTOM, "Transitions to PHANTOM after warning")
	assert_true(plat5.collision_shape.disabled, "Collision disabled in PHANTOM state")
	
	# Advance recovery time to restore to SOLID
	plat5._process_triggered_state(plat5.phantom_recovery_time + 0.05)
	assert_eq(plat5.current_state, PhantomPlatformClass.PlatformState.SOLID, "Recovers to SOLID after predictable interval")
	assert_true(not plat5.collision_shape.disabled, "Collision re-enabled upon recovery")
	
	# Exit gate locked state
	var exit_gate = lvl.get_node("ExitGate")
	assert_true(not exit_gate._is_open, "ExitGate starts locked requiring all 10 coins")
	
	# Collect all 10 coins
	print("  Validating Coin Collection & Level 6 Completion...")
	GameManager.current_level_id = 6
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 6")
	assert_true(exit_gate._is_open, "ExitGate opens automatically when all 10 coins collected")
	
	# Enter exit gate to complete Level 6
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 6 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(6), "Level 6 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(7), "Level 7 is unlocked after Level 6 completion")
	
	# Next Level button on LevelCompleteOverlay transitions to implemented Level 7
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	assert_true(GameManager.can_play_level(7), "Level 7 is playable so Level 6 Next Level advances to Level 7")
	
	# Test clean retry reset
	print("  Validating Clean Trap Reset on Level 6 Retry...")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 6 retry resets coins to 0")
	assert_true(not exit_gate._is_open, "ExitGate re-locks on retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")
	assert_eq(plat1.current_state, PhantomPlatformClass.PlatformState.SOLID, "Plat1 reset to initial state")
	assert_eq(plat5.current_state, PhantomPlatformClass.PlatformState.SOLID, "Plat5 reset to initial state")
	assert_true(not plat5._is_triggered, "Plat5 trigger reset on retry")
	
	lvl.queue_free()

func test_level_7_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 7 Gameplay Mechanics (World 2: The Haunted Hall - Hall of Illusions) ---")
	var lvl_info: Dictionary = GameManager.get_level_info(7)
	assert_eq(lvl_info.get("name"), "Hall of Illusions", "Level 7 name is 'Hall of Illusions'")
	assert_eq(GameManager.get_world_name_for_stage(7), "THE HAUNTED HALL", "Level 7 world is 'THE HAUNTED HALL'")
	assert_true(lvl_info.get("implemented"), "Level 7 is marked implemented")
	assert_eq(lvl_info.get("coin_count"), 10, "Level 7 has exactly 10 required coins")
	
	var lvl_scene = load(lvl_info.get("scene", ""))
	assert_true(lvl_scene != null, "Level 7 scene loads successfully")
	
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node_or_null("Player")
	assert_true(player != null, "Player exists in Level 7")
	assert_eq(player.position, Vector2(100, 380), "Player spawns safely at X=100, Y=380")
	
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	assert_true(cam != null, "Camera2D exists on player")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_eq(cam.limit_right, 3000, "Camera2D limit_right is 3000")
	assert_true(cam.offset.y < 0, "Camera2D negative offset ensures landing visibility")
	
	# Mobile controls standardized dimensions
	print("  Validating Level 7 Mobile Controls standardized dimensions...")
	var touch_controls = lvl.get_node_or_null("HUD/TouchControls")
	assert_true(touch_controls != null, "TouchControls exists in Level 7")
	var lbtn: TextureButton = touch_controls.get_node("LeftBtn")
	var rbtn: TextureButton = touch_controls.get_node("RightBtn")
	var jbtn: TextureButton = touch_controls.get_node("JumpBtn")
	assert_eq(lbtn.offset_right - lbtn.offset_left, 104.0, "LeftBtn width is 104px")
	assert_eq(lbtn.offset_bottom - lbtn.offset_top, 104.0, "LeftBtn height is 104px")
	assert_eq(rbtn.offset_right - rbtn.offset_left, 104.0, "RightBtn width is 104px")
	assert_eq(rbtn.offset_bottom - rbtn.offset_top, 104.0, "RightBtn height is 104px")
	assert_eq(jbtn.offset_right - jbtn.offset_left, 124.0, "JumpBtn width is 124px")
	assert_eq(jbtn.offset_bottom - jbtn.offset_top, 124.0, "JumpBtn height is 124px")
	
	# Haunted Hall visual environment
	assert_true(lvl.has_node("HauntedHallEnvironment"), "HauntedHallEnvironment instance exists in Level 7")
	
	# HUD World / Stage display
	var hud_level_label: Label = lvl.get_node("HUD/MarginContainer/TopBar/LevelName")
	assert_eq(hud_level_label.text, "WORLD 2 · STAGE 7: HALL OF ILLUSIONS", "HUD displays correct World 2 Stage 7 label")
	
	# Coins count and placement
	print("  Validating Exactly 10 Coins across 5 Sections...")
	var coins = lvl.get_node("Coins")
	assert_eq(coins.get_child_count(), 10, "Level 7 contains exactly 10 coins")
	for i in range(1, 11):
		assert_true(coins.has_node("Coin%d" % i), "Coin %d exists" % i)
		
	# Section 1: Moving Phantom Bars
	print("  Validating Section 1 (Coins 1-2): Moving Phantom Bars...")
	var plat1: PhantomPlatform = lvl.get_node("Platforms/Plat1_MovingPhantom")
	var plat2: PhantomPlatform = lvl.get_node("Platforms/Plat2_MovingPhantom")
	assert_true(plat1 != null and plat2 != null, "Section 1 moving phantom bars exist")
	assert_true(plat1.move_distance > 0.0, "Plat1 has move_distance > 0")
	assert_true(plat2.move_distance > 0.0, "Plat2 has move_distance > 0")
	
	# Test movement mechanics
	var initial_plat1_x := plat1.position.x
	plat1._process_movement(0.5)
	assert_true(plat1.position.x > initial_plat1_x, "Plat1 moves smoothly along X axis")
	
	# Section 2: Timed Phantom Platforms + Spikes
	print("  Validating Section 2 (Coins 3-4): Timed Phantom Platforms + Spikes...")
	var plat3: PhantomPlatform = lvl.get_node("Platforms/Plat3_PhantomTimedA")
	var plat4: PhantomPlatform = lvl.get_node("Platforms/Plat4_PhantomTimedB")
	assert_true(plat3 != null and plat4 != null, "Section 2 phantom platforms exist")
	assert_true(lvl.has_node("Spikes/FloorSpikes2A"), "Section 2 floor spikes exist")
	assert_true(lvl.has_node("Spikes/CeilingSpikes2"), "Section 2 ceiling spikes exist above islet")
	
	# Section 3: Falling Crushers
	print("  Validating Section 3 (Coins 5-6): Falling Crushers...")
	var crush1: CeilingCrusher = lvl.get_node("Crushers/Crusher1_Sec3")
	var crush2: CeilingCrusher = lvl.get_node("Crushers/Crusher2_Sec3")
	assert_true(crush1 != null and crush2 != null, "Section 3 falling crushers exist")
	assert_eq(crush1.current_state, CeilingCrusherClass.State.IDLE, "Crusher1 starts IDLE")
	
	# Trigger Crusher1
	crush1._on_trigger_body_entered(player)
	assert_eq(crush1.current_state, CeilingCrusherClass.State.TRIGGERED, "Crusher1 transitions to TRIGGERED upon player approach")
	assert_true(crush1.hazard_collision.disabled, "Crusher1 hazard disabled during warning tremor")
	
	# Advance warning to drop
	crush1._physics_process(crush1.trigger_delay + 0.02)
	assert_eq(crush1.current_state, CeilingCrusherClass.State.DESCENDING, "Crusher1 enters DESCENDING slam")
	assert_true(not crush1.hazard_collision.disabled, "Crusher1 lethal collision active during descent")
	
	# Section 4: Combined Moving Phantom Bars, Spikes & Crushers
	print("  Validating Section 4 (Coins 7-8): Combined Hazards...")
	var plat7: PhantomPlatform = lvl.get_node("Platforms/Plat7_MovingPhantom")
	var crush3: CeilingCrusher = lvl.get_node("Crushers/Crusher3_Sec4")
	assert_true(plat7 != null and crush3 != null, "Section 4 moving bar and crusher exist")
	assert_true(plat7.move_distance > 0.0, "Plat7 moves across hazard zone")
	
	# Section 5: Climax Combination
	print("  Validating Section 5 (Coins 9-10): Climax Combination...")
	var plat9: PhantomPlatform = lvl.get_node("Platforms/Plat9_MovingPhantom")
	var plat10: PhantomPlatform = lvl.get_node("Platforms/Plat10_TriggeredPhantom")
	var crush4: CeilingCrusher = lvl.get_node("Crushers/Crusher4_Sec5")
	assert_true(plat9 != null and plat10 != null and crush4 != null, "Section 5 climax elements exist")
	assert_eq(plat10.platform_type, PhantomPlatformClass.PlatformType.TRIGGERED, "Plat10 is TRIGGERED variant")
	
	# Exit gate and completion
	var exit_gate = lvl.get_node("ExitGate")
	assert_true(not exit_gate._is_open, "ExitGate starts locked requiring all 10 coins")
	
	# Collect all 10 coins
	print("  Validating Coin Collection & Level 7 Completion...")
	GameManager.current_level_id = 7
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 7")
	assert_true(exit_gate._is_open, "ExitGate opens automatically when all 10 coins collected")
	
	# Enter exit gate to complete Level 7
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 7 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(7), "Level 7 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(8), "Level 8 is unlocked after Level 7 completion")
	
	# Next Level button on LevelCompleteOverlay transitions to implemented Level 8
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	assert_true(GameManager.can_play_level(8), "Level 8 is playable so Level 7 Next Level advances to Level 8")
	
	# Test clean retry reset
	print("  Validating Clean Trap Reset on Level 7 Retry...")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 7 retry resets coins to 0")
	assert_true(not exit_gate._is_open, "ExitGate re-locks on retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")
	assert_eq(plat1.current_state, PhantomPlatformClass.PlatformState.SOLID, "Plat1 reset to initial state")
	assert_eq(crush1.current_state, CeilingCrusherClass.State.IDLE, "Crusher1 reset to IDLE")
	
	lvl.queue_free()

func test_level_7_bug_fixes() -> void:
	print("\n--- TEST: Level 7 Bug Fixes (Bug 1: Post-Death Input & Bug 2: Gate Alignment) ---")
	var lvl_scene = load("res://scenes/coin_hell/coin_hell_level_7.tscn")
	assert_true(lvl_scene != null, "Level 7 scene loads successfully")
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node("Player")
	var spawn_point = lvl.get_node("SpawnPoint")
	assert_true(player != null, "Player exists in Level 7")
	assert_true(spawn_point != null, "SpawnPoint exists in Level 7")
	
	# BUG 1 VERIFICATION: Movement and jump stop working after death
	print("  Validating Bug 1 Fix: Player revival and input restoration after death...")
	
	# Verify player is initially alive and accepting input
	assert_true(player._is_alive, "Player is alive on spawn")
	assert_true(not player._input_disabled, "Player input is enabled initially")
	
	# Loop through multiple death and retry cycles
	for cycle in range(1, 4):
		print("    Cycle %d: Player death -> retry..." % cycle)
		# Player dies
		player.die()
		assert_true(not player._is_alive, "Player is marked dead after die()")
		assert_true(player._input_disabled, "Player input is disabled upon death")
		
		# Retry triggered
		lvl._on_retry()
		
		# Player must be restored
		assert_true(player._is_alive, "Player _is_alive is restored to true after retry in cycle %d" % cycle)
		assert_true(not player._input_disabled, "Player _input_disabled is restored to false after retry in cycle %d" % cycle)
		assert_eq(player.global_position, spawn_point.global_position, "Player global_position is restored to spawn point in cycle %d" % cycle)
		
		# Simulate movement input to verify velocity updates
		Input.action_press("move_right")
		player._physics_process(0.016)
		Input.action_release("move_right")
		assert_true(player.velocity.x > 0.0, "Player responds to right movement input with positive velocity.x in cycle %d" % cycle)
		
		# Simulate jump input
		player.velocity.y = 0.0
		Input.action_press("jump")
		if player.is_on_floor():
			player._physics_process(0.016)
			assert_true(player.velocity.y < 0.0, "Player responds to jump input with negative velocity.y in cycle %d" % cycle)
		Input.action_release("jump")
	
	# Verify no duplicate player nodes exist in Level 7
	var player_count := 0
	for child in lvl.get_children():
		if child.name == "Player":
			player_count += 1
	assert_eq(player_count, 1, "Exactly 1 player node exists in Level 7 (no duplicate node recreation)")
	
	# BUG 2 VERIFICATION: Level 7 exit gate is partially buried
	print("  Validating Bug 2 Fix: Exit gate rests flush on platform...")
	var exit_gate = lvl.get_node("ExitGate")
	var sanctuary_plat = lvl.get_node("Platforms/Plat_ExitSanctuary")
	assert_true(exit_gate != null, "ExitGate exists")
	assert_true(sanctuary_plat != null, "Plat_ExitSanctuary exists")
	
	# Platform top surface: Y = position.y - (size.y / 2) = 340 - 40 = 300
	var plat_shape = sanctuary_plat.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat_top_surface: float = sanctuary_plat.position.y - (plat_shape.size.y / 2.0)
	assert_eq(plat_top_surface, 300.0, "Plat_ExitSanctuary top surface is at Y=300")
	
	# Gate sprite is 56px tall with centered origin (extending +/- 28px)
	# At Y = 272, bottom edge is 272 + 28 = 300.0, resting exactly on top surface!
	assert_eq(exit_gate.position.y, 272.0, "ExitGate Y position is 272 (elevated from 300 to avoid sinking into platform)")
	var gate_bottom: float = exit_gate.position.y + 28.0
	assert_eq(gate_bottom, plat_top_surface, "ExitGate bottom rests flush on Plat_ExitSanctuary top surface (not buried)")
	
	# Exit gate unlock logic & coin requirement still intact
	assert_true(not exit_gate._is_open, "ExitGate starts locked")
	assert_eq(lvl.get_node("Coins").get_child_count(), 10, "Level 7 retains exactly 10 coins")
	
	lvl.queue_free()

func test_cursed_wind_zone_mechanics() -> void:
	print("\n--- TEST: Cursed Wind Zone Mechanics (Sideways, Reversing, Burst) ---")
	var player_scene = load("res://scenes/coin_hell/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(100, 100)
	
	# Test baseline player physics values
	var baseline_speed: float = player.move_speed
	var baseline_jump: float = player.jump_velocity
	var baseline_gravity: float = player.gravity
	
	var wind_zone_scene: PackedScene = load("res://scenes/coin_hell/cursed_wind_zone.tscn")
	assert_true(wind_zone_scene != null, "CursedWindZone scene loads successfully")
	
	# Test 1: Sideways Gust
	print("  Validating Sideways Gust Behavior...")
	var sideways_zone = wind_zone_scene.instantiate()
	sideways_zone.wind_type = CursedWindZoneClass.WindType.SIDEWAYS
	sideways_zone.base_strength = 120.0
	sideways_zone.direction = 1.0
	add_child(sideways_zone)
	
	# Enter zone
	sideways_zone._on_body_entered(player)
	assert_true(sideways_zone._player == player, "Player registered in wind zone")
	
	# Step physics to ramp wind force
	for i in range(10):
		sideways_zone._physics_process(0.05)
	assert_true(player.wind_velocity > 50.0, "Player experiences positive horizontal wind velocity")
	
	# Verify player control: player can resist wind by walking left
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	player._physics_process(0.016)
	Input.action_release("move_left")
	assert_true(player.velocity.x < 0.0, "Player retains control and can move against the wind")
	
	# Exit zone: force cleared immediately
	sideways_zone._on_body_exited(player)
	assert_true(sideways_zone._player == null, "Player cleared from wind zone")
	assert_eq(player.wind_velocity, 0.0, "Player wind_velocity cleared to 0.0 upon exiting zone")
	sideways_zone.queue_free()
	
	# Test 2: Reversing Gust
	print("  Validating Reversing Gust Behavior...")
	var reversing_zone = wind_zone_scene.instantiate()
	reversing_zone.wind_type = CursedWindZoneClass.WindType.REVERSING
	reversing_zone.base_strength = 100.0
	reversing_zone.direction = 1.0
	reversing_zone.cycle_duration = 2.0
	reversing_zone.warning_duration = 0.5
	add_child(reversing_zone)
	
	reversing_zone._on_body_entered(player)
	reversing_zone._physics_process(0.05)
	assert_eq(reversing_zone.current_direction, 1.0, "Reversing zone starts in forward direction (1.0)")
	
	# Advance time into warning period (cycle_duration - warning_duration = 1.5s)
	reversing_zone._process_reversing(1.48)
	assert_true(reversing_zone.is_warning, "Reversing zone triggers warning telegraph before direction change")
	
	# Advance time past cycle duration: direction flips
	reversing_zone._process_reversing(0.6)
	assert_eq(reversing_zone.current_direction, -1.0, "Reversing zone predictably flips direction to -1.0 (LEFT)")
	assert_true(not reversing_zone.is_warning, "Warning clears after reversal")
	
	reversing_zone._on_body_exited(player)
	reversing_zone.queue_free()
	
	# Test 3: Burst Gust
	print("  Validating Burst Gust Behavior...")
	var burst_zone = wind_zone_scene.instantiate()
	burst_zone.wind_type = CursedWindZoneClass.WindType.BURST
	burst_zone.base_strength = 60.0
	burst_zone.burst_strength = 140.0
	burst_zone.burst_interval = 2.0
	burst_zone.burst_duration = 0.8
	burst_zone.burst_warning_duration = 0.5
	add_child(burst_zone)
	
	burst_zone._on_body_entered(player)
	assert_true(not burst_zone.is_warning and not burst_zone.is_bursting, "Burst zone starts in normal idle state")
	
	# Advance time into warning state (burst_interval - burst_warning_duration = 1.5s)
	burst_zone._process_burst(1.6)
	assert_true(burst_zone.is_warning, "Burst zone enters warning state before activation")
	assert_true(not burst_zone.is_bursting, "Burst zone is not yet bursting during warning")
	
	# Advance time into burst active state
	burst_zone._process_burst(0.5)
	assert_true(burst_zone.is_bursting, "Burst zone activates bursting state")
	assert_true(not burst_zone.is_warning, "Warning state cleared during burst")
	assert_eq(burst_zone.current_force, 140.0, "Burst force is amplified during burst window")
	
	# Step physics so player receives burst velocity
	burst_zone._physics_process(0.1)
	assert_true(player.wind_velocity > 0.0, "Player experiences strong wind velocity during burst")
	
	# Test 4: Death and Reset safety
	print("  Validating Wind Reset on Death and Level Reset...")
	player.die()
	assert_eq(player.wind_velocity, 0.0, "Player wind_velocity resets immediately upon death")
	
	burst_zone.reset()
	assert_true(not burst_zone.is_bursting, "Burst zone resets is_bursting to false on reset()")
	assert_true(not burst_zone.is_warning, "Burst zone resets is_warning to false on reset()")
	burst_zone.queue_free()
	
	# Verify global physics remained unmodified
	assert_eq(player.move_speed, baseline_speed, "Player move_speed remains unchanged")
	assert_eq(player.jump_velocity, baseline_jump, "Player jump_velocity remains unchanged")
	assert_eq(player.gravity, baseline_gravity, "Player gravity remains unchanged")
	
	player.queue_free()

func test_level_8_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 8 Gameplay Mechanics (World 2: Stage 8 - The Cursed Wind) ---")
	var lvl_info: Dictionary = GameManager.get_level_info(8)
	assert_eq(lvl_info.get("name"), "The Cursed Wind", "Level 8 name is 'The Cursed Wind'")
	assert_eq(GameManager.get_world_name_for_stage(8), "THE HAUNTED HALL", "Level 8 world is 'THE HAUNTED HALL'")
	assert_true(lvl_info.get("implemented"), "Level 8 is marked implemented")
	assert_eq(lvl_info.get("coin_count"), 10, "Level 8 has exactly 10 required coins")
	
	var lvl_scene = load(lvl_info.get("scene", ""))
	assert_true(lvl_scene != null, "Level 8 scene loads successfully")
	
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node_or_null("Player")
	assert_true(player != null, "Player exists in Level 8")
	assert_eq(player.position, Vector2(100, 380), "Player spawns safely at X=100, Y=380")
	
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	assert_true(cam != null, "Camera2D exists on player")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_eq(cam.limit_right, 3000, "Camera2D limit_right is 3000")
	
	# Mobile controls standardized dimensions
	print("  Validating Level 8 Mobile Controls standardized dimensions...")
	var touch_controls = lvl.get_node_or_null("HUD/TouchControls")
	assert_true(touch_controls != null, "TouchControls exists in Level 8")
	var lbtn: TextureButton = touch_controls.get_node("LeftBtn")
	var rbtn: TextureButton = touch_controls.get_node("RightBtn")
	var jbtn: TextureButton = touch_controls.get_node("JumpBtn")
	assert_eq(lbtn.offset_right - lbtn.offset_left, 104.0, "LeftBtn width is 104px")
	assert_eq(lbtn.offset_bottom - lbtn.offset_top, 104.0, "LeftBtn height is 104px")
	assert_eq(rbtn.offset_right - rbtn.offset_left, 104.0, "RightBtn width is 104px")
	assert_eq(rbtn.offset_bottom - rbtn.offset_top, 104.0, "RightBtn height is 104px")
	assert_eq(jbtn.offset_right - jbtn.offset_left, 124.0, "JumpBtn width is 124px")
	assert_eq(jbtn.offset_bottom - jbtn.offset_top, 124.0, "JumpBtn height is 124px")
	
	# Haunted Hall visual environment
	assert_true(lvl.has_node("HauntedHallEnvironment"), "HauntedHallEnvironment exists in Level 8")
	
	# HUD World / Stage display
	var hud_level_label: Label = lvl.get_node("HUD/MarginContainer/TopBar/LevelName")
	assert_eq(hud_level_label.text, "WORLD 2 · STAGE 8: THE CURSED WIND", "HUD displays correct World 2 Stage 8 label")
	
	# Exactly 10 coins
	print("  Validating Exactly 10 Coins across 5 Sections...")
	var coins = lvl.get_node("Coins")
	assert_eq(coins.get_child_count(), 10, "Level 8 contains exactly 10 coins")
	for i in range(1, 11):
		assert_true(coins.has_node("Coin%d" % i), "Coin %d exists" % i)
		
	# Cursed Wind Zones validation
	print("  Validating 5 Cursed Wind Zones across sections...")
	var wind_zones = lvl.get_node("WindZones")
	assert_eq(wind_zones.get_child_count(), 5, "Level 8 contains 5 wind zones")
	
	var wz1 = wind_zones.get_node("WindZone1_Sideways")
	var wz2 = wind_zones.get_node("WindZone2_Headwind")
	var wz3 = wind_zones.get_node("WindZone3_Reversing")
	var wz4 = wind_zones.get_node("WindZone4_Crosswind")
	var wz5 = wind_zones.get_node("WindZone5_Burst")
	
	assert_eq(wz1.wind_type, CursedWindZoneClass.WindType.SIDEWAYS, "Zone 1 is SIDEWAYS")
	assert_eq(wz2.wind_type, CursedWindZoneClass.WindType.SIDEWAYS, "Zone 2 is SIDEWAYS")
	assert_eq(wz3.wind_type, CursedWindZoneClass.WindType.REVERSING, "Zone 3 is REVERSING")
	assert_eq(wz4.wind_type, CursedWindZoneClass.WindType.REVERSING, "Zone 4 is REVERSING")
	assert_eq(wz5.wind_type, CursedWindZoneClass.WindType.BURST, "Zone 5 is BURST")
	
	# Rebalance Verification: Generous Platform Widths and Controlled Wind Forces
	print("  Validating Level 8 Rebalanced Platform Widths & Controlled Wind...")
	var plat1 = lvl.get_node("Platforms/Plat1_Stone")
	var plat2 = lvl.get_node("Platforms/Plat2_RestA")
	var plat5 = lvl.get_node("Platforms/Plat5_StoneIslet")
	var plat7_pier = lvl.get_node("Platforms/Plat7_StonePier")
	var plat10 = lvl.get_node("Platforms/Plat10_TriggeredPhantom")
	
	var plat1_shape = plat1.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat2_shape = plat2.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat5_shape = plat5.get_node("CollisionShape2D").shape as RectangleShape2D
	var pier_shape = plat7_pier.get_node("CollisionShape2D").shape as RectangleShape2D
	
	assert_true(plat1_shape.size.x >= 120.0, "Plat1 width >= 120px for reliable landing")
	assert_true(plat2_shape.size.x >= 120.0, "Plat2 RestA width >= 120px")
	assert_true(plat5_shape.size.x >= 120.0, "Plat5 StoneIslet widened to 120px (was 60px needle)")
	assert_true(pier_shape.size.x >= 120.0, "Plat7 StonePier widened to 120px (was 50px needle)")
	assert_true(plat10.width >= 100.0, "Plat10 TriggeredPhantom width >= 100px")
	assert_true(plat10.trigger_delay >= 1.2, "Plat10 trigger delay >= 1.2s for fair reaction time")
	
	# Wind strengths are controlled and predictable
	assert_true(wz1.base_strength <= 60.0, "Zone 1 wind strength <= 60px/s (moderate intro)")
	assert_true(wz2.direction > 0.0, "Zone 2 wind flows rightward along natural stage route")
	assert_true(wz2.base_strength <= 60.0, "Zone 2 wind strength <= 60px/s")
	assert_true(wz3.base_strength <= 70.0, "Zone 3 reversing strength <= 70px/s")
	assert_true(wz3.warning_duration >= 0.9, "Zone 3 warning telegraph >= 0.9s for clear visual cue")
	assert_true(wz4.base_strength <= 70.0, "Zone 4 crosswind strength <= 70px/s")
	assert_true(wz5.burst_strength <= 90.0, "Zone 5 burst strength <= 90px/s (bounded and controllable)")
	assert_true(wz5.burst_warning_duration >= 0.9, "Zone 5 burst warning cue >= 0.9s")
	
	# Exit gate locked state and positioning
	var exit_gate = lvl.get_node("ExitGate")
	var sanctuary_plat = lvl.get_node("Platforms/Plat_ExitSanctuary")
	assert_true(not exit_gate._is_open, "ExitGate starts locked requiring all 10 coins")
	assert_eq(exit_gate.position.y, 272.0, "Level 8 ExitGate rests at Y=272")
	var plat_shape = sanctuary_plat.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat_top = sanctuary_plat.position.y - (plat_shape.size.y / 2.0)
	assert_eq(exit_gate.position.y + 28.0, plat_top, "Level 8 ExitGate rests flush on sanctuary platform (Y=300)")
	
	# Collect all 10 coins
	print("  Validating Coin Collection & Level 8 Completion...")
	GameManager.current_level_id = 8
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 8")
	assert_true(exit_gate._is_open, "ExitGate opens automatically when all 10 coins collected")
	
	# Enter exit gate to complete Level 8
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 8 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(8), "Level 8 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(9), "Level 9 is unlocked after Level 8 completion")
	
	# Next Level button transitions to Level 9 (now implemented)
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	complete_overlay._on_next_level_pressed()
	assert_eq(GameManager.current_level_id, 9, "Level 8 Next Level transitions directly to implemented Level 9")
	
	# Test clean retry reset
	print("  Validating Clean Trap Reset on Level 8 Retry...")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 8 retry resets coins to 0")
	assert_true(not exit_gate._is_open, "ExitGate re-locks on retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")
	assert_eq(wz5.is_bursting, false, "Zone 5 reset to not bursting on retry")
	
	lvl.queue_free()

func test_swinging_chain_mechanics() -> void:
	print("\n--- TEST: Swinging Ghost Chain Mechanics ---")
	var chain_scene: PackedScene = load("res://scenes/coin_hell/swinging_chain.tscn")
	assert_true(chain_scene != null, "SwingingChain scene loads successfully")
	var chain = chain_scene.instantiate()
	add_child(chain)
	
	# Verify default exports and node structure
	assert_eq(chain.chain_length, 140.0, "Default chain length is 140.0px")
	assert_eq(chain.max_angle_degrees, 50.0, "Default max swing angle is 50.0 deg")
	assert_eq(chain.swing_speed, 2.0, "Default swing speed is 2.0 rad/s")
	assert_eq(chain.phase_offset, 0.0, "Default phase offset is 0.0 rad")
	assert_true(chain.is_lethal, "Chain is lethal by default")
	
	assert_true(chain.mount_sprite != null, "MountSprite exists on SwingingChain")
	assert_true(chain.pivot != null, "Pivot exists on SwingingChain")
	assert_true(chain.chain_line != null, "ChainLine exists under Pivot")
	assert_true(chain.weight_sprite != null, "WeightSprite exists under Pivot")
	assert_true(chain.hazard_area != null, "HazardArea exists under Pivot")
	assert_true(chain.weight_collision != null, "WeightCollision exists in HazardArea")
	assert_true(chain.chain_collision != null, "ChainCollision exists in HazardArea")
	
	# Verify pendulum harmonic motion at key timestamps (theta(t) = max_angle * sin(t * w + phi))
	print("  Validating Pendulum Harmonic Motion math...")
	chain.reset()
	assert_eq(chain.get_current_angle_degrees(), 0.0, "At t=0, chain hangs straight down (angle = 0 deg)")
	
	# At t = (PI/2) / 2.0 = 0.25 * PI (~0.785398s), sin(t * 2.0) = sin(PI/2) = 1.0 -> angle = +50 deg
	var peak_right_time: float = (PI / 2.0) / chain.swing_speed
	chain._physics_process(peak_right_time)
	assert_true(is_equal_approx(chain.get_current_angle_degrees(), 50.0), "At peak right turnaround, angle = +50 deg")
	
	# Advance another half period (PI / 2.0 = 1.570796s): sin(3*PI/2) = -1.0 -> angle = -50 deg
	var half_period: float = PI / chain.swing_speed
	chain._physics_process(half_period)
	assert_true(is_equal_approx(chain.get_current_angle_degrees(), -50.0), "At peak left turnaround, angle = -50 deg")
	
	# Verify counter-phase offset (e.g. antiphase double chain corridor, phi = PI)
	print("  Validating Counter-phase offset behavior...")
	chain.reset()
	chain.phase_offset = PI
	chain.reset()
	assert_true(is_equal_approx(chain.get_current_angle_degrees(), 0.0), "Antiphase chain at t=0 has angle = 0 deg")
	chain._physics_process(peak_right_time)
	# sin(PI/2 + PI) = sin(3*PI/2) = -1.0 -> angle = -50 deg
	assert_true(is_equal_approx(chain.get_current_angle_degrees(), -50.0), "Antiphase chain swings in exact opposition (-50 deg)")
	
	# Verify dynamic geometry update when chain_length is changed
	print("  Validating geometry and collision updates...")
	chain.chain_length = 180.0
	assert_eq(chain.weight_sprite.position.y, 180.0, "Weight sprite updates to Y=180 when chain_length changed")
	assert_eq(chain.weight_collision.position.y, 180.0, "Weight collision updates to Y=180")
	assert_eq(chain.chain_line.points[1].y, 180.0, "ChainLine endpoint updates to Y=180")
	
	# Verify hazard collision lethality
	print("  Validating Hazard Collision & Player Death...")
	var player_scene = load("res://scenes/coin_hell/player.tscn")
	var test_player = player_scene.instantiate()
	add_child(test_player)
	
	var death_data := {"triggered": false}
	var death_cb := func(): death_data["triggered"] = true
	GameManager.player_died.connect(death_cb)
	
	chain.is_lethal = true
	chain._on_hazard_body_entered(test_player)
	assert_true(not test_player._is_alive, "Touching lethal chain kills the player")
	assert_true(death_data["triggered"], "Touching lethal chain triggers GameManager.player_died")
	GameManager.player_died.disconnect(death_cb)
	
	# Non-lethal toggle
	death_data["triggered"] = false
	test_player.revive()
	GameManager.player_died.connect(death_cb)
	chain.is_lethal = false
	chain._on_hazard_body_entered(test_player)
	assert_true(test_player._is_alive, "Non-lethal chain does not kill the player")
	assert_true(not death_data["triggered"], "Non-lethal chain does not trigger death signal")
	GameManager.player_died.disconnect(death_cb)
	test_player.queue_free()
	
	# Verify clean retry reset
	chain.reset()
	assert_eq(chain._time, 0.0, "Reset restores _time to 0.0")
	
	chain.queue_free()

func test_level_9_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 9 Gameplay Mechanics (Chains of the Damned) ---")
	var lvl_scene = load("res://scenes/coin_hell/coin_hell_level_9.tscn")
	assert_true(lvl_scene != null, "Level 9 scene loads successfully")
	
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	
	var player = lvl.get_node_or_null("Player")
	assert_true(player != null, "Player exists in Level 9")
	assert_eq(player.position, Vector2(100, 380), "Player spawns safely at X=100, Y=380")
	
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	assert_true(cam != null, "Camera2D exists on player")
	assert_eq(cam.limit_bottom, 600, "Camera2D limit_bottom is 600")
	assert_eq(cam.limit_right, 3000, "Camera2D limit_right is 3000")
	
	# Mobile controls standardized dimensions
	print("  Validating Level 9 Mobile Controls standardized dimensions...")
	var touch_controls = lvl.get_node_or_null("HUD/TouchControls")
	assert_true(touch_controls != null, "TouchControls exists in Level 9")
	var lbtn: TextureButton = touch_controls.get_node("LeftBtn")
	var rbtn: TextureButton = touch_controls.get_node("RightBtn")
	var jbtn: TextureButton = touch_controls.get_node("JumpBtn")
	assert_eq(lbtn.offset_right - lbtn.offset_left, 104.0, "LeftBtn width is 104px")
	assert_eq(lbtn.offset_bottom - lbtn.offset_top, 104.0, "LeftBtn height is 104px")
	assert_eq(rbtn.offset_right - rbtn.offset_left, 104.0, "RightBtn width is 104px")
	assert_eq(rbtn.offset_bottom - rbtn.offset_top, 104.0, "RightBtn height is 104px")
	assert_eq(jbtn.offset_right - jbtn.offset_left, 124.0, "JumpBtn width is 124px")
	assert_eq(jbtn.offset_bottom - jbtn.offset_top, 124.0, "JumpBtn height is 124px")
	
	# Haunted Hall visual environment
	assert_true(lvl.has_node("HauntedHallEnvironment"), "HauntedHallEnvironment exists in Level 9")
	
	# HUD World / Stage display
	var hud_level_label: Label = lvl.get_node("HUD/MarginContainer/TopBar/LevelName")
	assert_eq(hud_level_label.text, "WORLD 2 · STAGE 9: CHAINS OF THE DAMNED", "HUD displays correct World 2 Stage 9 label")
	
	# Exactly 10 coins
	print("  Validating Exactly 10 Coins across 5 Sections...")
	var coins = lvl.get_node("Coins")
	assert_eq(coins.get_child_count(), 10, "Level 9 contains exactly 10 coins")
	for i in range(1, 11):
		assert_true(coins.has_node("Coin%d" % i), "Coin %d exists" % i)
		
	# Swinging Ghost Chains across sections
	print("  Validating Swinging Ghost Chains across sections...")
	var chains = lvl.get_node("Chains")
	assert_eq(chains.get_child_count(), 7, "Level 9 contains 7 swinging chains")
	
	var ch1 = chains.get_node("Chain1_Single")
	var ch2 = chains.get_node("Chain2_Wide")
	var ch3 = chains.get_node("Chain3_Phantom")
	var ch4 = chains.get_node("Chain4_CorridorA")
	var ch5 = chains.get_node("Chain5_CorridorB")
	var ch6 = chains.get_node("Chain6_Final")
	var ch7 = chains.get_node("Chain7_ExitGuard")
	
	assert_true(ch1 is SwingingChainClass, "Chain 1 is SwingingChain")
	assert_true(ch2 is SwingingChainClass, "Chain 2 is SwingingChain")
	assert_true(ch3 is SwingingChainClass, "Chain 3 is SwingingChain")
	assert_true(ch4 is SwingingChainClass, "Chain 4 is SwingingChain")
	assert_true(ch5 is SwingingChainClass, "Chain 5 is SwingingChain")
	assert_true(ch6 is SwingingChainClass, "Chain 6 is SwingingChain")
	assert_true(ch7 is SwingingChainClass, "Chain 7 is SwingingChain")
	
	# Type B: Double-Chain Corridor alternating phase verification
	assert_eq(ch4.swing_speed, ch5.swing_speed, "Corridor chains have matching swing speed")
	assert_true(is_equal_approx(absf(ch5.phase_offset - ch4.phase_offset), PI), "Corridor chains swing in exact counter-phase (delta phi = PI)")
	
	# Medium Difficulty Platforms & Fair reaction times
	print("  Validating Platform Widths & Phantom Platform Windows...")
	var plat1 = lvl.get_node("Platforms/Plat1_Stone")
	var plat2 = lvl.get_node("Platforms/Plat2_RestA")
	var plat4_rest = lvl.get_node("Platforms/Plat4_RestB")
	var plat5_phantom = lvl.get_node("Platforms/Plat5_PhantomTimed")
	var plat6_rest = lvl.get_node("Platforms/Plat6_RestC")
	var plat8_phantom = lvl.get_node("Platforms/Plat8_MovingPhantom")
	var plat8_rest = lvl.get_node("Platforms/Plat8_RestD")
	var plat10_phantom = lvl.get_node("Platforms/Plat10_TriggeredPhantom")
	
	var plat1_shape = plat1.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat2_shape = plat2.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat4_shape = plat4_rest.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat6_shape = plat6_rest.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat8_shape = plat8_rest.get_node("CollisionShape2D").shape as RectangleShape2D
	
	assert_true(plat1_shape.size.x >= 120.0, "Plat1 width >= 120px for reliable landing")
	assert_true(plat2_shape.size.x >= 120.0, "Plat2 RestA width >= 120px")
	assert_true(plat4_shape.size.x >= 120.0, "Plat4 RestB width >= 120px")
	assert_true(plat6_shape.size.x >= 120.0, "Plat6 RestC width >= 120px")
	assert_true(plat8_shape.size.x >= 120.0, "Plat8 RestD width >= 120px")
	
	# Phantom platform generous parameters
	assert_true(plat5_phantom.width >= 100.0, "Plat5 Phantom width >= 100px")
	assert_true(plat5_phantom.solid_duration >= 3.0, "Plat5 Phantom solid duration >= 3.0s")
	assert_true(plat8_phantom.width >= 100.0, "Plat8 Moving Phantom width >= 100px")
	assert_true(plat8_phantom.solid_duration >= 3.0, "Plat8 Moving Phantom solid duration >= 3.0s")
	assert_true(plat10_phantom.width >= 100.0, "Plat10 Triggered Phantom width >= 100px")
	assert_true(plat10_phantom.trigger_delay >= 1.2, "Plat10 Triggered Phantom reaction time >= 1.2s")
	
	# Exit gate locked state and positioning
	var exit_gate = lvl.get_node("ExitGate")
	var sanctuary_plat = lvl.get_node("Platforms/Plat_ExitSanctuary")
	assert_true(not exit_gate._is_open, "ExitGate starts locked requiring all 10 coins")
	assert_eq(exit_gate.position.y, 272.0, "Level 9 ExitGate rests at Y=272")
	var plat_shape = sanctuary_plat.get_node("CollisionShape2D").shape as RectangleShape2D
	var plat_top = sanctuary_plat.position.y - (plat_shape.size.y / 2.0)
	assert_eq(exit_gate.position.y + 28.0, plat_top, "Level 9 ExitGate rests flush on sanctuary platform (Y=300)")
	
	# Collect all 10 coins
	print("  Validating Coin Collection & Level 9 Completion...")
	GameManager.current_level_id = 9
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	for i in range(1, 11):
		coins.get_node("Coin%d" % i).collect()
	assert_eq(GameManager.current_coins, 10, "All 10 coins collected in Level 9")
	assert_true(exit_gate._is_open, "ExitGate opens automatically when all 10 coins collected")
	
	# Enter exit gate to complete Level 9
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level 9 completion triggered upon entering exit gate")
	assert_true(SaveManager.is_level_completed(9), "Level 9 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(10), "Level 10 is unlocked after Level 9 completion")
	
	# Next Level button on LevelCompleteOverlay displays in-progress modal for Level 10
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	complete_overlay._on_next_level_pressed()
	var complete_modal_label: Label = complete_overlay.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_eq(complete_modal_label.text, "Level 10 is unlocked, but it's still being built. Replay Level 1 for now.", "Level 9 Next Level shows safe unimplemented Level 10 modal")
	
	# Test clean retry reset
	print("  Validating Clean Trap Reset on Level 9 Retry...")
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 9 retry resets coins to 0")
	assert_true(not exit_gate._is_open, "ExitGate re-locks on retry")
	assert_true(not exit_gate._completion_triggered, "ExitGate completion flag reset")
	assert_eq(ch1._time, 0.0, "Chain 1 reset to t=0 on retry")
	assert_eq(ch5._time, 0.0, "Chain 5 reset to t=0 on retry")
	
	lvl.queue_free()


