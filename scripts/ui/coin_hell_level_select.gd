extends Control

## CoinHellLevelSelect provides the world and stage selection UI
## for Coin Hell, featuring 4 thematic worlds and stages 1–11 (20 planned).

@onready var back_button: Button = $MarginContainer/VBox/HeaderBar/BackButton
@onready var progress_label: Label = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressBar
@onready var world_cards_bar: HBoxContainer = $MarginContainer/VBox/WorldCardsBar
@onready var worlds_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBox/ScrollContainer
@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

var lock_icon: Texture2D = preload("res://assets/sprites/icon_lock.png")
var completed_icon: Texture2D = preload("res://assets/sprites/icon_completed.png")

# Styles per world
var _style_w1_comp_normal: StyleBoxFlat
var _style_w1_comp_hover: StyleBoxFlat
var _style_w1_avail_normal: StyleBoxFlat
var _style_w1_avail_hover: StyleBoxFlat

var _style_w2_comp_normal: StyleBoxFlat
var _style_w2_comp_hover: StyleBoxFlat
var _style_w2_avail_normal: StyleBoxFlat
var _style_w2_avail_hover: StyleBoxFlat

var _style_w3_comp_normal: StyleBoxFlat
var _style_w3_comp_hover: StyleBoxFlat
var _style_w3_avail_normal: StyleBoxFlat
var _style_w3_avail_hover: StyleBoxFlat

var _style_w4_comp_normal: StyleBoxFlat
var _style_w4_comp_hover: StyleBoxFlat
var _style_w4_avail_normal: StyleBoxFlat
var _style_w4_avail_hover: StyleBoxFlat
var _style_w4_normal: StyleBoxFlat
var _style_w4_hover: StyleBoxFlat

var _style_lock_normal: StyleBoxFlat
var _style_lock_hover: StyleBoxFlat
var _style_planned_normal: StyleBoxFlat
var _style_planned_hover: StyleBoxFlat

var _style_dev_normal: StyleBoxFlat
var _style_dev_hover: StyleBoxFlat

var is_debug_mode: bool = OS.is_debug_build()
var dev_bypass_active: bool = false
var dev_toggle_btn: Button = null

# Active world view: 0 = Show All, 1..4 = Focused on World 1..4
var current_selected_world: int = 0
var world_card_buttons: Dictionary = {}

# Touch drag scrolling state
var _is_touch_active: bool = false
var _drag_touch_id: int = -1
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_last_pos: Vector2 = Vector2.ZERO
var _drag_start_scroll_v: int = 0
var _is_dragging: bool = false
var _drag_velocity: float = 0.0
var _last_drag_time: float = 0.0
var _drag_suppress_click_until: float = 0.0
const DRAG_THRESHOLD: float = 8.0
const DRAG_DECEL_FRICTION: float = 10.0

func _init() -> void:
	_init_styles()

func _init_styles() -> void:
	# World 1: Neon Cyan Styles
	_style_w1_comp_normal = _create_card_style(Color(0.04, 0.13, 0.18, 0.96), Color(0.0, 0.95, 1.0, 1.0), 2, Color(0.0, 0.9, 1.0, 0.4), 8)
	_style_w1_comp_hover = _create_card_style(Color(0.06, 0.18, 0.25, 0.98), Color(0.3, 1.0, 1.0, 1.0), 2, Color(0.0, 1.0, 1.0, 0.65), 12)
	_style_w1_avail_normal = _create_card_style(Color(0.08, 0.10, 0.18, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w1_avail_hover = _create_card_style(Color(0.11, 0.15, 0.26, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 2: The Haunted Hall (Spectral Violet Styles)
	_style_w2_comp_normal = _create_card_style(Color(0.12, 0.08, 0.20, 0.96), Color(0.80, 0.55, 1.0, 1.0), 2, Color(0.75, 0.45, 1.0, 0.4), 8)
	_style_w2_comp_hover = _create_card_style(Color(0.16, 0.11, 0.28, 0.98), Color(0.92, 0.72, 1.0, 1.0), 2, Color(0.85, 0.55, 1.0, 0.65), 12)
	_style_w2_avail_normal = _create_card_style(Color(0.10, 0.08, 0.18, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w2_avail_hover = _create_card_style(Color(0.14, 0.11, 0.25, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 3: Rage Factory (Hazard Amber/Orange Styles)
	_style_w3_comp_normal = _create_card_style(Color(0.15, 0.09, 0.05, 0.96), Color(1.0, 0.68, 0.15, 1.0), 2, Color(1.0, 0.6, 0.12, 0.4), 8)
	_style_w3_comp_hover = _create_card_style(Color(0.20, 0.13, 0.08, 0.98), Color(1.0, 0.85, 0.32, 1.0), 2, Color(1.0, 0.75, 0.18, 0.65), 12)
	_style_w3_avail_normal = _create_card_style(Color(0.14, 0.09, 0.06, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w3_avail_hover = _create_card_style(Color(0.18, 0.12, 0.08, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 4: Final Hell (Infernal Crimson Styles)
	_style_w4_comp_normal = _create_card_style(Color(0.18, 0.05, 0.08, 0.96), Color(1.0, 0.25, 0.35, 1.0), 2, Color(0.9, 0.15, 0.25, 0.4), 8)
	_style_w4_comp_hover = _create_card_style(Color(0.24, 0.07, 0.11, 0.98), Color(1.0, 0.45, 0.55, 1.0), 2, Color(1.0, 0.25, 0.35, 0.65), 12)
	_style_w4_avail_normal = _create_card_style(Color(0.15, 0.05, 0.07, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w4_avail_hover = _create_card_style(Color(0.20, 0.08, 0.10, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)
	_style_w4_normal = _style_w4_avail_normal
	_style_w4_hover = _style_w4_avail_hover

	# Locked and Planned Styles
	_style_lock_normal = _create_card_style(Color(0.06, 0.06, 0.11, 0.88), Color(0.24, 0.27, 0.38, 0.85), 1, Color.TRANSPARENT, 0)
	_style_lock_hover = _create_card_style(Color(0.09, 0.09, 0.16, 0.94), Color(0.35, 0.40, 0.54, 0.95), 2, Color.TRANSPARENT, 0)
	_style_planned_normal = _create_card_style(Color(0.05, 0.05, 0.09, 0.82), Color(0.18, 0.20, 0.28, 0.70), 1, Color.TRANSPARENT, 0)
	_style_planned_hover = _create_card_style(Color(0.08, 0.08, 0.13, 0.90), Color(0.28, 0.30, 0.40, 0.85), 1, Color.TRANSPARENT, 0)

	# Dev Bypass Styles
	_style_dev_normal = _create_card_style(Color(0.05, 0.12, 0.18, 0.95), Color(0.0, 0.80, 1.0, 1.0), 2, Color(0.0, 0.7, 1.0, 0.3), 5)
	_style_dev_hover = _create_card_style(Color(0.08, 0.17, 0.26, 0.98), Color(0.4, 0.95, 1.0, 1.0), 3, Color(0.0, 0.9, 1.0, 0.55), 8)

func _create_card_style(bg: Color, border: Color, b_width: int, shadow: Color = Color.TRANSPARENT, s_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(b_width)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	if s_size > 0:
		sb.shadow_color = shadow
		sb.shadow_size = s_size
	return sb

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	modal_ok_btn.pressed.connect(_on_modal_close)
	message_modal.visible = false
	SaveManager.progress_updated.connect(_update_ui)

	# Developer-only level access widget (strictly debug builds only)
	if is_debug_mode:
		var header_bar: HBoxContainer = $MarginContainer/VBox/HeaderBar
		dev_toggle_btn = Button.new()
		dev_toggle_btn.name = "DevBypassToggle"
		dev_toggle_btn.custom_minimum_size = Vector2(130, 36)
		dev_toggle_btn.add_theme_font_size_override("font_size", 11)
		_update_dev_button_text()
		dev_toggle_btn.pressed.connect(_on_dev_toggle_pressed)
		header_bar.add_child(dev_toggle_btn)

	_setup_secret_developer_tap()
	_build_world_navigation_cards()
	_build_level_tiles()
	_update_ui()
	set_process(true)

var _secret_tap_count: int = 0
var _secret_tap_last_time: float = 0.0

func _setup_secret_developer_tap() -> void:
	var title_box: VBoxContainer = get_node_or_null("MarginContainer/VBox/HeaderBar/TitleBox")
	if title_box:
		title_box.mouse_filter = Control.MOUSE_FILTER_STOP
		title_box.gui_input.connect(_on_secret_tap_input)
		for child in title_box.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_PASS

	var progress_box: VBoxContainer = get_node_or_null("MarginContainer/VBox/HeaderBar/ProgressBox")
	if progress_box:
		progress_box.mouse_filter = Control.MOUSE_FILTER_STOP
		progress_box.gui_input.connect(_on_secret_tap_input)
		for child in progress_box.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_secret_tap_input(event: InputEvent) -> void:
	var is_tap: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_tap = true
	elif event is InputEventScreenTouch and event.pressed:
		is_tap = true

	if is_tap:
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if now - _secret_tap_last_time > 2.5:
			_secret_tap_count = 0
		_secret_tap_last_time = now
		_secret_tap_count += 1

		if _secret_tap_count >= 5:
			_secret_tap_count = 0
			_activate_dev_mode_secret()

func _activate_dev_mode_secret() -> void:
	is_debug_mode = true
	dev_bypass_active = true

	if not dev_toggle_btn:
		var header_bar: HBoxContainer = $MarginContainer/VBox/HeaderBar
		dev_toggle_btn = Button.new()
		dev_toggle_btn.name = "DevBypassToggle"
		dev_toggle_btn.custom_minimum_size = Vector2(130, 36)
		dev_toggle_btn.add_theme_font_size_override("font_size", 11)
		dev_toggle_btn.pressed.connect(_on_dev_toggle_pressed)
		header_bar.add_child(dev_toggle_btn)

	_update_dev_button_text()
	_refresh_tile_states()
	AudioManager.play_sfx("coin")

	modal_title.text = "🛠 DEV MODE UNLOCKED"
	modal_label.text = "Developer bypass active! All implemented levels (including Level 11: Meltdown) are unlocked for testing."
	message_modal.visible = true

func _update_dev_button_text() -> void:
	if not dev_toggle_btn:
		return
	if dev_bypass_active:
		dev_toggle_btn.text = "🛠 DEV: UNLOCKED"
		dev_toggle_btn.modulate = Color(0.3, 1.0, 0.7)
	else:
		dev_toggle_btn.text = "🛠 DEV: LOCKED"
		dev_toggle_btn.modulate = Color(0.7, 0.7, 0.7)

func _on_dev_toggle_pressed() -> void:
	if not is_debug_mode:
		dev_bypass_active = false
		return
	dev_bypass_active = !dev_bypass_active
	_update_dev_button_text()
	_refresh_tile_states()
	AudioManager.play_sfx("click")

func _build_world_navigation_cards() -> void:
	if not world_cards_bar:
		return
	for c in world_cards_bar.get_children():
		c.queue_free()
	world_card_buttons.clear()

	# 1. "ALL WORLDS" Tab Button
	var btn_all := Button.new()
	btn_all.name = "TabAllWorlds"
	btn_all.custom_minimum_size = Vector2(100, 48)
	btn_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_all.pressed.connect(func(): _select_world_tab(0))
	_style_nav_card(btn_all, 0, "ALL WORLDS", "Stages 1–20", Color(1.0, 0.82, 0.15))
	world_cards_bar.add_child(btn_all)
	world_card_buttons[0] = btn_all

	# 2. 4 Dedicated World Cards
	var world_configs: Array[Dictionary] = [
		{"id": 1, "title": "W1: NEON RUINS", "sub": "Stages 1–5", "col": Color(0.0, 0.92, 1.0)},
		{"id": 2, "title": "W2: HAUNTED HALL", "sub": "Stages 6–10", "col": Color(0.78, 0.55, 1.0)},
		{"id": 3, "title": "W3: RAGE FACTORY", "sub": "Stages 11–15", "col": Color(1.0, 0.65, 0.15)},
		{"id": 4, "title": "W4: FINAL HELL", "sub": "Stages 16–20", "col": Color(1.0, 0.30, 0.40)}
	]

	for cfg in world_configs:
		var wid: int = int(cfg["id"])
		var btn := Button.new()
		btn.name = "WorldNavCard_%d" % wid
		btn.custom_minimum_size = Vector2(170, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _select_world_tab(wid))
		_style_nav_card(btn, wid, str(cfg["title"]), str(cfg["sub"]), Color(cfg["col"]))
		world_cards_bar.add_child(btn)
		world_card_buttons[wid] = btn

func _style_nav_card(btn: Button, wid: int, title: String, sub: String, theme_col: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 1)

	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", theme_col)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.name = "Sub"
	sub_lbl.text = sub
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	btn.add_child(vbox)

	var sb_normal := _create_card_style(Color(0.08, 0.07, 0.15, 0.9), theme_col * 0.6, 2, Color.TRANSPARENT, 0)
	var sb_hover := _create_card_style(Color(0.12, 0.10, 0.22, 0.98), theme_col, 2, theme_col * 0.35, 6)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)

func _select_world_tab(wid: int) -> void:
	AudioManager.play_sfx("click")
	_drag_velocity = 0.0
	current_selected_world = wid
	_update_world_filter()
	_update_back_button_text()

func _update_world_filter() -> void:
	# Update active state of world navigation cards
	for wid in world_card_buttons.keys():
		var btn: Button = world_card_buttons[wid]
		if not btn:
			continue
		var is_selected: bool = (int(wid) == current_selected_world)
		var theme_col: Color = Color(1.0, 0.82, 0.15)
		match wid:
			1: theme_col = Color(0.0, 0.92, 1.0)
			2: theme_col = Color(0.78, 0.55, 1.0)
			3: theme_col = Color(1.0, 0.65, 0.15)
			4: theme_col = Color(1.0, 0.30, 0.40)
		if is_selected:
			var sb_active := _create_card_style(Color(0.14, 0.12, 0.26, 0.98), theme_col, 3, theme_col * 0.5, 8)
			btn.add_theme_stylebox_override("normal", sb_active)
		else:
			var sb_normal := _create_card_style(Color(0.08, 0.07, 0.15, 0.9), theme_col * 0.6, 2, Color.TRANSPARENT, 0)
			btn.add_theme_stylebox_override("normal", sb_normal)

	# Filter or highlight world sections in scroll container
	for wid in range(1, 5):
		var sec = worlds_container.get_node_or_null("WorldSection_%d" % wid)
		if sec:
			sec.visible = (current_selected_world == 0 or current_selected_world == wid)

	# Reset scroll offset when switching
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _update_back_button_text() -> void:
	if current_selected_world != 0:
		back_button.text = "◀ WORLDS"
	else:
		back_button.text = "◀ MENU"

func _update_ui() -> void:
	var cleared: int = SaveManager.get_completed_count()
	var implemented_count: int = GameManager.get_implemented_level_count()
	progress_label.text = "STAGES CLEARED: %d / %d" % [cleared, implemented_count]
	progress_bar.value = (float(cleared) / float(implemented_count)) * 100.0 if implemented_count > 0 else 0.0

	_update_world_filter()
	_update_back_button_text()
	_refresh_tile_states()

func get_level_button(lvl_id: int) -> Button:
	return find_child("LevelBtn_%d" % lvl_id, true, false) as Button

func _build_level_tiles() -> void:
	for child in worlds_container.get_children():
		child.queue_free()

	for wid in range(1, 5):
		var w_info: Dictionary = GameManager.worlds.get(wid, {})
		var w_name: String = str(w_info.get("name", "WORLD %d" % wid))
		var stages: Array = w_info.get("stages", [])

		# Section Container
		var section := VBoxContainer.new()
		section.name = "WorldSection_%d" % wid
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 8)

		# Header Bar
		var header_bar := HBoxContainer.new()
		header_bar.name = "WorldHeader_%d" % wid
		header_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_label := Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "WORLD %d — %s" % [wid, w_name]
		title_label.add_theme_font_size_override("font_size", 14)

		var header_color: Color = Color(0.0, 0.92, 1.0)
		match wid:
			1: header_color = Color(0.0, 0.92, 1.0) # Neon Cyan
			2: header_color = Color(0.78, 0.55, 1.0) # Spectral Violet
			3: header_color = Color(1.0, 0.65, 0.15) # Hazard Amber
			4: header_color = Color(1.0, 0.30, 0.40) # Hellfire Red
		title_label.add_theme_color_override("font_color", header_color)
		header_bar.add_child(title_label)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_bar.add_child(spacer)

		var stage_range_label := Label.new()
		var s_start: int = stages.front() if stages.size() > 0 else (wid * 5 - 4)
		var s_end: int = stages.back() if stages.size() > 0 else (wid * 5)
		stage_range_label.text = "STAGES %d–%d" % [s_start, s_end]
		stage_range_label.add_theme_font_size_override("font_size", 11)
		stage_range_label.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
		header_bar.add_child(stage_range_label)

		section.add_child(header_bar)

		# Grid for this world's 5 stages
		var grid := GridContainer.new()
		grid.name = "WorldGrid_%d" % wid
		grid.columns = 5
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)

		for lvl_id in stages:
			var info: Dictionary = GameManager.get_level_info(lvl_id)
			var lvl_name: String = info.get("name", "Stage %d" % lvl_id)

			var btn := Button.new()
			btn.custom_minimum_size = Vector2(170, 94)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			btn.name = "LevelBtn_%d" % lvl_id

			var vbox := VBoxContainer.new()
			vbox.name = "VBox"
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_theme_constant_override("separation", 3)

			var header_box := HBoxContainer.new()
			header_box.alignment = BoxContainer.ALIGNMENT_CENTER
			header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_box.add_theme_constant_override("separation", 6)

			var num_label := Label.new()
			num_label.text = "STAGE %d" % lvl_id
			num_label.add_theme_font_size_override("font_size", 14)
			num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_box.add_child(num_label)

			var status_icon := TextureRect.new()
			status_icon.name = "StatusIcon"
			status_icon.custom_minimum_size = Vector2(16, 16)
			status_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header_box.add_child(status_icon)

			vbox.add_child(header_box)

			var name_label := Label.new()
			name_label.text = lvl_name
			name_label.add_theme_font_size_override("font_size", 11)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(name_label)

			var state_label := Label.new()
			state_label.name = "StateLabel"
			state_label.add_theme_font_size_override("font_size", 10)
			state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(state_label)

			var stars_label := Label.new()
			stars_label.name = "StarsLabel"
			stars_label.add_theme_font_size_override("font_size", 11)
			stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(stars_label)

			btn.add_child(vbox)

			# Connect button click
			btn.pressed.connect(func(): _on_level_tile_pressed(lvl_id))
			grid.add_child(btn)

		section.add_child(grid)
		worlds_container.add_child(section)

func _refresh_tile_states() -> void:
	for lvl_id in range(1, 21):
		var btn: Button = get_level_button(lvl_id)
		if not btn:
			continue

		var vbox: VBoxContainer = btn.get_child(0)
		var header_box: HBoxContainer = vbox.get_child(0)
		var num_label: Label = header_box.get_child(0)
		var status_icon: TextureRect = header_box.get_child(1)
		var name_label: Label = vbox.get_child(1)
		var state_label: Label = vbox.get_child(2)
		var stars_label: Label = vbox.get_node_or_null("StarsLabel")

		var is_unlocked: bool = SaveManager.is_level_unlocked(lvl_id)
		var is_completed: bool = SaveManager.is_level_completed(lvl_id)
		var is_implemented: bool = GameManager.can_play_level(lvl_id)
		var can_dev_access: bool = is_debug_mode and dev_bypass_active and is_implemented
		var star_rating: int = SaveManager.get_level_stars(lvl_id)
		var world_id: int = GameManager.get_world_id_for_stage(lvl_id)

		if not is_implemented:
			# Unimplemented / Planned Stages (Stages 12–20)
			btn.add_theme_stylebox_override("normal", _style_planned_normal)
			btn.add_theme_stylebox_override("hover", _style_planned_hover)
			btn.add_theme_stylebox_override("focus", _style_planned_hover)
			num_label.add_theme_color_override("font_color", Color(0.40, 0.44, 0.52))
			name_label.add_theme_color_override("font_color", Color(0.35, 0.38, 0.46))
			state_label.text = "PLANNED"
			state_label.add_theme_color_override("font_color", Color(0.55, 0.45, 0.45))
			status_icon.texture = lock_icon
			status_icon.visible = true
			if stars_label:
				stars_label.text = ""
		elif is_completed:
			var sb_norm: StyleBoxFlat = _style_w1_comp_normal
			var sb_hov: StyleBoxFlat = _style_w1_comp_hover
			var num_col: Color = Color(0.0, 0.95, 0.8)
			match world_id:
				1:
					sb_norm = _style_w1_comp_normal
					sb_hov = _style_w1_comp_hover
					num_col = Color(0.0, 0.92, 1.0)
				2:
					sb_norm = _style_w2_comp_normal
					sb_hov = _style_w2_comp_hover
					num_col = Color(0.85, 0.65, 1.0)
				3:
					sb_norm = _style_w3_comp_normal
					sb_hov = _style_w3_comp_hover
					num_col = Color(1.0, 0.75, 0.25)
				4:
					sb_norm = _style_w4_comp_normal
					sb_hov = _style_w4_comp_hover
					num_col = Color(1.0, 0.45, 0.5)

			btn.add_theme_stylebox_override("normal", sb_norm)
			btn.add_theme_stylebox_override("hover", sb_hov)
			btn.add_theme_stylebox_override("focus", sb_hov)
			num_label.add_theme_color_override("font_color", num_col)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
			state_label.text = "COMPLETED"
			state_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.65))
			status_icon.texture = completed_icon
			status_icon.visible = true
			if stars_label:
				if star_rating == 3:
					stars_label.text = "★ ★ ★"
					stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
				elif star_rating == 2:
					stars_label.text = "★ ★ ☆"
					stars_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
				else:
					stars_label.text = "★ ☆ ☆" if star_rating == 1 else ""
					stars_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		elif is_unlocked:
			var sb_norm: StyleBoxFlat = _style_w1_avail_normal
			var sb_hov: StyleBoxFlat = _style_w1_avail_hover
			match world_id:
				1:
					sb_norm = _style_w1_avail_normal
					sb_hov = _style_w1_avail_hover
				2:
					sb_norm = _style_w2_avail_normal
					sb_hov = _style_w2_avail_hover
				3:
					sb_norm = _style_w3_avail_normal
					sb_hov = _style_w3_avail_hover
				4:
					sb_norm = _style_w4_avail_normal
					sb_hov = _style_w4_avail_hover

			btn.add_theme_stylebox_override("normal", sb_norm)
			btn.add_theme_stylebox_override("hover", sb_hov)
			btn.add_theme_stylebox_override("focus", sb_hov)
			num_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			state_label.text = "AVAILABLE"
			state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			status_icon.visible = false
			if stars_label:
				stars_label.text = "☆ ☆ ☆"
				stars_label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.7, 0.5))
		elif can_dev_access:
			btn.add_theme_stylebox_override("normal", _style_dev_normal)
			btn.add_theme_stylebox_override("hover", _style_dev_hover)
			btn.add_theme_stylebox_override("focus", _style_dev_hover)
			num_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
			name_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
			state_label.text = "DEV TEST"
			state_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			status_icon.visible = false
			if stars_label:
				stars_label.text = ""
		else:
			# Locked legitimate stages (Stages 2–11)
			btn.add_theme_stylebox_override("normal", _style_lock_normal)
			btn.add_theme_stylebox_override("hover", _style_lock_hover)
			btn.add_theme_stylebox_override("focus", _style_lock_hover)
			num_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			name_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
			state_label.text = "LOCKED"
			state_label.add_theme_color_override("font_color", Color(0.8, 0.35, 0.35))
			status_icon.texture = lock_icon
			status_icon.visible = true
			if stars_label:
				stars_label.text = ""

func _on_level_tile_pressed(level_id: int) -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if _is_dragging or now < _drag_suppress_click_until:
		return

	var is_unlocked: bool = SaveManager.is_level_unlocked(level_id)
	var is_implemented: bool = GameManager.can_play_level(level_id)

	if not is_implemented:
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IN PROGRESS" % level_id
		modal_label.text = "Level %d is still being built. Replay an earlier level for now." % level_id
		message_modal.visible = true
		return

	if not is_unlocked and not (is_debug_mode and dev_bypass_active):
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IS LOCKED" % level_id
		modal_label.text = "Locked! Beat the previous level first. The developer has enough problems already."
		message_modal.visible = true
		return

	# Launch level gameplay directly without mutating legitimate save progression
	AudioManager.play_sfx("click")
	GameManager.start_level(level_id)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	if current_selected_world != 0:
		# Return from specific world view to all worlds view
		current_selected_world = 0
		_update_world_filter()
		_update_back_button_text()
	else:
		# Return to main menu
		GameManager.go_to_main_menu()

func _on_modal_close() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false

func _input(event: InputEvent) -> void:
	if message_modal and message_modal.visible:
		return
	if not scroll_container or not scroll_container.is_visible_in_tree():
		return

	var s_rect: Rect2 = scroll_container.get_global_rect()
	var in_bounds: bool = true
	if s_rect.size.x > 0 and s_rect.size.y > 0:
		in_bounds = s_rect.has_point(event.position)

	if event is InputEventScreenTouch:
		if event.pressed:
			if in_bounds:
				_is_touch_active = true
				_drag_touch_id = event.index
				_drag_start_pos = event.position
				_drag_last_pos = event.position
				_drag_start_scroll_v = scroll_container.scroll_vertical
				_is_dragging = false
				_drag_velocity = 0.0
				_last_drag_time = float(Time.get_ticks_msec()) / 1000.0
		else:
			if _is_touch_active and event.index == _drag_touch_id:
				_finish_touch_drag()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if in_bounds:
					_is_touch_active = true
					_drag_touch_id = 0
					_drag_start_pos = event.position
					_drag_last_pos = event.position
					_drag_start_scroll_v = scroll_container.scroll_vertical
					_is_dragging = false
					_drag_velocity = 0.0
					_last_drag_time = float(Time.get_ticks_msec()) / 1000.0
			else:
				if _is_touch_active and _drag_touch_id == 0:
					_finish_touch_drag()

	elif event is InputEventScreenDrag:
		if _is_touch_active and event.index == _drag_touch_id:
			_process_drag_motion(event.position)

	elif event is InputEventMouseMotion:
		if _is_touch_active and _drag_touch_id == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_process_drag_motion(event.position)

func _process_drag_motion(current_pos: Vector2) -> void:
	var total_delta: Vector2 = current_pos - _drag_start_pos
	if not _is_dragging:
		if abs(total_delta.y) >= DRAG_THRESHOLD:
			_is_dragging = true

	if _is_dragging:
		var max_scroll: int = _get_max_scroll()
		var target_scroll: int = clampi(_drag_start_scroll_v - int(total_delta.y), 0, max_scroll)
		scroll_container.scroll_vertical = target_scroll

		var now: float = float(Time.get_ticks_msec()) / 1000.0
		var dt: float = now - _last_drag_time
		if dt > 0.001:
			var step_y: float = current_pos.y - _drag_last_pos.y
			var inst_vel: float = -step_y / dt
			_drag_velocity = lerp(_drag_velocity, inst_vel, 0.4)
		_drag_last_pos = current_pos
		_last_drag_time = now

func _finish_touch_drag() -> void:
	_is_touch_active = false
	_drag_touch_id = -1
	if _is_dragging:
		_drag_suppress_click_until = float(Time.get_ticks_msec()) / 1000.0 + 0.18
	_is_dragging = false

func _get_max_scroll() -> int:
	if not scroll_container:
		return 0
	var v_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if not v_bar:
		return 0
	var limit: float = v_bar.max_value - v_bar.page
	if limit <= 0 and v_bar.max_value > 0:
		limit = v_bar.max_value
	return maxi(0, int(limit))

func _process(delta: float) -> void:
	if not _is_touch_active and abs(_drag_velocity) > 15.0:
		var max_scroll: int = _get_max_scroll()
		var next_scroll: float = float(scroll_container.scroll_vertical) + _drag_velocity * delta
		var clamped_scroll: int = clampi(int(round(next_scroll)), 0, max_scroll)
		scroll_container.scroll_vertical = clamped_scroll

		if clamped_scroll <= 0 or clamped_scroll >= max_scroll:
			_drag_velocity = 0.0
		else:
			_drag_velocity = lerp(_drag_velocity, 0.0, DRAG_DECEL_FRICTION * delta)
	elif not _is_touch_active:
		_drag_velocity = 0.0
