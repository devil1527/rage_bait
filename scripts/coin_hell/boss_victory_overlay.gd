class_name BossVictoryOverlay
extends Control

## World 2 Boss Stage Victory Overlay
## Displays dramatic victory celebration:
## SURVIVED!
## 60 SECONDS IN HELL!
## WORLD 2 COMPLETE!
## With buttons to continue to World 3, level select, or replay.

signal replay_requested

@onready var survived_title: Label = $Panel/VBox/SurvivedTitle
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var world_complete_label: Label = $Panel/VBox/WorldCompleteLabel
@onready var coins_summary_label: Label = $Panel/VBox/CoinsSummaryLabel
@onready var next_level_btn: Button = $Panel/VBox/ButtonContainer/NextLevelBtn
@onready var replay_btn: Button = $Panel/VBox/ButtonContainer/ReplayBtn
@onready var level_select_btn: Button = $Panel/VBox/ButtonContainer/LevelSelectBtn

@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	next_level_btn.pressed.connect(_on_next_level_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	modal_ok_btn.pressed.connect(_on_modal_ok_pressed)
	message_modal.visible = false

func open(coins_collected: int, total_coins: int) -> void:
	visible = true
	coins_summary_label.text = "COINS COLLECTED: %d / %d" % [coins_collected, total_coins]
	
	# Dramatic punch scale-in
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	
	AudioManager.play_sfx("complete")

func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("click")
	var next_id := GameManager.current_level_id + 1 # 11 (World 3)
	if not GameManager.can_play_level(next_id):
		modal_title.text = "WORLD 3 IN PROGRESS"
		modal_label.text = "World 2 is Complete! World 3: Rage Factory is currently under construction. Replay earlier stages for now!"
		message_modal.visible = true
	else:
		GameManager.start_level(next_id)

func _on_modal_ok_pressed() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false

func _on_replay_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	replay_requested.emit()

func _on_level_select_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	GameManager.go_to_level_select()
