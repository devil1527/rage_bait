extends Control

signal retry_requested
signal revive_requested

@onready var revive_btn: Button = $Panel/VBox/ReviveBtn
@onready var ad_status_label: Label = $Panel/VBox/AdStatusLabel
@onready var retry_btn: Button = $Panel/VBox/RetryBtn
@onready var level_select_btn: Button = $Panel/VBox/LevelSelectBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	revive_btn.pressed.connect(_on_revive_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	ad_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	ad_status_label.gui_input.connect(_on_ad_status_label_gui_input)
	if AdManager:
		AdManager.rewarded_ad_loaded.connect(_on_ad_loaded)
		AdManager.rewarded_ad_failed_to_load.connect(_on_ad_failed_to_load)
		AdManager.network_state_changed.connect(_on_network_state_changed)

func open() -> void:
	visible = true
	_update_ad_status()
	# Proactively request ad if not ready yet and not currently loading
	if AdManager and not AdManager.is_rewarded_ad_ready() and not AdManager.is_loading():
		AdManager.load_rewarded_ad()

func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false

func _update_ad_status() -> void:
	if not is_inside_tree() or not visible:
		return

	if not AdManager:
		revive_btn.disabled = true
		ad_status_label.text = "Ad service unavailable"
		ad_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
		return

	if AdManager.is_rewarded_ad_ready():
		revive_btn.disabled = false
		revive_btn.text = "🎬 WATCH AD — REVIVE"
		ad_status_label.text = "Watch a short ad to revive here!"
		ad_status_label.modulate = Color(0.5, 1.0, 0.6, 0.9)
	elif AdManager.is_loading():
		revive_btn.disabled = true
		revive_btn.text = "🎬 WATCH AD — REVIVE"
		ad_status_label.text = "Loading ad..."
		ad_status_label.modulate = Color(1.0, 0.85, 0.3, 0.9)
	else:
		revive_btn.disabled = true
		revive_btn.text = "🎬 WATCH AD — REVIVE"
		ad_status_label.text = AdManager.get_status_text()
		if AdManager.last_error_type == AdManager.AdErrorType.NETWORK_ERROR or not AdManager.is_network_available:
			ad_status_label.modulate = Color(0.9, 0.5, 0.5, 0.9)
		elif AdManager.last_error_type == AdManager.AdErrorType.TIMEOUT:
			ad_status_label.modulate = Color(1.0, 0.7, 0.3, 0.9)
		elif AdManager.last_error_type == AdManager.AdErrorType.NO_FILL:
			ad_status_label.modulate = Color(0.8, 0.8, 0.8, 0.8)
		else:
			ad_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)

func _on_ad_status_label_gui_input(event: InputEvent) -> void:
	var is_click := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true

	if is_click and AdManager and not AdManager.is_rewarded_ad_ready() and not AdManager.is_loading():
		AudioManager.play_sfx("click")
		ad_status_label.text = "Loading ad..."
		ad_status_label.modulate = Color(1.0, 0.85, 0.3, 0.9)
		AdManager.retry_load_ad()

func _on_ad_loaded() -> void:
	if visible:
		_update_ad_status()

func _on_ad_failed_to_load(_error_type: Variant = 0, _error_code: Variant = null, _error_message: String = "") -> void:
	if visible:
		_update_ad_status()

func _on_network_state_changed(_available: bool) -> void:
	if visible:
		_update_ad_status()

func _on_revive_pressed() -> void:
	AudioManager.play_sfx("click")
	# Prevent repeated taps while ad request is in progress
	revive_btn.disabled = true
	retry_btn.disabled = true
	ad_status_label.text = "Preparing ad..."
	ad_status_label.modulate = Color(1.0, 0.9, 0.4, 1.0)
	get_tree().paused = true

	var started := AdManager.show_rewarded_ad_for_revive(
		_on_revive_reward_granted,
		_on_revive_ad_failed
	)
	if not started:
		get_tree().paused = false
		retry_btn.disabled = false
		_update_ad_status()

func _on_revive_reward_granted() -> void:
	print("[DeathOverlay] Authoritative revive reward received.")
	get_tree().paused = false
	visible = false
	revive_btn.disabled = false
	retry_btn.disabled = false
	# Centralized revive execution
	GameManager.revive_current_player()
	revive_requested.emit()

func _on_revive_ad_failed(reason: String) -> void:
	print("[DeathOverlay] Ad flow failed or dismissed: %s" % reason)
	get_tree().paused = false
	# Re-enable controls and explain situation clearly without granting revive
	retry_btn.disabled = false
	_update_ad_status()
	ad_status_label.text = reason
	ad_status_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("click")
	if AdManager:
		AdManager.cancel_current_transaction()
	visible = false
	get_tree().paused = false
	retry_requested.emit()

func _on_level_select_pressed() -> void:
	AudioManager.play_sfx("click")
	if AdManager:
		AdManager.cancel_current_transaction()
	visible = false
	get_tree().paused = false
	GameManager.go_to_level_select()
