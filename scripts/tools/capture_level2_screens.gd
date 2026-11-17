extends Node

func _ready() -> void:
	get_viewport().size = Vector2i(960, 540)
	DirAccess.make_dir_absolute("res://screenshots")
	_capture_screens()

func _capture_screens() -> void:
	# 1. Screen 1: Level 2 HUD Top Bar & Start
	var lvl2 = load("res://scenes/bullet_betrayal/bb_level_2.tscn").instantiate()
	add_child(lvl2)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_start_hud.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_start_hud.png")

	# 2. Screen 2: Dynamic Rear Ambush (Player at X=660 moving right, Enemy2 emerges behind at X=420)
	var player = lvl2.player
	var enemy2 = lvl2.get_node_or_null("Enemies/Enemy2_RearAmbush")
	var cam = player.get_node_or_null("Camera2D")
	if cam:
		cam.position_smoothing_enabled = false
	
	player.global_position = Vector2(660, 394)
	player.velocity = Vector2(230, 0)
	player.facing_direction = 1
	if enemy2:
		enemy2.trigger_ambush(player)
	if cam:
		cam.global_position = Vector2(550, 320)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_rear_ambush.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_rear_ambush.png")

	# 3. Screen 3: Final Bar Jump & Safe Landing Runway
	player.global_position = Vector2(2440, 280) # Mid-air clearing the bar
	player.velocity = Vector2(230, 50)
	if cam:
		cam.global_position = Vector2(2520, 320)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_final_bar_jump.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_final_bar_jump.png")

	# 4. Screen 4: Safe Landing at Extraction Runway
	player.global_position = Vector2(2580, 394) # Landed safely on runway in front of extraction
	player.velocity = Vector2.ZERO
	if cam:
		cam.global_position = Vector2(2560, 320)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_safe_landing.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_safe_landing.png")

	lvl2.queue_free()
	await get_tree().process_frame
	get_tree().quit()
