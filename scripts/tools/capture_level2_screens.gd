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

	# 2. Screen 2: Rear Ambush
	var enemy2 = lvl2.get_node_or_null("Enemies/Enemy2_RearAmbush")
	var cam = lvl2.player.get_node_or_null("Camera2D")
	if enemy2:
		enemy2.trigger_ambush()
	if cam:
		cam.global_position = Vector2(450, 320)
		cam.position_smoothing_enabled = false
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_rear_ambush.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_rear_ambush.png")

	# 3. Screen 3: Ladder & Watchtower at end of stage
	if cam:
		cam.global_position = Vector2(2400, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level2_watchtower_ladder.png")
		img.save_png("C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551/bb_level2_watchtower_ladder.png")

	lvl2.queue_free()
	await get_tree().process_frame
	get_tree().quit()
