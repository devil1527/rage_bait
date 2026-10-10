extends Control

@onready var back_button: Button = $MarginContainer/VBox/HeaderBar/BackButton
@onready var progress_label: Label = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBox/HeaderBar/ProgressBox/ProgressBar
@onready var grid_container: GridContainer = $MarginContainer/VBox/ScrollContainer/LevelGrid
@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

var lock_icon: Texture2D = preload("res://assets/sprites/icon_lock.png")
var completed_icon: Texture2D = preload("res://assets/sprites/icon_completed.png")

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	modal_ok_btn.pressed.connect(_on_modal_close)
	message_modal.visible = false
	SaveManager.progress_updated.connect(_update_ui)
	_build_level_tiles()
	_update_ui()

func _update_ui() -> void:
	var cleared: int = SaveManager.get_completed_count()
	progress_label.text = "LEVELS CLEARED: %d / 20" % cleared
	progress_bar.value = float(cleared) / 20.0 * 100.0
	_refresh_tile_states()

func _build_level_tiles() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	for lvl_id in range(1, 21):
		var info: Dictionary = GameManager.get_level_info(lvl_id)
		var lvl_name: String = info.get("name", "Level %d" % lvl_id)
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 85)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.name = "LevelBtn_%d" % lvl_id
		
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var header_box := HBoxContainer.new()
		header_box.alignment = BoxContainer.ALIGNMENT_CENTER
		header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var num_label := Label.new()
		num_label.text = "LEVEL %d" % lvl_id
		num_label.add_theme_font_size_override("font_size", 16)
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
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)
		
		var state_label := Label.new()
		state_label.name = "StateLabel"
		state_label.add_theme_font_size_override("font_size", 11)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(state_label)
		
		btn.add_child(vbox)
		
		# Connect button click
		btn.pressed.connect(func(): _on_level_tile_pressed(lvl_id))
		grid_container.add_child(btn)

func _refresh_tile_states() -> void:
	for lvl_id in range(1, 21):
		var btn: Button = grid_container.get_node_or_null("LevelBtn_%d" % lvl_id)
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
		
		if is_completed:
			num_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.8))
			name_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.9))
			state_label.text = "COMPLETED"
			state_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
			status_icon.texture = completed_icon
			status_icon.visible = true
		elif is_unlocked:
			num_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			state_label.text = "AVAILABLE"
			state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			status_icon.visible = false
		else:
			num_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			name_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
			state_label.text = "LOCKED"
			state_label.add_theme_color_override("font_color", Color(0.8, 0.35, 0.35))
			status_icon.texture = lock_icon
			status_icon.visible = true

func _on_level_tile_pressed(level_id: int) -> void:
	if not SaveManager.is_level_unlocked(level_id):
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IS LOCKED" % level_id
		modal_label.text = "Locked! Beat the previous level first. The developer has enough problems already."
		message_modal.visible = true
		return

	if not GameManager.can_play_level(level_id):
		AudioManager.play_sfx("warning")
		modal_title.text = "LEVEL %d IN PROGRESS" % level_id
		modal_label.text = "Level %d is unlocked, but it's still being built. Replay Level 1 for now." % level_id
		message_modal.visible = true
		return

	# Launch Level 1 gameplay
	AudioManager.play_sfx("click")
	GameManager.start_level(level_id)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.go_to_main_menu()

func _on_modal_close() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false
