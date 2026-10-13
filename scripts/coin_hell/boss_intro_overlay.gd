class_name BossIntroOverlay
extends Control

## World 2 Boss Stage Introduction Overlay
## Displays dramatic title, objective, and instructions before gameplay begins:
## WORLD 2
## THE HAUNTED HALL
## BOSS STAGE
## HAUNTED SURVIVAL
## SURVIVE FOR 1 MINUTE!
## Followed by dramatic pulsing "SURVIVE!" banner before releasing player control.

signal intro_completed

@onready var dark_background: ColorRect = $DarkBackground
@onready var content_box: VBoxContainer = $CenterContainer/ContentBox
@onready var world_label: Label = $CenterContainer/ContentBox/WorldLabel
@onready var boss_stage_label: Label = $CenterContainer/ContentBox/BossStageLabel
@onready var title_label: Label = $CenterContainer/ContentBox/TitleLabel
@onready var objective_label: Label = $CenterContainer/ContentBox/ObjectiveLabel
@onready var instruction_label: Label = $CenterContainer/ContentBox/InstructionLabel
@onready var survive_banner: Label = $SurviveBanner
@onready var skip_hint: Label = $SkipHint

var is_playing: bool = false
var _timer: float = 0.0
var _skipped: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_intro() -> void:
	visible = true
	is_playing = true
	_skipped = false
	_timer = 0.0
	
	dark_background.modulate.a = 0.85
	content_box.visible = true
	content_box.modulate.a = 1.0
	survive_banner.visible = false
	skip_hint.visible = true
	
	# Pulse objective label
	var tween := create_tween().set_loops(4)
	tween.tween_property(objective_label, "scale", Vector2(1.06, 1.06), 0.3)
	tween.tween_property(objective_label, "scale", Vector2(1.0, 1.0), 0.3)

func _process(delta: float) -> void:
	if not is_playing or _skipped:
		return
		
	_timer += delta
	
	# After 2.4s, transition to dramatic "SURVIVE!" banner
	if _timer >= 2.4 and content_box.visible:
		_show_survive_banner()
	elif _timer >= 3.4:
		_finish_intro()

func _input(event: InputEvent) -> void:
	if not is_playing or _skipped:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		skip()
	elif (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		skip()

func skip() -> void:
	if not is_playing or _skipped:
		return
	_skipped = true
	_finish_intro()

func _show_survive_banner() -> void:
	content_box.visible = false
	skip_hint.visible = false
	survive_banner.visible = true
	survive_banner.modulate.a = 1.0
	survive_banner.scale = Vector2(0.8, 0.8)
	
	AudioManager.play_sfx("click")
	var tween := create_tween()
	tween.tween_property(survive_banner, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(survive_banner, "modulate:a", 0.0, 0.45).set_delay(0.3)

func _finish_intro() -> void:
	is_playing = false
	visible = false
	intro_completed.emit()
