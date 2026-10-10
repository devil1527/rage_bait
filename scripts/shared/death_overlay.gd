extends Control

signal retry_requested

@onready var retry_btn: Button = $Panel/VBox/RetryBtn
@onready var level_select_btn: Button = $Panel/VBox/LevelSelectBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_btn.pressed.connect(_on_retry_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)

func open() -> void:
	visible = true

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	retry_requested.emit()

func _on_level_select_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	GameManager.go_to_level_select()
