extends SceneTree

## Automated test runner executing comprehensive headless verification of Coin Hell.

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n=======================================================")
	print("  RETRO RAGE ARCADE / COIN HELL AUTOMATED TEST SUITE   ")
	print("=======================================================\n")
	
	run_all_tests()
	
	print("\n=======================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("=======================================================\n")
	
	if failed_count > 0:
		quit(1)
	else:
		quit(0)

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
	
	for lvl_id in range(2, 21):
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
	root.add_child(menu)
	
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
	root.add_child(lsel)
	
	var grid = lsel.get_node("MarginContainer/VBox/ScrollContainer/LevelGrid")
	assert_eq(grid.get_child_count(), 20, "Level grid contains 20 level tiles")
	
	# Test locked level press
	lsel._on_level_tile_pressed(5)
	var modal = lsel.get_node("MessageModal")
	var modal_label: Label = lsel.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_true(modal.visible, "Pressing locked level shows modal")
	assert_eq(modal_label.text, "Locked! Beat the previous level first. The developer has enough problems already.", "Modal shows exact locked level message")
	
	# Unlock level 2 and test unimplemented level press
	SaveManager.complete_level(1)
	lsel._update_ui()
	lsel._on_level_tile_pressed(2)
	assert_true(modal.visible, "Pressing unlocked but unimplemented level shows modal")
	assert_eq(modal_label.text, "Level 2 is unlocked, but it's still being built. Replay Level 1 for now.", "Modal shows exact unimplemented level message")
	
	lsel.queue_free()

func test_level_1_gameplay_mechanics() -> void:
	print("\n--- TEST: Level 1 Gameplay Mechanics ---")
	var lvl1_scene: PackedScene = load("res://scenes/coin_hell/coin_hell_level_1.tscn")
	assert_true(lvl1_scene != null, "Level 1 scene loads successfully")
	var lvl = lvl1_scene.instantiate()
	root.add_child(lvl)
	
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
	assert_eq(exit_gate.toast_label.text, "You still need 10 coins!", "Exit gate toast informs player of remaining coins")
	
	# Collect all coins
	for coin in coins_container.get_children():
		coin.collect()
	
	assert_true(exit_gate._is_open, "Exit gate unlocks automatically after 10th coin is collected")
	assert_eq(exit_gate.status_label.text, "EXIT OPEN!", "Exit gate displays 'EXIT OPEN!'")
	
	# Player touches unlocked exit gate
	GameManager.is_gameplay_active = true
	exit_gate._on_body_entered(player)
	assert_true(exit_gate._completion_triggered, "Level completion triggers on exit")
	assert_true(SaveManager.is_level_completed(1), "Level 1 completion persists in SaveManager")
	assert_true(SaveManager.is_level_unlocked(2), "Level 2 is unlocked upon completion")
	
	# Test Level Complete overlay Next Level button
	var complete_overlay = lvl.get_node("HUD/LevelCompleteOverlay")
	complete_overlay.open(10, 10)
	complete_overlay._on_next_level_pressed()
	var complete_modal_label: Label = complete_overlay.get_node("MessageModal/Panel/VBox/MessageLabel")
	assert_eq(complete_modal_label.text, "Level 2 is unlocked, but it's still being built. Replay Level 1 for now.", "Next Level from overlay safely shows unimplemented level message")
	
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
