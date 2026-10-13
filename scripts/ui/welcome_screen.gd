extends Control

## WelcomeScreen provides a polished retro startup and loading experience
## for Retro Rage Arcade and Coin Hell.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const MIN_DISPLAY_TIME: float = 0.9
const MAX_FAILSAFE_TIME: float = 2.5

@onready var brand_label: Label = $CenterContainer/VBox/BrandLabel
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var welcome_label: Label = $CenterContainer/VBox/WelcomeLabel
@onready var coin_icon: TextureRect = $CenterContainer/VBox/IconContainer/CoinIcon
@onready var progress_bar: ProgressBar = $CenterContainer/VBox/LoadingBox/ProgressBar
@onready var status_label: Label = $CenterContainer/VBox/LoadingBox/StatusLabel
@onready var percent_label: Label = $CenterContainer/VBox/LoadingBox/PercentLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

var _elapsed_time: float = 0.0
var _target_progress: float = 0.0
var _current_progress: float = 0.0
var _resource_loaded: bool = false
var _transition_started: bool = false
var _load_status_progress: Array = []

func _ready() -> void:
	# Keep welcome screen active across input
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	fade_overlay.modulate.a = 1.0
	fade_overlay.visible = true
	
	# Initial UI state
	progress_bar.value = 0.0
	percent_label.text = "0%"
	status_label.text = "INITIALIZING RETRO SYSTEMS..."
	
	# Initial safe verify of save without data loss
	SaveManager.load_save()
	
	# Start threaded preload of main menu scene
	var err := ResourceLoader.load_threaded_request(MAIN_MENU_SCENE)
	if err != OK:
		push_warning("Threaded load request failed with err %d, will use standard load fallback." % err)
		_resource_loaded = true
	
	# Animate fade in
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.35)
	
	# Subtle coin pulse animation
	_start_icon_pulse()

func _start_icon_pulse() -> void:
	if not coin_icon:
		return
	var icon_tween := create_tween().set_loops()
	icon_tween.tween_property(coin_icon, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(coin_icon, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if _transition_started:
		return
		
	_elapsed_time += delta
	
	# Poll ResourceLoader progress if still loading
	if not _resource_loaded:
		var status := ResourceLoader.load_threaded_get_status(MAIN_MENU_SCENE, _load_status_progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_resource_loaded = true
			_target_progress = 1.0
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and _load_status_progress.size() > 0:
			_target_progress = maxf(_target_progress, float(_load_status_progress[0]))
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Fallback if threaded loader fails
			_resource_loaded = true
			_target_progress = 1.0

	# Smooth fake/real blend progress towards 1.0 over MIN_DISPLAY_TIME
	var time_ratio := clampf(_elapsed_time / MIN_DISPLAY_TIME, 0.0, 1.0)
	var desired_progress := maxf(time_ratio, _target_progress)
	_current_progress = move_toward(_current_progress, desired_progress, delta * 1.8)
	
	# Update UI elements
	var pct_int := int(_current_progress * 100.0)
	progress_bar.value = _current_progress * 100.0
	percent_label.text = "%d%%" % pct_int
	
	if pct_int < 30:
		status_label.text = "INITIALIZING RETRO SYSTEMS..."
	elif pct_int < 70:
		status_label.text = "CHECKING SAVE PROGRESSION..."
	elif pct_int < 95:
		status_label.text = "PREPARING ARCADE CABINET..."
	else:
		status_label.text = "READY!"
	
	# Transition trigger: minimum display time elapsed AND resource loaded (or failsafe timeout reached)
	if (_elapsed_time >= MIN_DISPLAY_TIME and _resource_loaded and _current_progress >= 0.99) or (_elapsed_time >= MAX_FAILSAFE_TIME):
		_start_transition()

func _gui_input(event: InputEvent) -> void:
	# Allow player to skip if already partially loaded
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		if _elapsed_time >= 0.4 and not _transition_started:
			_start_transition()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		if _elapsed_time >= 0.4 and not _transition_started:
			_start_transition()

func _start_transition() -> void:
	if _transition_started:
		return
	_transition_started = true
	
	progress_bar.value = 100.0
	percent_label.text = "100%"
	status_label.text = "READY!"
	
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.28)
	tween.tween_callback(_on_fade_complete)

func _on_fade_complete() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
