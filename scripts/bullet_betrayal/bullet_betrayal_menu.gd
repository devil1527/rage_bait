class_name BulletBetrayalMenu
extends Control

## Dedicated menu for Bullet Betrayal inside Retro Rage Arcade.

const LEVEL_1_SCENE: String = "res://scenes/bullet_betrayal/bb_level_1.tscn"
const ARCADE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

@onready var deploy_btn: Button = $MarginContainer/VBox/MissionCard/VBox/DeployBtn
@onready var back_btn: Button = $MarginContainer/VBox/HeaderBar/BackBtn
@onready var sfx_btn: Button = $MarginContainer/VBox/HeaderBar/SfxBtn
@onready var message_modal: Control = $MessageModal
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	deploy_btn.pressed.connect(_on_deploy_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	sfx_btn.pressed.connect(_on_sfx_toggle_pressed)
	modal_ok_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		message_modal.visible = false
	)
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

func _on_deploy_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file(LEVEL_1_SCENE)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file(ARCADE_MAIN_MENU)
