extends Control

signal replay_requested

@onready var coins_label: Label = $Panel/VBox/CoinsLabel
@onready var next_level_btn: Button = $Panel/VBox/NextLevelBtn
@onready var replay_btn: Button = $Panel/VBox/ReplayBtn
@onready var level_select_btn: Button = $Panel/VBox/LevelSelectBtn

@onready var message_modal: Control = $MessageModal
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	next_level_btn.pressed.connect(_on_next_level_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	modal_ok_btn.pressed.connect(_on_modal_ok_pressed)
	message_modal.visible = false

func open(coins_collected: int, total_coins: int) -> void:
	coins_label.text = "COINS COLLECTED: %d / %d" % [coins_collected, total_coins]
	visible = true

func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("click")
	var next_id := GameManager.current_level_id + 1
	if not GameManager.can_play_level(next_id):
		# Show unimplemented Level message as required by spec Section 5 & 8 & 12
		modal_title.text = "LEVEL %d IN PROGRESS" % next_id
		modal_label.text = "Level %d is unlocked, but it's still being built. Replay Level 1 for now." % next_id
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
