extends Node

## Test runner node executed inside the active scene tree with full autoload support.

const CrumblingBridgeSectionClass = preload("res://scripts/coin_hell/crumbling_bridge_section.gd")
const MovingWallClass = preload("res://scripts/coin_hell/moving_wall.gd")
const FakeExitGateClass = preload("res://scripts/coin_hell/fake_exit_gate.gd")

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
	test_main_menu_logic_and_modals()
	test_level_select_logic_and_states()
	test_level_1_gameplay_mechanics()
	test_multitouch_gameplay_controls()
	test_ragebait_tricks_and_level_rework()
	test_full_level_1_gameplay_walkthrough()
	test_spike_collision_directions_and_cases()
	test_level_2_gameplay_mechanics()

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
	
	for lvl_id in range(3, 21):
		assert_true(not GameManager.can_play_level(lvl_id), "Level %d is marked not implemented" % lvl_id)
		
	# Test coin counter clamping
	GameManager.current_level_id = 1
	GameManager.total_coins_required = 10
	GameManager.reset_coins()
	assert_eq(GameManager.current_coins, 0, "Reset coins sets current_coins to 0")
	for i in range(15):
		GameManager.collect_coin()
	assert_eq(GameManager.current_coins, 10, "Coin counter clamps at configured total (10) and does not overflow")

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
	
	var grid = lsel.get_node("MarginContainer/VBox/ScrollContainer/LevelGrid")
	assert_eq(grid.get_child_count(), 20, "Level grid contains 20 level tiles")
	
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

	# Complete level 2 to unlock level 3 and test unimplemented level press
	SaveManager.complete_level(2)
	lsel._update_ui()
	lsel._on_level_tile_pressed(3)
	assert_true(modal.visible, "Pressing unlocked but unimplemented level shows modal")
	assert_eq(modal_label.text, "Level 3 is unlocked, but it's still being built. Replay Level 1 for now.", "Modal shows exact unimplemented level message")
	
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

	# --- TRAP 1: CRUMBLING BRIDGE ---
	print("  Validating Trap 1: Crumbling Bridge...")
	var b1 = platforms.get_node("BridgeSection1")
	var b2 = platforms.get_node("BridgeSection2")
	var b3 = platforms.get_node("BridgeSection3")
	assert_true(b1 is CrumblingBridgeSectionClass, "BridgeSection1 uses CrumblingBridgeSection script")
	assert_true(b2 is CrumblingBridgeSectionClass, "BridgeSection2 uses CrumblingBridgeSection script")
	assert_true(b3 is CrumblingBridgeSectionClass, "BridgeSection3 uses CrumblingBridgeSection script")
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

	# --- TRAP 2: GREEDY COIN ---
	print("  Validating Trap 2: Greedy Coin Platform...")
	var gp = platforms.get_node("PlatformGreedy")
	assert_true(gp is GreedyPlatform, "PlatformGreedy uses GreedyPlatform script")
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

	# --- TRAP 3: HIDDEN SPIKE FLOOR ---
	print("  Validating Trap 3: Hidden Spike Floor...")
	var spike_floor = platforms.get_node("PlatformSpikeFloor")
	assert_true(spike_floor is FakeSafePlatform, "PlatformSpikeFloor uses FakeSafePlatform script")
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

	# --- TRAP 4: MOVING WALL ---
	print("  Validating Trap 4: Moving Wall...")
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

	# --- FINAL SURPRISE: FAKE EXIT -> REAL EXIT ---
	print("  Validating Final Surprise: Fake Exit -> Real Exit...")
	assert_true(fake_exit is FakeExitGateClass, "FakeExitGate uses FakeExitGate script")
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
	assert_eq(fake_exit.status_label.text, "FAKED!", "FakeExitGate displays 'FAKED!'")
	assert_true(real_exit.visible, "RealExitGate revealed upon FakeExitGate deception")
	assert_true(real_exit._is_open, "RealExitGate is unlocked and open")

	# Enter RealExitGate to complete Level 2
	GameManager.is_gameplay_active = true
	real_exit._on_body_entered(player)
	assert_true(real_exit._completion_triggered, "Level 2 completion triggered upon entering RealExitGate")
	assert_true(SaveManager.is_level_completed(2), "Level 2 marked completed in SaveManager")
	assert_true(SaveManager.is_level_unlocked(3), "Level 3 is unlocked after Level 2 completion")

	# Next Level button from complete overlay in Level 2 shows Level 3 is still being built
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	complete_overlay._on_next_level_pressed()
	var complete_modal_label: Label = complete_overlay.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_eq(complete_modal_label.text, "Level 3 is unlocked, but it's still being built. Replay Level 1 for now.", "Level 2 Next Level shows safe unimplemented Level 3 modal")

	# Reset Level 2
	lvl._on_retry()
	assert_eq(GameManager.current_coins, 0, "Level 2 retry resets coins to 0")
	assert_true(not fake_exit._has_tricked, "FakeExitGate deception reset")
	assert_true(not real_exit.visible, "RealExitGate hidden again on reset")
	assert_true(not real_exit._completion_triggered, "RealExitGate completion flag reset")

	lvl.queue_free()
