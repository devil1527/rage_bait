class_name BulletBetrayalMenu
extends Control

## Dedicated level selection UI for Bullet Betrayal inside Retro Rage Arcade.
## Faithfully reproduces Coin Hell's menu architecture:
## Ambient glow bar, HeaderBar with BackButton (◀ MENU / ◀ WORLDS), TitleBox, ProgressBox,
## WorldCardsBar with ALL WORLDS + 4 World Tabs, ScrollContainer with 4 WorldSections
## containing 5 stage tiles ($170x94) each, locked/available/completed states,
## touch drag scrolling, and arcade MessageModal popups.

const LEVEL_1_SCENE: String = "res://scenes/bullet_betrayal/bb_level_1.tscn"
const ARCADE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

@onready var back_button: Button = $MarginContainer/VBox/HeaderBar/BackButton
@onready var progress_label: Label = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressBar
@onready var world_cards_bar: HBoxContainer = $MarginContainer/VBox/WorldCardsBar
@onready var scroll_container: ScrollContainer = $MarginContainer/VBox/ScrollContainer
@onready var worlds_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer

# Message Modal
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

var _style_lock_normal: StyleBoxFlat
var _style_lock_hover: StyleBoxFlat
var _style_planned_normal: StyleBoxFlat
var _style_planned_hover: StyleBoxFlat

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

const STAGE_NAMES: Dictionary = {
	1: "Border Infiltration",
	2: "River Ambush",
	3: "Supply Depot",
	4: "Radar Station",
	5: "Commander's Camp",
	6: "Dune Patrol",
	7: "Oasis Outpost",
	8: "Canyon Ambush",
	9: "Fuel Station",
	10: "Desert Command",
	11: "Mountain Pass",
	12: "Cliffside Battery",
	13: "Cableway Siege",
	14: "Bunker Breach",
	15: "Summit Fortress",
	16: "City Outskirts",
	17: "Rooftop Snipers",
	18: "Industrial Sector",
	19: "Courtyard Assault",
	20: "Final Stronghold"
}

func _init() -> void:
	_init_styles()

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

func _init_styles() -> void:
	# World 1: The Green Hills (Emerald/Cyan)
	_style_w1_comp_normal = _create_card_style(Color(0.04, 0.13, 0.18, 0.96), Color(0.2, 0.95, 0.55, 1.0), 2, Color(0.1, 0.9, 0.5, 0.4), 8)
	_style_w1_comp_hover = _create_card_style(Color(0.06, 0.18, 0.25, 0.98), Color(0.4, 1.0, 0.75, 1.0), 2, Color(0.2, 1.0, 0.6, 0.65), 12)
	_style_w1_avail_normal = _create_card_style(Color(0.08, 0.10, 0.18, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w1_avail_hover = _create_card_style(Color(0.11, 0.15, 0.26, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 2: Desert Outpost (Warm Desert Amber)
	_style_w2_comp_normal = _create_card_style(Color(0.15, 0.11, 0.05, 0.96), Color(0.9, 0.75, 0.30, 1.0), 2, Color(0.85, 0.7, 0.2, 0.4), 8)
	_style_w2_comp_hover = _create_card_style(Color(0.20, 0.15, 0.07, 0.98), Color(1.0, 0.85, 0.45, 1.0), 2, Color(0.95, 0.8, 0.3, 0.65), 12)
	_style_w2_avail_normal = _create_card_style(Color(0.12, 0.09, 0.06, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w2_avail_hover = _create_card_style(Color(0.16, 0.12, 0.08, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 3: Mountain Fortress (High Altitude Slate Violet)
	_style_w3_comp_normal = _create_card_style(Color(0.10, 0.09, 0.18, 0.96), Color(0.70, 0.65, 0.95, 1.0), 2, Color(0.65, 0.55, 0.9, 0.4), 8)
	_style_w3_comp_hover = _create_card_style(Color(0.14, 0.12, 0.25, 0.98), Color(0.85, 0.80, 1.0, 1.0), 2, Color(0.75, 0.65, 1.0, 0.65), 12)
	_style_w3_avail_normal = _create_card_style(Color(0.09, 0.08, 0.15, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w3_avail_hover = _create_card_style(Color(0.13, 0.11, 0.22, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# World 4: Urban Stronghold (Crimson Red)
	_style_w4_comp_normal = _create_card_style(Color(0.18, 0.05, 0.08, 0.96), Color(0.95, 0.45, 0.50, 1.0), 2, Color(0.9, 0.35, 0.4, 0.4), 8)
	_style_w4_comp_hover = _create_card_style(Color(0.24, 0.07, 0.11, 0.98), Color(1.0, 0.60, 0.65, 1.0), 2, Color(1.0, 0.45, 0.5, 0.65), 12)
	_style_w4_avail_normal = _create_card_style(Color(0.15, 0.05, 0.07, 0.96), Color(1.0, 0.85, 0.20, 1.0), 2, Color(1.0, 0.8, 0.15, 0.45), 8)
	_style_w4_avail_hover = _create_card_style(Color(0.20, 0.08, 0.10, 0.98), Color(1.0, 0.95, 0.40, 1.0), 3, Color(1.0, 0.88, 0.25, 0.7), 12)

	# Locked and Planned Styles
	_style_lock_normal = _create_card_style(Color(0.06, 0.06, 0.11, 0.88), Color(0.24, 0.27, 0.38, 0.85), 1, Color.TRANSPARENT, 0)
	_style_lock_hover = _create_card_style(Color(0.09, 0.09, 0.16, 0.94), Color(0.35, 0.40, 0.54, 0.95), 2, Color.TRANSPARENT, 0)
	_style_planned_normal = _create_card_style(Color(0.05, 0.05, 0.09, 0.82), Color(0.18, 0.20, 0.28, 0.70), 1, Color.TRANSPARENT, 0)
	_style_planned_hover = _create_card_style(Color(0.08, 0.08, 0.13, 0.90), Color(0.28, 0.30, 0.40, 0.85), 1, Color.TRANSPARENT, 0)

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	modal_ok_btn.pressed.connect(_on_modal_close)
	message_modal.visible = false

	_build_world_navigation_cards()
	_build_level_tiles()
	_update_ui()
	set_process(true)

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
		{"id": 1, "title": "W1: GREEN HILLS", "sub": "Stages 1–5", "col": Color(0.2, 0.95, 0.55)},
		{"id": 2, "title": "W2: DESERT OUTPOST", "sub": "Stages 6–10", "col": Color(0.9, 0.75, 0.30)},
		{"id": 3, "title": "W3: MOUNTAIN FORTRESS", "sub": "Stages 11–15", "col": Color(0.70, 0.65, 0.95)},
		{"id": 4, "title": "W4: URBAN STRONGHOLD", "sub": "Stages 16–20", "col": Color(0.95, 0.45, 0.50)}
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

func _style_nav_card(btn: Button, _wid: int, title: String, sub: String, theme_col: Color) -> void:
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
	for wid in world_card_buttons.keys():
		var btn: Button = world_card_buttons[wid]
		if not btn:
			continue
		var is_selected: bool = (int(wid) == current_selected_world)
		var theme_col: Color = Color(1.0, 0.82, 0.15)
		match wid:
			1: theme_col = Color(0.2, 0.95, 0.55)
			2: theme_col = Color(0.9, 0.75, 0.30)
			3: theme_col = Color(0.70, 0.65, 0.95)
			4: theme_col = Color(0.95, 0.45, 0.50)
		if is_selected:
			var sb_active := _create_card_style(Color(0.14, 0.12, 0.26, 0.98), theme_col, 3, theme_col * 0.5, 8)
			btn.add_theme_stylebox_override("normal", sb_active)
		else:
			var sb_normal := _create_card_style(Color(0.08, 0.07, 0.15, 0.9), theme_col * 0.6, 2, Color.TRANSPARENT, 0)
			btn.add_theme_stylebox_override("normal", sb_normal)

	for wid in range(1, 5):
		var sec = worlds_container.get_node_or_null("WorldSection_%d" % wid)
		if sec:
			sec.visible = (current_selected_world == 0 or current_selected_world == wid)

	if scroll_container:
		scroll_container.scroll_vertical = 0

func _update_back_button_text() -> void:
	if current_selected_world != 0:
		back_button.text = "◀ WORLDS"
	else:
		back_button.text = "◀ MENU"

func _update_ui() -> void:
	progress_label.text = "STAGES CLEARED: 0 / 20"
	progress_bar.value = 5.0 # Stage 1 active / 20

	_update_world_filter()
	_update_back_button_text()
	_refresh_tile_states()

func get_level_button(lvl_id: int) -> Button:
	return find_child("LevelBtn_%d" % lvl_id, true, false) as Button

func _build_level_tiles() -> void:
	for child in worlds_container.get_children():
		child.queue_free()

	var world_names: Dictionary = {
		1: "THE GREEN HILLS",
		2: "DESERT OUTPOST",
		3: "MOUNTAIN FORTRESS",
		4: "URBAN STRONGHOLD"
	}

	for wid in range(1, 5):
		var w_name: String = world_names.get(wid, "WORLD %d" % wid)
		var s_start: int = (wid - 1) * 5 + 1
		var s_end: int = wid * 5

		var section := VBoxContainer.new()
		section.name = "WorldSection_%d" % wid
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 8)

		var header_bar := HBoxContainer.new()
		header_bar.name = "WorldHeader_%d" % wid
		header_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_label := Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "WORLD %d — %s" % [wid, w_name]
		title_label.add_theme_font_size_override("font_size", 14)

		var header_color: Color = Color(0.2, 0.95, 0.55)
		match wid:
			1: header_color = Color(0.2, 0.95, 0.55)
			2: header_color = Color(0.9, 0.75, 0.30)
			3: header_color = Color(0.70, 0.65, 0.95)
			4: header_color = Color(0.95, 0.45, 0.50)
		title_label.add_theme_color_override("font_color", header_color)
		header_bar.add_child(title_label)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_bar.add_child(spacer)

		var stage_range_label := Label.new()
		stage_range_label.text = "STAGES %d–%d" % [s_start, s_end]
		stage_range_label.add_theme_font_size_override("font_size", 11)
		stage_range_label.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
		header_bar.add_child(stage_range_label)

		section.add_child(header_bar)

		var grid := GridContainer.new()
		grid.name = "WorldGrid_%d" % wid
		grid.columns = 5
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)

		for lvl_id in range(s_start, s_end + 1):
			var lvl_name: String = STAGE_NAMES.get(lvl_id, "Stage %d" % lvl_id)

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

		if lvl_id == 1:
			# Stage 1: Playable
			btn.add_theme_stylebox_override("normal", _style_w1_avail_normal)
			btn.add_theme_stylebox_override("hover", _style_w1_avail_hover)
			btn.add_theme_stylebox_override("focus", _style_w1_avail_hover)
			num_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			state_label.text = "AVAILABLE"
			state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			status_icon.visible = false
			if stars_label:
				stars_label.text = "☆ ☆ ☆"
				stars_label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.7, 0.5))
		else:
			# Stages 2–20: Locked
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

	if level_id == 1:
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file(LEVEL_1_SCENE)
	else:
		AudioManager.play_sfx("warning")
		modal_title.text = "STAGE %d IS LOCKED" % level_id
		var stage_name: String = STAGE_NAMES.get(level_id, "Stage %d" % level_id)
		modal_label.text = "Locked! Complete earlier missions before attempting %s." % stage_name
		message_modal.visible = true

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	if current_selected_world != 0:
		current_selected_world = 0
		_update_world_filter()
		_update_back_button_text()
	else:
		get_tree().change_scene_to_file(ARCADE_MAIN_MENU)

func _on_modal_close() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false

# Touch drag scrolling support matching Coin Hell
func _input(event: InputEvent) -> void:
	if message_modal and message_modal.visible:
		return
	if not scroll_container or not scroll_container.is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_is_touch_active = true
			_drag_touch_id = event.index
			_drag_start_pos = event.position
			_drag_last_pos = event.position
			_drag_start_scroll_v = scroll_container.scroll_vertical
			_is_dragging = false
			_drag_velocity = 0.0
			_last_drag_time = Time.get_ticks_msec() / 1000.0
		elif event.index == _drag_touch_id:
			_is_touch_active = false
			_drag_touch_id = -1
			if _is_dragging:
				_drag_suppress_click_until = (Time.get_ticks_msec() / 1000.0) + 0.15
				_is_dragging = false

	elif event is InputEventScreenDrag:
		if _is_touch_active and event.index == _drag_touch_id:
			var now: float = Time.get_ticks_msec() / 1000.0
			var dt: float = maxf(now - _last_drag_time, 0.001)
			var total_dy: float = event.position.y - _drag_start_pos.y

			if not _is_dragging and absf(total_dy) > DRAG_THRESHOLD:
				_is_dragging = true

			if _is_dragging:
				var dy: float = event.position.y - _drag_last_pos.y
				_drag_velocity = -dy / dt
				scroll_container.scroll_vertical = clampi(
					int(_drag_start_scroll_v - total_dy),
					0,
					maxi(0, int(worlds_container.size.y - scroll_container.size.y))
				)

			_drag_last_pos = event.position
			_last_drag_time = now

func _process(delta: float) -> void:
	if not _is_touch_active and absf(_drag_velocity) > 10.0:
		scroll_container.scroll_vertical = clampi(
			int(scroll_container.scroll_vertical + _drag_velocity * delta),
			0,
			maxi(0, int(worlds_container.size.y - scroll_container.size.y))
		)
		_drag_velocity = move_toward(_drag_velocity, 0.0, DRAG_DECEL_FRICTION * 100.0 * delta)
