class_name BulletBetrayalHUD
extends CanvasLayer

## Mobile-first gameplay HUD for Bullet Betrayal.
## Manages 1-life health indicator, ammunition counters, target/enemy trackers,
## dry-fire alerts, on-screen multitouch controls, rewarded ad revives,
## and Coin Hell-standard pause/popup overlays.

signal restart_requested
signal menu_requested
signal arcade_requested
signal revive_requested

@onready var health_label: Label = $TopBar/Margin/HBox/HealthBox/HealthLabel
@onready var ammo_label: Label = $TopBar/Margin/HBox/AmmoBox/AmmoLabel
@onready var targets_label: Label = get_node_or_null("TopBar/Margin/HBox/TargetsBox/TargetsLabel")
@onready var stage_label: Label = $TopBar/Margin/HBox/StageBox/StageLabel
@onready var pause_btn: Button = $TopBar/Margin/HBox/PauseBtn

# Touch buttons
@onready var left_btn: TextureButton = $TouchControls/LeftBtn
@onready var right_btn: TextureButton = $TouchControls/RightBtn
@onready var jump_btn: TextureButton = $TouchControls/JumpBtn
@onready var shoot_btn: TextureButton = $TouchControls/ShootBtn

# Overlays
@onready var pause_overlay: Control = $Overlays/PauseOverlay
@onready var death_overlay: Control = $Overlays/DeathOverlay
@onready var victory_overlay: Control = $Overlays/VictoryOverlay

# Pause Overlay elements
@onready var pause_resume_btn: Button = $Overlays/PauseOverlay/Panel/VBox/ResumeBtn
@onready var pause_restart_btn: Button = $Overlays/PauseOverlay/Panel/VBox/RestartBtn
@onready var pause_mission_btn: Button = $Overlays/PauseOverlay/Panel/VBox/MissionSelectBtn
@onready var pause_arcade_btn: Button = $Overlays/PauseOverlay/Panel/VBox/ArcadeMenuBtn
@onready var pause_sfx_btn: Button = $Overlays/PauseOverlay/Panel/VBox/SfxBtn

# Confirmation Modal inside PauseOverlay
@onready var confirm_modal: Control = $Overlays/PauseOverlay/ConfirmModal
@onready var modal_title: Label = $Overlays/PauseOverlay/ConfirmModal/Panel/VBox/TitleLabel
@onready var modal_message: Label = $Overlays/PauseOverlay/ConfirmModal/Panel/VBox/MessageLabel
@onready var modal_cancel_btn: Button = $Overlays/PauseOverlay/ConfirmModal/Panel/VBox/HBox/CancelBtn
@onready var modal_confirm_btn: Button = $Overlays/PauseOverlay/ConfirmModal/Panel/VBox/HBox/ConfirmBtn

# Death Overlay elements
@onready var death_revive_btn: Button = get_node_or_null("Overlays/DeathOverlay/Panel/VBox/ReviveBtn")
@onready var death_ad_status: Label = get_node_or_null("Overlays/DeathOverlay/Panel/VBox/AdStatusLabel")
@onready var death_retry_btn: Button = $Overlays/DeathOverlay/Panel/VBox/RetryBtn
@onready var death_mission_btn: Button = $Overlays/DeathOverlay/Panel/VBox/MissionSelectBtn
@onready var death_arcade_btn: Button = $Overlays/DeathOverlay/Panel/VBox/ArcadeMenuBtn

# Victory Overlay buttons
@onready var victory_replay_btn: Button = $Overlays/VictoryOverlay/Panel/VBox/ReplayBtn
@onready var victory_mission_btn: Button = $Overlays/VictoryOverlay/Panel/VBox/MissionSelectBtn
@onready var victory_arcade_btn: Button = $Overlays/VictoryOverlay/Panel/VBox/ArcadeMenuBtn
@onready var victory_stats_label: Label = $Overlays/VictoryOverlay/Panel/VBox/StatsLabel

var _player_ref: BulletBetrayalPlayer = null
var _pending_confirm_action: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pause button inputs (both click and touchscreen touch)
	pause_btn.pressed.connect(_on_pause_pressed)
	pause_btn.gui_input.connect(_on_pause_gui_input)

	# Pause menu buttons
	pause_resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_restart_btn.pressed.connect(func(): _open_confirm("restart"))
	pause_mission_btn.pressed.connect(func(): _open_confirm("mission_select"))
	pause_arcade_btn.pressed.connect(func(): _open_confirm("arcade_menu"))
	pause_sfx_btn.pressed.connect(_on_sfx_toggle_pressed)

	# Confirm modal buttons
	modal_cancel_btn.pressed.connect(_close_confirm)
	modal_confirm_btn.pressed.connect(_execute_confirm)

	# Death menu buttons
	if death_revive_btn:
		death_revive_btn.pressed.connect(_on_revive_ad_pressed)
	death_retry_btn.pressed.connect(_on_restart_pressed)
	death_mission_btn.pressed.connect(_on_mission_pressed)
	death_arcade_btn.pressed.connect(_on_arcade_pressed)

	# Victory menu buttons
	victory_replay_btn.pressed.connect(_on_restart_pressed)
	victory_mission_btn.pressed.connect(_on_mission_pressed)
	victory_arcade_btn.pressed.connect(_on_arcade_pressed)

	# AdManager signals
	if AdManager:
		AdManager.initialization_completed.connect(func(_ok): if death_overlay.visible: _update_death_ad_status())
		AdManager.rewarded_ad_loaded.connect(func(): if death_overlay.visible: _update_death_ad_status())
		AdManager.rewarded_ad_failed_to_load.connect(func(_t, _c, _m): if death_overlay.visible: _update_death_ad_status())
		AdManager.network_state_changed.connect(func(_n): if death_overlay.visible: _update_death_ad_status())

	# Initial overlay states
	pause_overlay.visible = false
	confirm_modal.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false
	_update_sfx_btn_text()

func connect_player(player: BulletBetrayalPlayer) -> void:
	_player_ref = player
	player.health_updated.connect(update_health)
	player.ammo_updated.connect(update_ammo)
	player.dry_fire.connect(_on_dry_fire)
	player.player_died.connect(_on_player_died)

	# Direct virtual touch wiring to player
	left_btn.touch_down.connect(func(): player.touch_left = true)
	left_btn.touch_up.connect(func(): player.touch_left = false)

	right_btn.touch_down.connect(func(): player.touch_right = true)
	right_btn.touch_up.connect(func(): player.touch_right = false)

	jump_btn.touch_down.connect(func():
		player.touch_jump = true
		player.touch_jump_just_pressed = true
	)
	jump_btn.touch_up.connect(func():
		player.touch_jump = false
		player.touch_jump_just_released = true
	)

	shoot_btn.touch_down.connect(func():
		player.touch_shoot = true
		player.touch_shoot_just_pressed = true
	)
	shoot_btn.touch_up.connect(func():
		player.touch_shoot = false
	)

	update_health(player.current_health, player.max_health)
	update_ammo(player.current_ammo, player.max_ammo)
	update_targets(0, 10)

## One-hit death system: displays single life status
func update_health(current: int, _max_amount: int) -> void:
	if not health_label:
		return
	if current > 0:
		health_label.text = "♥ LIFE: 1 / 1"
		health_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
	else:
		health_label.text = "♥ LIFE: 0 / 1"
		health_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))

func update_ammo(current: int, _max_amount: int) -> void:
	if not ammo_label:
		return
	ammo_label.text = "AMMO: %d" % current
	if current == 0:
		ammo_label.text = "AMMO: 0 (EMPTY)"
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	elif current <= 3:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1.0))
	else:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))

func update_targets(current: int, required: int = 10) -> void:
	if not targets_label:
		return
	targets_label.text = "🎯 TARGETS: %d / %d" % [current, required]
	if current >= required:
		targets_label.text = "🎯 TARGETS: %d / %d (CLEAR)" % [current, required]
		targets_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
	else:
		targets_label.add_theme_color_override("font_color", Color(0.0, 0.92, 1.0, 1.0))

func _on_dry_fire() -> void:
	if not ammo_label:
		return
	var tween := create_tween()
	tween.tween_property(ammo_label, "modulate", Color(2.0, 0.2, 0.2, 1.0), 0.05)
	tween.tween_property(ammo_label, "modulate", Color.WHITE, 0.1)

func reset_touch_controls() -> void:
	if left_btn and left_btn.has_method("reset"):
		left_btn.reset()
	if right_btn and right_btn.has_method("reset"):
		right_btn.reset()
	if jump_btn and jump_btn.has_method("reset"):
		jump_btn.reset()
	if shoot_btn and shoot_btn.has_method("reset"):
		shoot_btn.reset()
	if _player_ref and _player_ref.has_method("reset_touch_inputs"):
		_player_ref.reset_touch_inputs()

func _on_pause_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		pause_btn.accept_event()
		_on_pause_pressed()

func _on_pause_pressed() -> void:
	if pause_overlay.visible or death_overlay.visible or victory_overlay.visible:
		return
	show_pause()

func show_pause() -> void:
	reset_touch_controls()
	AudioManager.play_sfx("click")
	_update_sfx_btn_text()
	confirm_modal.visible = false
	pause_overlay.visible = true
	get_tree().paused = true

func _on_pause_resume_pressed() -> void:
	AudioManager.play_sfx("click")
	confirm_modal.visible = false
	pause_overlay.visible = false
	reset_touch_controls()
	get_tree().paused = false

func _update_sfx_btn_text() -> void:
	if pause_sfx_btn:
		pause_sfx_btn.text = "SFX: ON" if SaveManager.sfx_enabled else "SFX: OFF"

func _on_sfx_toggle_pressed() -> void:
	SaveManager.toggle_sfx()
	_update_sfx_btn_text()
	AudioManager.play_sfx("click")

func _open_confirm(action: String) -> void:
	AudioManager.play_sfx("click")
	_pending_confirm_action = action
	match action:
		"restart":
			modal_title.text = "RESTART LEVEL?"
			modal_message.text = "Restart mission from the beginning? Current progress will be lost."
			modal_confirm_btn.text = "↺ RESTART"
		"mission_select":
			modal_title.text = "RETURN TO MENU?"
			modal_message.text = "Return to stage selection? Current mission progress will be lost."
			modal_confirm_btn.text = "CONFIRM"
		"arcade_menu":
			modal_title.text = "RETURN TO ARCADE?"
			modal_message.text = "Exit to Retro Rage Arcade main menu?"
			modal_confirm_btn.text = "CONFIRM"
	confirm_modal.visible = true

func _close_confirm() -> void:
	AudioManager.play_sfx("click")
	confirm_modal.visible = false
	_pending_confirm_action = ""

func _execute_confirm() -> void:
	AudioManager.play_sfx("click")
	var action := _pending_confirm_action
	confirm_modal.visible = false
	_pending_confirm_action = ""
	match action:
		"restart":
			_on_restart_pressed()
		"mission_select":
			_on_mission_pressed()
		"arcade_menu":
			_on_arcade_pressed()

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false
	reset_touch_controls()
	get_tree().paused = false
	restart_requested.emit()

func _on_mission_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false
	reset_touch_controls()
	get_tree().paused = false
	menu_requested.emit()

func _on_arcade_pressed() -> void:
	AudioManager.play_sfx("click")
	pause_overlay.visible = false
	death_overlay.visible = false
	victory_overlay.visible = false
	reset_touch_controls()
	get_tree().paused = false
	arcade_requested.emit()

func _on_player_died() -> void:
	reset_touch_controls()
	var death_timer := get_tree().create_timer(0.4)
	death_timer.timeout.connect(func():
		death_overlay.visible = true
		_update_death_ad_status()
		# Proactively load rewarded ad if eligible
		if GameManager and GameManager.can_revive_this_run():
			if AdManager and not AdManager.is_rewarded_ad_ready() and not AdManager.is_loading() and AdManager.is_plugin_initialized():
				AdManager.load_rewarded_ad()
	)

func _update_death_ad_status() -> void:
	if not death_overlay or not death_overlay.visible:
		return
	if not death_revive_btn or not death_ad_status:
		return

	# Authoritative run allowance check
	if GameManager and not GameManager.can_revive_this_run():
		death_revive_btn.disabled = true
		death_ad_status.text = "Revive already used this run"
		death_ad_status.modulate = Color(0.8, 0.8, 0.8, 0.7)
		return

	if not AdManager:
		death_revive_btn.disabled = true
		death_ad_status.text = "Ad service unavailable"
		death_ad_status.modulate = Color(0.8, 0.8, 0.8, 0.7)
		return

	if AdManager.is_rewarded_ad_ready():
		death_revive_btn.disabled = false
		death_ad_status.text = "Watch a short ad to revive here!"
		death_ad_status.modulate = Color(0.5, 1.0, 0.6, 0.9)
	elif AdManager.is_initializing():
		death_revive_btn.disabled = true
		death_ad_status.text = "Initializing ad service..."
		death_ad_status.modulate = Color(1.0, 0.85, 0.3, 0.9)
	elif AdManager.is_loading():
		death_revive_btn.disabled = true
		death_ad_status.text = "Loading ad..."
		death_ad_status.modulate = Color(1.0, 0.85, 0.3, 0.9)
	else:
		death_revive_btn.disabled = true
		death_ad_status.text = AdManager.get_status_text()
		death_ad_status.modulate = Color(0.8, 0.8, 0.8, 0.7)

func _on_revive_ad_pressed() -> void:
	if not GameManager or not GameManager.can_revive_this_run():
		_update_death_ad_status()
		return

	AudioManager.play_sfx("click")
	if death_revive_btn:
		death_revive_btn.disabled = true
	death_retry_btn.disabled = true
	if death_ad_status:
		death_ad_status.text = "Preparing ad..."
		death_ad_status.modulate = Color(1.0, 0.9, 0.4, 1.0)
	get_tree().paused = true

	var target_run_id: int = GameManager.current_run_id if GameManager else -1
	var started := AdManager.show_rewarded_ad_for_revive(
		func(): _on_revive_reward_granted(target_run_id),
		_on_revive_ad_failed
	)
	if not started:
		get_tree().paused = false
		death_retry_btn.disabled = false
		_update_death_ad_status()

func _on_revive_reward_granted(expected_run_id: int = -1) -> void:
	if expected_run_id != -1 and GameManager and GameManager.current_run_id != expected_run_id:
		get_tree().paused = false
		death_overlay.visible = false
		return

	if GameManager and not GameManager.can_revive_this_run():
		get_tree().paused = false
		_update_death_ad_status()
		return

	# Revive player authoritatively with 1 life and 10 bullets
	if GameManager:
		GameManager.revives_used_this_run += 1

	if _player_ref:
		_player_ref.revive()

	death_overlay.visible = false
	if death_revive_btn:
		death_revive_btn.disabled = false
	death_retry_btn.disabled = false
	reset_touch_controls()
	get_tree().paused = false
	revive_requested.emit()

func _on_revive_ad_failed(reason: String) -> void:
	get_tree().paused = false
	death_retry_btn.disabled = false
	if death_ad_status:
		death_ad_status.text = reason
		death_ad_status.modulate = Color(1.0, 0.4, 0.4, 1.0)
	_update_death_ad_status()

func show_victory(ammo_remaining: int) -> void:
	reset_touch_controls()
	if victory_stats_label:
		victory_stats_label.text = "BORDER INFILTRATION SUCCESSFUL\nAMMO REMAINING: %d ROUNDS" % ammo_remaining
	victory_overlay.visible = true
