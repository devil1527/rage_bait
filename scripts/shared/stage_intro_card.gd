class_name StageIntroCard
extends CanvasLayer

## StageIntroCard displays a brief, stylish transition card when entering
## a stage for the first time in a gameplay session.
## Automatically fades out after a short duration, and can be skipped on tap/input.
## Does NOT reappear on retry or death.

@onready var card_panel: PanelContainer = $CenterContainer/CardPanel
@onready var world_num_label: Label = $CenterContainer/CardPanel/VBox/WorldNumLabel
@onready var world_name_label: Label = $CenterContainer/CardPanel/VBox/WorldNameLabel
@onready var stage_label: Label = $CenterContainer/CardPanel/VBox/StageLabel
@onready var tap_hint_label: Label = $CenterContainer/CardPanel/VBox/TapHintLabel
@onready var fade_rect: ColorRect = $FadeRect
@onready var center_container: CenterContainer = $CenterContainer

var _is_dismissing: bool = false
var _display_timer: float = 1.35
var _elapsed: float = 0.0

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initial fade in
	fade_rect.modulate.a = 0.0
	center_container.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(center_container, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)

func setup(world_num: int, world_name: String, stage_num: int, stage_title: String = "") -> void:
	if not world_num_label:
		world_num_label = $CenterContainer/CardPanel/VBox/WorldNumLabel
	if not world_name_label:
		world_name_label = $CenterContainer/CardPanel/VBox/WorldNameLabel
	if not stage_label:
		stage_label = $CenterContainer/CardPanel/VBox/StageLabel
		
	world_num_label.text = "WORLD %d" % world_num
	world_name_label.text = world_name.to_upper()
	
	if stage_title.is_empty() or stage_title.begins_with("STAGE"):
		stage_label.text = "STAGE %d" % stage_num
	else:
		stage_label.text = "STAGE %d: %s" % [stage_num, stage_title.to_upper()]

func _process(delta: float) -> void:
	if _is_dismissing:
		return
	_elapsed += delta
	if _elapsed >= _display_timer:
		dismiss()

func _input(event: InputEvent) -> void:
	if _is_dismissing:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		dismiss()
	elif (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		dismiss()

func dismiss() -> void:
	if _is_dismissing:
		return
	_is_dismissing = true
	var tween := create_tween().set_parallel(true)
	if fade_rect and center_container:
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(center_container, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(queue_free)
