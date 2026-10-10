extends Node

func _ready() -> void:
	get_viewport().size = Vector2i(960, 540)
	DirAccess.make_dir_absolute("res://screenshots")
	_run_capture()

func _run_capture() -> void:
	# Screen 1: Main Menu
	var main_menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(main_menu)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/01_main_menu.png")
	main_menu.queue_free()
	await get_tree().process_frame

	# Screen 2: Coming Soon Modal on Main Menu
	var main_menu2 = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(main_menu2)
	main_menu2._show_coming_soon("Bullet Betrayal")
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/02_main_menu_modal.png")
	main_menu2.queue_free()
	await get_tree().process_frame

	# Screen 3: Level Select
	var lsel = load("res://scenes/ui/coin_hell_level_select.tscn").instantiate()
	add_child(lsel)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/03_level_select.png")

	# Screen 4: Level Select Locked Modal
	lsel._on_level_tile_pressed(2)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/04_level_select_locked_modal.png")
	lsel.queue_free()
	await get_tree().process_frame

	# Screen 5: Gameplay Level 1
	var lvl1 = load("res://scenes/coin_hell/coin_hell_level_1.tscn").instantiate()
	add_child(lvl1)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/05_gameplay_level_1.png")

	# Screen 6: Pause Overlay
	lvl1.pause_overlay.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/06_pause_overlay.png")
	lvl1.pause_overlay.visible = false

	# Screen 7: Death Overlay
	lvl1.death_overlay.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/07_death_overlay.png")
	lvl1.death_overlay.visible = false

	# Screen 8: Level Complete Overlay
	lvl1.level_complete_overlay.open(10, 10)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/08_level_complete_overlay.png")

	lvl1.queue_free()
	print("ALL SCREENSHOTS CAPTURED SUCCESSFULLY!")
	get_tree().quit(0)
