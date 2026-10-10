extends Control

@onready var resume_btn: Button = $Panel/VBox/ResumeBtn
@onready var restart_btn: Button = $Panel/VBox/RestartBtn
@onready var level_select_btn: Button = $Panel/VBox/LevelSelectBtn
@onready var sfx_btn: Button = $Panel/VBox/SfxBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	sfx_btn.pressed.connect(_on_sfx_pressed)
	_update_sfx_btn_text()

func _update_sfx_btn_text() -> void:
	sfx_btn.text = "SFX: ON" if SaveManager.sfx_enabled else "SFX: OFF"

func _on_sfx_pressed() -> void:
	SaveManager.toggle_sfx()
	_update_sfx_btn_text()
	AudioManager.play_sfx("click")

func open() -> void:
	_update_sfx_btn_text()
	visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	visible = false

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_level_select_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	GameManager.go_to_level_select()
