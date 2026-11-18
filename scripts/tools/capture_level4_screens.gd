extends Node

func _ready() -> void:
	get_viewport().size = Vector2i(960, 540)
	DirAccess.make_dir_absolute("res://screenshots")
	_capture_screens()

func _capture_screens() -> void:
	var artifact_dir := "C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551"
	
	# 1. Screen 1: Level 4 HUD Top Bar, Intro Banner & Starting Area
	var lvl4 = load("res://scenes/bullet_betrayal/bb_level_4.tscn").instantiate()
	add_child(lvl4)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level4_start_hud.png")
		img.save_png("%s/bb_level4_start_hud.png" % artifact_dir)

	var player = lvl4.player
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.position_smoothing_enabled = false

	# Hide intro banner for subsequent gameplay gameplay captures
	if lvl4.intro_banner:
		lvl4.intro_banner.visible = false

	# 2. Screen 2: Section A Hunting Mine Patrol with Blinking LED & Warning signs
	var hmine1 = lvl4.get_node_or_null("HuntingMines/HuntingMine1_Intro")
	if hmine1:
		hmine1._blink_timer = 0.05
		hmine1._update_blinking_led(0.0)
	player.global_position = Vector2(380, 394)
	if cam:
		cam.global_position = Vector2(500, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level4_hunting_mine_patrol.png")
		img.save_png("%s/bb_level4_hunting_mine_patrol.png" % artifact_dir)

	# 3. Screen 3: Section C Platform Overpass, Ladder & Field Hunting Mine
	var hmine2 = lvl4.get_node_or_null("HuntingMines/HuntingMine2_Field")
	if hmine2:
		hmine2._change_state(BulletBetrayalHuntingMine.State.CHASE)
		hmine2.velocity.x = 80.0
		hmine2._blink_timer = 0.04
		hmine2._update_blinking_led(0.0)
	player.global_position = Vector2(1660, 244) # Safely up on overpass
	if cam:
		cam.global_position = Vector2(1660, 310)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level4_section_c_overpass.png")
		img.save_png("%s/bb_level4_section_c_overpass.png" % artifact_dir)

	# 4. Screen 4: Section D Narrow Passage, Waiting Alcove & Extraction Beacon
	var hmine3 = lvl4.get_node_or_null("HuntingMines/HuntingMine3_Passage")
	if hmine3:
		hmine3._blink_timer = 0.05
		hmine3._update_blinking_led(0.0)
	player.global_position = Vector2(2180, 294) # Waiting on alcove ledge
	if cam:
		cam.global_position = Vector2(2420, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level4_section_d_narrow_passage.png")
		img.save_png("%s/bb_level4_section_d_narrow_passage.png" % artifact_dir)

	print("Captured all Level 4 screenshots successfully!")
	lvl4.queue_free()
	get_tree().quit(0)
