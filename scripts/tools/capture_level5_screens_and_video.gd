extends Node

func _ready() -> void:
	get_viewport().size = Vector2i(960, 540)
	DirAccess.make_dir_absolute("res://screenshots")
	DirAccess.make_dir_absolute("res://screenshots/frames_rusher")
	_capture_all()

func _capture_all() -> void:
	var artifact_dir := "C:/Users/hp/.gemini/antigravity/brain/fd57ad84-cb7a-403d-bad9-877515bd6551"
	
	# Load Level 5 for Screenshots
	var lvl5 = load("res://scenes/bullet_betrayal/bb_level_5.tscn").instantiate()
	add_child(lvl5)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	# 1. Screen 1: Level 5 Start HUD & Briefing Banner
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_start_hud.png")
		img.save_png("%s/bb_level5_start_hud.png" % artifact_dir)

	var player = lvl5.player
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.position_smoothing_enabled = false

	# Hide intro banner for subsequent gameplay captures
	if lvl5.intro_banner:
		lvl5.intro_banner.visible = false

	# 2. Screen 2: Section B - Rusher 1 waiting disguised behind Bunker 1
	var rusher1 = lvl5.get_node_or_null("Enemies/Enemy3_Rusher1_Bunker")
	if rusher1:
		rusher1.visible = true
	player.global_position = Vector2(800, 394)
	if cam:
		cam.global_position = Vector2(980, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_rusher_waiting.png")
		img.save_png("%s/bb_level5_rusher_waiting.png" % artifact_dir)

	# 3. Screen 3: Rusher 1 Activating & Charging towards player
	if rusher1:
		rusher1.activate_rusher(player)
		rusher1.rusher_state = BulletBetrayalExplosiveRusher.RusherState.RUSHING
		rusher1.velocity.x = -145.0
		rusher1.facing_direction = -1
		rusher1._update_facing()
		rusher1.global_position = Vector2(960, 393)
		rusher1._strobe_state = true
		if rusher1.sprite:
			rusher1.sprite.modulate = Color(2.2, 0.4, 0.3, 1.0)
		if rusher1.warning_led:
			rusher1.warning_led.color = Color(1.0, 0.1, 0.1, 1.0)
			rusher1.warning_led.visible = true
		if rusher1.warning_glow:
			rusher1.warning_glow.visible = true
		if rusher1.alert_icon:
			rusher1.alert_icon.visible = true
	player.global_position = Vector2(830, 394)
	if cam:
		cam.global_position = Vector2(930, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_rusher_charging.png")
		img.save_png("%s/bb_level5_rusher_charging.png" % artifact_dir)

	# 4. Screen 4: Section C Platform Overpass & Rear Rusher
	var rusher2 = lvl5.get_node_or_null("Enemies/Enemy6_Rusher2_Rear")
	if rusher2:
		rusher2.visible = true
		rusher2.activate_rusher(player)
		rusher2.rusher_state = BulletBetrayalExplosiveRusher.RusherState.RUSHING
		rusher2.facing_direction = 1
		rusher2._update_facing()
		rusher2.global_position = Vector2(1700, 393)
		if rusher2.warning_glow:
			rusher2.warning_glow.visible = true
	player.global_position = Vector2(1820, 394)
	if cam:
		cam.global_position = Vector2(1740, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_section_c_rear_rusher.png")
		img.save_png("%s/bb_level5_section_c_rear_rusher.png" % artifact_dir)

	# 5. Screen 5: Section D Narrow Passage & Extraction Beacon
	player.global_position = Vector2(2060, 284)
	if cam:
		cam.global_position = Vector2(2360, 320)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_section_d_narrow_passage.png")
		img.save_png("%s/bb_level5_section_d_narrow_passage.png" % artifact_dir)

	# 6. Screen 6: Rusher 1 Detonating
	player.global_position = Vector2(980, 394)
	if cam:
		cam.global_position = Vector2(930, 320)
	if rusher1:
		rusher1.global_position = Vector2(910, 393)
		rusher1.detonate()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshots/bb_level5_rusher_detonation.png")
		img.save_png("%s/bb_level5_rusher_detonation.png" % artifact_dir)

	# 7. Video Sequence Capture: Rusher activating, sprinting, and detonating
	lvl5.queue_free()
	await get_tree().process_frame

	var lvl5_sim = load("res://scenes/bullet_betrayal/bb_level_5.tscn").instantiate()
	add_child(lvl5_sim)
	await get_tree().process_frame
	await get_tree().process_frame
	if lvl5_sim.intro_banner:
		lvl5_sim.intro_banner.visible = false

	var sim_player = lvl5_sim.player
	var sim_cam = sim_player.get_node_or_null("Camera2D")
	if sim_cam:
		sim_cam.position_smoothing_enabled = false
		sim_cam.global_position = Vector2(950, 320)

	var sim_rusher = lvl5_sim.get_node_or_null("Enemies/Enemy3_Rusher1_Bunker")
	if sim_rusher:
		sim_rusher.visible = true
	sim_player.global_position = Vector2(800, 394)

	var frame_idx: int = 0
	# Run 60 frames of real simulation!
	for f in range(60):
		# Player moves right towards bunker until rusher activates
		if f < 15 and is_instance_valid(sim_player):
			sim_player.global_position.x += 2.5
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("res://screenshots/frames_rusher/frame_%04d.png" % frame_idx)
			frame_idx += 1

	print("Captured %d simulation frames and all Level 5 screenshots successfully!" % frame_idx)
	lvl5_sim.queue_free()
	get_tree().quit(0)
