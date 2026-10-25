extends Control

signal replay_requested

@onready var coins_label: Label = $Panel/VBox/CoinsLabel
@onready var stars_label: Label = $Panel/VBox/StarsLabel
@onready var rating_status_label: Label = $Panel/VBox/RatingStatusLabel
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

func open(coins_collected: int, total_coins: int, earned_stars: int = -1) -> void:
	coins_label.text = "COINS COLLECTED: %d / %d" % [coins_collected, total_coins]
	var stars: int = earned_stars if earned_stars > 0 else (GameManager.last_run_stars if GameManager else 3)
	
	var title_lbl: Label = get_node_or_null("Panel/VBox/Title")
	if GameManager and GameManager.current_level_id == 20:
		if title_lbl:
			title_lbl.text = "CONGRATULATIONS!"
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		if rating_status_label:
			rating_status_label.text = "THE FINAL BETRAYAL — COMPLETED"
			rating_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
		if next_level_btn:
			next_level_btn.text = "▶ NEXT"
	else:
		if title_lbl:
			title_lbl.text = "LEVEL COMPLETE!"
			title_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6, 1.0))
		if next_level_btn:
			next_level_btn.text = "▶ NEXT LEVEL"
	
	if stars_label:
		if stars == 3:
			stars_label.text = "★ ★ ★"
			stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
			if rating_status_label and GameManager and GameManager.current_level_id != 20:
				rating_status_label.text = "PERFECT CLEAR! (NO REVIVES)"
				rating_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
		elif stars == 2:
			stars_label.text = "★ ★ ☆"
			stars_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 1.0))
			if rating_status_label and GameManager and GameManager.current_level_id != 20:
				rating_status_label.text = "REVIVED CLEAR (2 STARS)"
				rating_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
		else:
			stars_label.text = "★ ☆ ☆"
			stars_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			if rating_status_label and GameManager and GameManager.current_level_id != 20:
				rating_status_label.text = "LEVEL COMPLETED"
				rating_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	visible = true

func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("click")
	if GameManager and GameManager.current_level_id >= 20:
		visible = false
		GameManager.go_to_level_select()
		return
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
