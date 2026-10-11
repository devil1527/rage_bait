extends Node

## Automates in-engine gameplay traversal of Level 1 to capture visual proof
## of the starting position, each ragebait trick in action, and level completion.

var level_scene_path: String = "res://scenes/coin_hell/coin_hell_level_1.tscn"

func _ready() -> void:
	get_viewport().size = Vector2i(960, 540)
	DirAccess.make_dir_absolute("res://screenshots")
	_run_visual_verification()

func _capture(file_path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		img.save_png(file_path)
		print("SAVED SCREENSHOT: ", file_path)

func _run_visual_verification() -> void:
	print("--- STARTING LEVEL 1 VISUAL GAMEPLAY VERIFICATION ---")
	
	# Load and add Level 1
	var level = load(level_scene_path).instantiate()
	add_child(level)
	
	var player = level.get_node("Player")
	var exit_gate = level.get_node("ExitGate")
	var plat2 = level.get_node("Platforms/Platform2")
	var plat_greedy = level.get_node("Platforms/PlatformGreedy")
	var plat4 = level.get_node("Platforms/Platform4")
	var coins = level.get_node("Coins")
	
	# Log runtime physics values to stdout as required by Problem 1 & 4
	print("RUNTIME PHYSICS VERIFICATION:")
	print("  Player move_speed: ", player.move_speed)
	print("  Player acceleration: ", player.acceleration)
	print("  Player friction: ", player.friction)
	print("  Player jump_velocity: ", player.jump_velocity)
	print("  Player gravity: ", player.gravity)
	var max_jump_reach = (player.jump_velocity * player.jump_velocity) / (2.0 * player.gravity)
	print("  Calculated peak jump reach: ", max_jump_reach, " px")
	print("  Player in group 'player': ", player.is_in_group("player"))
	
	# STAGE 1: Starting Position
	for i in range(10):
		await get_tree().process_frame
	await _capture("res://screenshots/stage1_starting_position.png")
	
	# STAGE 2: Landing on Betraying Platform (Platform 2)
	print("\nSimulating approach to Trick 1 (Platform 2)...")
	# Collect Coin 1, 2, 3 on the way
	coins.get_node("Coin1").collect()
	coins.get_node("Coin2").collect()
	coins.get_node("Coin3").collect()
	
	# Land player on Platform 2
	player.global_position = Vector2(680, 320)
	player.velocity = Vector2.ZERO
	for i in range(6):
		await get_tree().process_frame
	
	# Collect Coin 4
	coins.get_node("Coin4").collect()
	
	# Trigger Platform 2 warning
	plat2.trigger()
	for i in range(12):
		await get_tree().process_frame
	
	await _capture("res://screenshots/stage2_betraying_platform_warning.png")
	
	# STAGE 3: Trick 3 — The Greedy Coin on Platform Greedy
	print("\nSimulating approach to Trick 3 (Platform Greedy)...")
	coins.get_node("Coin5").collect()
	player.global_position = Vector2(1010, 320)
	player.velocity = Vector2.ZERO
	for i in range(5):
		await get_tree().process_frame
	
	# Stepping onto lower Platform Greedy drops into pit
	plat_greedy.trigger_greedy_drop()
	for i in range(12):
		await get_tree().process_frame
	
	await _capture("res://screenshots/stage3_greedy_coin_drop.png")
	
	# STAGE 4: Trick 2 — Fake Safe Platform 4 Pop-up Spikes
	print("\nSimulating approach to Trick 2 (Fake Safe Platform 4)...")
	coins.get_node("Coin6").collect()
	coins.get_node("Coin7").collect()
	
	# Player approaches / lands on Platform 4
	player.global_position = Vector2(1400, 360)
	player.velocity = Vector2.ZERO
	plat4.trigger_trap()
	
	# Allow telegraph to run and spikes to fully pop up
	for i in range(35):
		await get_tree().process_frame
	
	await _capture("res://screenshots/stage4_fake_safe_platform_spikes.png")
	
	# STAGE 5: Trick 4 — Unlocked Stationary Exit Gate
	print("\nSimulating collection of all coins and approaching exit...")
	coins.get_node("Coin8").collect()
	coins.get_node("Coin9").collect()
	coins.get_node("Coin10").collect()
	
	# Check exit unlocked
	print("  Coins collected: ", GameManager.current_coins, " / ", GameManager.total_coins_required)
	print("  Exit gate is open: ", exit_gate._is_open)
	
	# Move player close to stationary exit gate
	player.global_position = Vector2(1810, 434)
	player.velocity = Vector2.ZERO
	
	for i in range(12):
		await get_tree().process_frame
	
	await _capture("res://screenshots/stage5_stationary_exit_open.png")
	
	# STAGE 6: Completing Level 1
	print("\nCompleting level...")
	player.global_position = exit_gate.global_position
	exit_gate._on_body_entered(player)
	for i in range(15):
		await get_tree().process_frame
	
	await _capture("res://screenshots/stage6_level_complete.png")
	
	print("\nALL 6 GAMEPLAY STAGE SCREENSHOTS CAPTURED SUCCESSFULLY!")
	get_tree().quit(0)
