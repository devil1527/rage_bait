extends Control

@onready var coin_hell_card: Button = $MarginContainer/VBoxContainer/CardsGrid/CardCoinHell
@onready var bullet_betrayal_card: Button = $MarginContainer/VBoxContainer/CardsGrid/CardBulletBetrayal
@onready var ninja_nightmare_card: Button = $MarginContainer/VBoxContainer/CardsGrid/CardNinjaNightmare
@onready var castle_of_lies_card: Button = $MarginContainer/VBoxContainer/CardsGrid/CardCastleOfLies
@onready var sfx_toggle_btn: Button = $MarginContainer/VBoxContainer/HeaderBar/SfxToggleBtn
@onready var message_modal: Control = $MessageModal
@onready var modal_label: Label = $MessageModal/Panel/VBox/MessageLabel
@onready var modal_title: Label = $MessageModal/Panel/VBox/TitleLabel
@onready var modal_ok_btn: Button = $MessageModal/Panel/VBox/OkButton

func _ready() -> void:
	coin_hell_card.pressed.connect(_on_coin_hell_pressed)
	bullet_betrayal_card.pressed.connect(func(): _show_coming_soon("Bullet Betrayal"))
	ninja_nightmare_card.pressed.connect(func(): _show_coming_soon("Ninja Nightmare"))
	castle_of_lies_card.pressed.connect(func(): _show_coming_soon("Castle of Lies"))
	
	sfx_toggle_btn.pressed.connect(_on_sfx_toggle_pressed)
	modal_ok_btn.pressed.connect(_on_modal_close)
	message_modal.visible = false
	_update_sfx_button_text()

func _update_sfx_button_text() -> void:
	if SaveManager.sfx_enabled:
		sfx_toggle_btn.text = "SFX: ON"
		sfx_toggle_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.7, 1.0))
	else:
		sfx_toggle_btn.text = "SFX: OFF"
		sfx_toggle_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.7))

func _on_sfx_toggle_pressed() -> void:
	var enabled := SaveManager.toggle_sfx()
	_update_sfx_button_text()
	AudioManager.play_sfx("click")

func _on_coin_hell_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.go_to_level_select()

func _show_coming_soon(game_name: String) -> void:
	AudioManager.play_sfx("warning")
	modal_title.text = game_name.to_upper()
	modal_label.text = "This game is still in development. Coin Hell is ready to cause trouble first."
	message_modal.visible = true

func _on_modal_close() -> void:
	AudioManager.play_sfx("click")
	message_modal.visible = false
