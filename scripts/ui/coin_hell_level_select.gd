extends Control

@onready var back_button: Button = $MarginContainer/VBox/HeaderBar/BackButton
@onready var progress_label: Label = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressBar
@onready var worlds_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer
@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

var lock_icon: Texture2D = preload("res://assets/sprites/icon_lock.png")
var completed_icon: Texture2D = preload("res://assets/sprites/icon_completed.png")

var _style_comp_normal: StyleBoxFlat
var _style_comp_hover: StyleBoxFlat
var _style_avail_normal: StyleBoxFlat
var _style_avail_hover: StyleBoxFlat
var _style_lock_normal: StyleBoxFlat
var _style_lock_hover: StyleBoxFlat
var _style_dev_normal: StyleBoxFlat
var _style_dev_hover: StyleBoxFlat

var is_debug_mode: bool = OS.is_debug_build()
var dev_bypass_active: bool = false
var dev_toggle_btn: Button = null

func _init() -> void:
	_init_styles()

func _init_styles() -> void:
	_style_comp_normal = StyleBoxFlat.new()
	_style_comp_normal.bg_color = Color(0.08, 0.18, 0.16, 0.95)
	_style_comp_normal.set_border_width_all(2)
	_style_comp_normal.border_color = Color(0.0, 0.95, 0.65, 1.0)
	_style_comp_normal.set_corner_radius_all(8)
	
	_style_comp_hover = StyleBoxFlat.new()
	_style_comp_hover.bg_color = Color(0.12, 0.24, 0.22, 0.98)
	_style_comp_hover.set_border_width_all(2)
	_style_comp_hover.border_color = Color(0.2, 1.0, 0.75, 1.0)
	_style_comp_hover.set_corner_radius_all(8)

	_style_avail_normal = StyleBoxFlat.new()
	_style_avail_normal.bg_color = Color(0.15, 0.12, 0.26, 0.95)
	_style_avail_normal.set_border_width_all(2)
	_style_avail_normal.border_color = Color(1.0, 0.82, 0.15, 1.0)
	_style_avail_normal.set_corner_radius_all(8)
	_style_avail_normal.shadow_color = Color(1.0, 0.75, 0.1, 0.3)
	_style_avail_normal.shadow_size = 4

	_style_avail_hover = StyleBoxFlat.new()
	_style_avail_hover.bg_color = Color(0.20, 0.16, 0.34, 0.98)
	_style_avail_hover.set_border_width_all(3)
	_style_avail_hover.border_color = Color(1.0, 0.92, 0.35, 1.0)
	_style_avail_hover.set_corner_radius_all(8)
	_style_avail_hover.shadow_color = Color(1.0, 0.85, 0.2, 0.5)
	_style_avail_hover.shadow_size = 6

	_style_lock_normal = StyleBoxFlat.new()
	_style_lock_normal.bg_color = Color(0.08, 0.08, 0.13, 0.85)
	_style_lock_normal.set_border_width_all(1)
	_style_lock_normal.border_color = Color(0.22, 0.25, 0.35, 0.85)
	_style_lock_normal.set_corner_radius_all(8)

	_style_lock_hover = StyleBoxFlat.new()
	_style_lock_hover.bg_color = Color(0.12, 0.12, 0.18, 0.92)
	_style_lock_hover.set_border_width_all(2)
	_style_lock_hover.border_color = Color(0.32, 0.36, 0.48, 0.9)
	_style_lock_hover.set_corner_radius_all(8)

	_style_dev_normal = StyleBoxFlat.new()
	_style_dev_normal.bg_color = Color(0.06, 0.14, 0.22, 0.95)
	_style_dev_normal.set_border_width_all(2)
	_style_dev_normal.border_color = Color(0.0, 0.75, 1.0, 1.0)
	_style_dev_normal.set_corner_radius_all(8)
	_style_dev_normal.shadow_color = Color(0.0, 0.6, 1.0, 0.3)
	_style_dev_normal.shadow_size = 4

	_style_dev_hover = StyleBoxFlat.new()
	_style_dev_hover.bg_color = Color(0.10, 0.20, 0.32, 0.98)
	_style_dev_hover.set_border_width_all(3)
	_style_dev_hover.border_color = Color(0.3, 0.9, 1.0, 1.0)
	_style_dev_hover.set_corner_radius_all(8)
	_style_dev_hover.shadow_color = Color(0.0, 0.8, 1.0, 0.5)
	_style_dev_hover.shadow_size = 6

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

	_build_level_tiles()
	_update_ui()

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

func _update_ui() -> void:
	var cleared: int = SaveManager.get_completed_count()
	progress_label.text = "LEVELS CLEARED: %d / 20" % cleared
	progress_bar.value = float(cleared) / 20.0 * 100.0
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
		
		var header_color: Color = Color(0.0, 0.9, 1.0)
		match wid:
			1: header_color = Color(0.0, 0.9, 1.0) # Neon Cyan
			2: header_color = Color(0.75, 0.55, 1.0) # Spectral Violet
			3: header_color = Color(1.0, 0.75, 0.2) # Hazard Amber
			4: header_color = Color(1.0, 0.35, 0.35) # Hellfire Red
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
		stage_range_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
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
		
		var is_unlocked: bool = SaveManager.is_level_unlocked(lvl_id)
		var is_completed: bool = SaveManager.is_level_completed(lvl_id)
		var is_implemented: bool = GameManager.can_play_level(lvl_id)
		var can_dev_access: bool = is_debug_mode and dev_bypass_active and is_implemented

		if is_completed:
			btn.add_theme_stylebox_override("normal", _style_comp_normal)
			btn.add_theme_stylebox_override("hover", _style_comp_hover)
			btn.add_theme_stylebox_override("focus", _style_comp_hover)
			num_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.8))
			name_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.9))
			state_label.text = "COMPLETED"
			state_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
			status_icon.texture = completed_icon
			status_icon.visible = true
		elif is_unlocked:
			btn.add_theme_stylebox_override("normal", _style_avail_normal)
			btn.add_theme_stylebox_override("hover", _style_avail_hover)
			btn.add_theme_stylebox_override("focus", _style_avail_hover)
			num_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			state_label.text = "AVAILABLE"
			state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			status_icon.visible = false
		elif can_dev_access:
			btn.add_theme_stylebox_override("normal", _style_dev_normal)
			btn.add_theme_stylebox_override("hover", _style_dev_hover)
			btn.add_theme_stylebox_override("focus", _style_dev_hover)
			num_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
			name_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
			state_label.text = "DEV TEST"
			state_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			status_icon.visible = false
		else:
			btn.add_theme_stylebox_override("normal", _style_lock_normal)
			btn.add_theme_stylebox_override("hover", _style_lock_hover)
			btn.add_theme_stylebox_override("focus", _style_lock_hover)
			num_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			name_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
			state_label.text = "LOCKED"
			state_label.add_theme_color_override("font_color", Color(0.8, 0.35, 0.35))
			status_icon.texture = lock_icon
			status_icon.visible = true

func _on_level_tile_pressed(level_id: int) -> void:
	var is_unlocked: bool = SaveManager.is_level_unlocked(level_id)
	var is_implemented: bool = GameManager.can_play_level(level_id)

	if not is_unlocked and not (is_debug_mode and dev_bypass_active):
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IS LOCKED" % level_id
		modal_label.text = "Locked! Beat the previous level first. The developer has enough problems already."
		message_modal.visible = true
		return

	if not is_implemented:
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IN PROGRESS" % level_id
		modal_label.text = "Level %d is still being built. Replay an earlier level for now." % level_id
		message_modal.visible = true
		return

	# Launch level gameplay directly without mutating legitimate save progression
	AudioManager.play_sfx("click")
	GameManager.start_level(level_id)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.go_to_main_menu()

func _on_modal_close() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false
