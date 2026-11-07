class_name BulletBetrayalMenu
extends Control

## Dedicated level selection UI for Bullet Betrayal inside Retro Rage Arcade.
## Follows the exact arcade design language established by Coin Hell:
## top ambient bar, header bar with back/title/progress/sfx, world pills,
## scrollable world panels with stage cards, touch scrolling, and message modals.

const LEVEL_1_SCENE: String = "res://scenes/bullet_betrayal/bb_level_1.tscn"
const ARCADE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

@onready var back_button: Button = $MarginContainer/VBox/HeaderBar/BackButton
@onready var sfx_btn: Button = $MarginContainer/VBox/HeaderBar/SfxBtn
@onready var scroll_container: ScrollContainer = $MarginContainer/VBox/ScrollContainer
@onready var worlds_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer

# World Filter Pills
@onready var pill_w1: Button = $MarginContainer/VBox/WorldCardsBar/PillW1
@onready var pill_w2: Button = $MarginContainer/VBox/WorldCardsBar/PillW2
@onready var pill_w3: Button = $MarginContainer/VBox/WorldCardsBar/PillW3
@onready var pill_w4: Button = $MarginContainer/VBox/WorldCardsBar/PillW4

# Stage buttons
@onready var stage_1_btn: Button = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card/Margin/VBox/StagesGrid/Stage1Btn
@onready var stage_2_btn: Button = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card/Margin/VBox/StagesGrid/Stage2Btn
@onready var stage_3_btn: Button = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card/Margin/VBox/StagesGrid/Stage3Btn
@onready var stage_4_btn: Button = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card/Margin/VBox/StagesGrid/Stage4Btn
@onready var stage_5_btn: Button = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card/Margin/VBox/StagesGrid/Stage5Btn

# World panels
@onready var world_1_card: PanelContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World1Card
@onready var world_2_card: PanelContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World2Card
@onready var world_3_card: PanelContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World3Card
@onready var world_4_card: PanelContainer = $MarginContainer/VBox/ScrollContainer/WorldsContainer/World4Card

# Message Modal
@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Header actions
	back_button.pressed.connect(_on_back_pressed)
	sfx_btn.pressed.connect(_on_sfx_toggle_pressed)

	# World filter pills
	pill_w1.pressed.connect(func(): _filter_world(1))
	pill_w2.pressed.connect(func(): _filter_world(2))
	pill_w3.pressed.connect(func(): _filter_world(3))
	pill_w4.pressed.connect(func(): _filter_world(4))

	# Stage 1 active deployment
	stage_1_btn.pressed.connect(_on_stage_1_pressed)

	# Locked stage buttons
	stage_2_btn.pressed.connect(func(): _show_locked_stage_modal("Stage 2: River Ambush"))
	stage_3_btn.pressed.connect(func(): _show_locked_stage_modal("Stage 3: Supply Depot"))
	stage_4_btn.pressed.connect(func(): _show_locked_stage_modal("Stage 4: Radar Station"))
	stage_5_btn.pressed.connect(func(): _show_locked_stage_modal("Stage 5: Commander's Camp"))

	# Modal actions
	modal_ok_btn.pressed.connect(_close_modal)
	message_modal.visible = false

	_update_sfx_button()

func _update_sfx_button() -> void:
	if SaveManager.sfx_enabled:
		sfx_btn.text = "SFX: ON"
		sfx_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
	else:
		sfx_btn.text = "SFX: OFF"
		sfx_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.7))

func _on_sfx_toggle_pressed() -> void:
	SaveManager.toggle_sfx()
	_update_sfx_button()
	AudioManager.play_sfx("click")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file(ARCADE_MAIN_MENU)

func _on_stage_1_pressed() -> void:
	if _is_dragging or Time.get_ticks_msec() / 1000.0 < _drag_suppress_click_until:
		return
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file(LEVEL_1_SCENE)

func _filter_world(world_idx: int) -> void:
	AudioManager.play_sfx("click")
	match world_idx:
		1:
			scroll_container.scroll_vertical = 0
		2:
			_show_locked_world_modal("WORLD 2: DESERT OUTPOST")
		3:
			_show_locked_world_modal("WORLD 3: MOUNTAIN FORTRESS")
		4:
			_show_locked_world_modal("WORLD 4: URBAN STRONGHOLD")

func _show_locked_stage_modal(stage_name: String) -> void:
	if _is_dragging or Time.get_ticks_msec() / 1000.0 < _drag_suppress_click_until:
		return
	AudioManager.play_sfx("click")
	modal_title.text = "SECTOR LOCKED"
	modal_label.text = "%s is classified.\nComplete Stage 1: Border Infiltration to gain combat clearance." % stage_name
	message_modal.visible = true

func _show_locked_world_modal(world_name: String) -> void:
	AudioManager.play_sfx("click")
	modal_title.text = "THEATER LOCKED"
	modal_label.text = "%s is locked by central command.\nComplete all World 1 operations to unlock this campaign theater." % world_name
	message_modal.visible = true

func _close_modal() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false

# Touch drag scrolling support matching Coin Hell
func _input(event: InputEvent) -> void:
	if message_modal.visible:
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
