extends Node

## AdManager — Centralized, Reusable Rewarded Ad Service for Retro Rage Arcade
## Integrates with Google AdMob via Android Engine singleton (e.g. GodotAdMob / PoingGodotAdMob).
## Provides clean offline fallbacks, single-transaction security, duplicate callback protection,
## and stale-callback prevention across all 20 levels.

signal initialization_completed(success: bool)
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error_message: String)
signal rewarded_ad_opened
signal rewarded_ad_closed
signal user_earned_reward(currency_type: String, amount: int)
signal revive_reward_verified(transaction_id: String)
signal revive_flow_failed(reason: String)

enum AdState {
	UNINITIALIZED,
	INITIALIZING,
	NOT_LOADED,
	LOADING,
	READY,
	SHOWING,
	ERROR
}

# Google Official Test AdMob IDs for Android (Production IDs are loaded from ad_config.json if provided)
const DEFAULT_TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const DEFAULT_TEST_REWARDED_AD_UNIT_ID := "ca-app-pub-3940256099942544/5224354917"
const CONFIG_PATH := "res://ad_config.json"

var is_test_mode: bool = true
var app_id: String = DEFAULT_TEST_APP_ID
var rewarded_ad_unit_id: String = DEFAULT_TEST_REWARDED_AD_UNIT_ID

var current_state: AdState = AdState.UNINITIALIZED
var _plugin_singleton: Object = null
var _plugin_name: String = ""

# Transaction safety variables
var _current_transaction_id: String = ""
var _transaction_in_progress: bool = false
var _transaction_consumed: bool = false
var _active_reward_callback: Callable = Callable()
var _active_failure_callback: Callable = Callable()
var _transaction_counter: int = 0

# Mock / Unit Testing support (for automated test suite)
var _mock_mode_enabled: bool = false
var _mock_ad_ready: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_configuration()
	_detect_plugin()
	initialize()

func _load_configuration() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file:
			var json_str := file.get_as_text()
			var json := JSON.new()
			var err := json.parse(json_str)
			if err == OK and json.data is Dictionary:
				var data: Dictionary = json.data
				is_test_mode = bool(data.get("test_mode", true))
				if is_test_mode:
					app_id = str(data.get("app_id_test", DEFAULT_TEST_APP_ID))
					rewarded_ad_unit_id = str(data.get("rewarded_ad_unit_id_test", DEFAULT_TEST_REWARDED_AD_UNIT_ID))
				else:
					app_id = str(data.get("app_id_production", ""))
					rewarded_ad_unit_id = str(data.get("rewarded_ad_unit_id_production", ""))
				print("[AdManager] Configuration loaded. TestMode: %s" % is_test_mode)
				return
	# Fallback to test defaults
	is_test_mode = true
	app_id = DEFAULT_TEST_APP_ID
	rewarded_ad_unit_id = DEFAULT_TEST_REWARDED_AD_UNIT_ID

func _detect_plugin() -> void:
	if Engine.has_singleton("GodotAdMob"):
		_plugin_singleton = Engine.get_singleton("GodotAdMob")
		_plugin_name = "GodotAdMob"
		print("[AdManager] Detected native Android singleton: GodotAdMob")
	elif Engine.has_singleton("PoingGodotAdMob"):
		_plugin_singleton = Engine.get_singleton("PoingGodotAdMob")
		_plugin_name = "PoingGodotAdMob"
		print("[AdManager] Detected native Android singleton: PoingGodotAdMob")
	else:
		_plugin_singleton = null
		_plugin_name = ""
		print("[AdManager] No native AdMob plugin singleton detected on platform: %s" % OS.get_name())

func initialize() -> void:
	if _mock_mode_enabled:
		current_state = AdState.READY if _mock_ad_ready else AdState.NOT_LOADED
		initialization_completed.emit(true)
		return

	if _plugin_singleton == null:
		current_state = AdState.NOT_LOADED
		initialization_completed.emit(false)
		return

	current_state = AdState.INITIALIZING
	_connect_plugin_signals()
	
	if _plugin_singleton.has_method("initialize"):
		# Most GodotAdMob plugins accept initialization call or config
		_plugin_singleton.call("initialize")
		current_state = AdState.NOT_LOADED
		initialization_completed.emit(true)
		# Automatically attempt initial ad load in background
		load_rewarded_ad()
	else:
		current_state = AdState.NOT_LOADED
		initialization_completed.emit(true)
		load_rewarded_ad()

func _connect_plugin_signals() -> void:
	if not _plugin_singleton:
		return
		
	# Connect to GodotAdMob / PoingGodotAdMob rewarded video signals safely
	_safe_connect_signal("rewarded_video_loaded", _on_plugin_rewarded_ad_loaded)
	_safe_connect_signal("on_rewarded_video_ad_loaded", _on_plugin_rewarded_ad_loaded)
	_safe_connect_signal("rewarded_ad_loaded", _on_plugin_rewarded_ad_loaded)
	
	_safe_connect_signal("rewarded_video_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)
	_safe_connect_signal("on_rewarded_video_ad_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)
	_safe_connect_signal("rewarded_ad_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)
	
	_safe_connect_signal("rewarded_video_opened", _on_plugin_rewarded_ad_opened)
	_safe_connect_signal("on_rewarded_video_ad_opened", _on_plugin_rewarded_ad_opened)
	_safe_connect_signal("rewarded_ad_opened", _on_plugin_rewarded_ad_opened)
	
	_safe_connect_signal("rewarded_video_closed", _on_plugin_rewarded_ad_closed)
	_safe_connect_signal("on_rewarded_video_ad_closed", _on_plugin_rewarded_ad_closed)
	_safe_connect_signal("rewarded_ad_closed", _on_plugin_rewarded_ad_closed)
	
	_safe_connect_signal("rewarded", _on_plugin_user_earned_reward)
	_safe_connect_signal("on_rewarded", _on_plugin_user_earned_reward)
	_safe_connect_signal("user_earned_reward", _on_plugin_user_earned_reward)

func _safe_connect_signal(signal_name: String, target_callable: Callable) -> void:
	if _plugin_singleton and _plugin_singleton.has_signal(signal_name):
		if not _plugin_singleton.is_connected(signal_name, target_callable):
			_plugin_singleton.connect(signal_name, target_callable)

func load_rewarded_ad() -> void:
	if _mock_mode_enabled:
		return

	if current_state == AdState.READY or current_state == AdState.LOADING:
		return

	if _plugin_singleton == null:
		# Offline or desktop development without native plugin
		current_state = AdState.NOT_LOADED
		return

	current_state = AdState.LOADING
	print("[AdManager] Requesting rewarded ad load...")
	
	if _plugin_singleton.has_method("load_rewarded_video"):
		_plugin_singleton.call("load_rewarded_video", rewarded_ad_unit_id)
	elif _plugin_singleton.has_method("load_rewarded_ad"):
		_plugin_singleton.call("load_rewarded_ad", rewarded_ad_unit_id)

func is_rewarded_ad_ready() -> bool:
	if _mock_mode_enabled:
		return _mock_ad_ready
	return current_state == AdState.READY

func is_loading() -> bool:
	return current_state == AdState.LOADING

func show_rewarded_ad_for_revive(on_reward: Callable, on_failure: Callable) -> bool:
	# Rate-limiting & re-entrancy prevention: only one active ad presentation at a time
	if _transaction_in_progress:
		print("[AdManager] Revive requested while a transaction is already active.")
		if on_failure.is_valid():
			on_failure.call("Ad request already in progress. Please wait.")
		return false

	if not is_rewarded_ad_ready():
		print("[AdManager] Revive requested but rewarded ad is not ready.")
		if on_failure.is_valid():
			on_failure.call("Rewarded ad is not available right now. Please restart the level.")
		return false

	_transaction_counter += 1
	_current_transaction_id = "revive_%d_%d" % [Time.get_ticks_msec(), _transaction_counter]
	_transaction_in_progress = true
	_transaction_consumed = false
	_active_reward_callback = on_reward
	_active_failure_callback = on_failure
	current_state = AdState.SHOWING
	print("[AdManager] Starting revive ad presentation. Transaction ID: %s" % _current_transaction_id)

	if _mock_mode_enabled:
		# In unit test / mock mode, execution is controlled deterministically by test runner
		rewarded_ad_opened.emit()
		return true

	if _plugin_singleton != null:
		if _plugin_singleton.has_method("show_rewarded_video"):
			_plugin_singleton.call("show_rewarded_video")
		elif _plugin_singleton.has_method("show_rewarded_ad"):
			_plugin_singleton.call("show_rewarded_ad")
		rewarded_ad_opened.emit()
		return true
	else:
		_handle_transaction_failure("Native ad provider unavailable on this platform.")
		return false

## Authoritative callback when player has successfully watched the rewarded ad
func _on_plugin_user_earned_reward(currency_type: String = "Revive", amount: int = 1) -> void:
	if not _transaction_in_progress:
		print("[AdManager] Discarding unexpected reward callback (no active revive transaction).")
		return

	if _transaction_consumed:
		print("[AdManager] Duplicate reward callback received for transaction %s. Discarded." % _current_transaction_id)
		return

	_transaction_consumed = true
	print("[AdManager] Authoritative reward confirmed for transaction %s: %s x %d" % [_current_transaction_id, currency_type, amount])
	user_earned_reward.emit(currency_type, amount)
	revive_reward_verified.emit(_current_transaction_id)

	if _active_reward_callback.is_valid():
		var cb := _active_reward_callback
		_active_reward_callback = Callable()
		cb.call()

func _on_plugin_rewarded_ad_loaded() -> void:
	current_state = AdState.READY
	print("[AdManager] Rewarded ad successfully loaded and ready.")
	rewarded_ad_loaded.emit()

func _on_plugin_rewarded_ad_failed_to_load(error_code: Variant = 0) -> void:
	current_state = AdState.ERROR
	var err_str := "Ad load failed (code: %s)" % str(error_code)
	print("[AdManager] %s" % err_str)
	rewarded_ad_failed_to_load.emit(err_str)

func _on_plugin_rewarded_ad_opened() -> void:
	print("[AdManager] Rewarded ad opened fullscreen.")
	rewarded_ad_opened.emit()

func _on_plugin_rewarded_ad_closed() -> void:
	print("[AdManager] Rewarded ad closed.")
	rewarded_ad_closed.emit()

	if _transaction_in_progress and not _transaction_consumed:
		# Player closed or skipped before earning reward
		_handle_transaction_failure("Ad was closed before completing the reward requirement.")

	_finish_transaction()
	# Pre-load next ad for future death events
	load_rewarded_ad()

func _handle_transaction_failure(reason: String) -> void:
	if not _transaction_in_progress:
		return
	print("[AdManager] Revive transaction failed: %s" % reason)
	revive_flow_failed.emit(reason)
	if _active_failure_callback.is_valid():
		var cb := _active_failure_callback
		_active_failure_callback = Callable()
		cb.call(reason)

func _finish_transaction() -> void:
	_transaction_in_progress = false
	_active_reward_callback = Callable()
	_active_failure_callback = Callable()
	if current_state == AdState.SHOWING:
		current_state = AdState.NOT_LOADED

## Invalidate any pending or delayed transaction if player restarts, exits, or changes levels
func cancel_current_transaction() -> void:
	if _transaction_in_progress:
		print("[AdManager] Cancelling active revive transaction: %s" % _current_transaction_id)
		_transaction_in_progress = false
		_transaction_consumed = true
		_current_transaction_id = ""
		_active_reward_callback = Callable()
		_active_failure_callback = Callable()
		if current_state == AdState.SHOWING:
			current_state = AdState.NOT_LOADED

func get_status_text() -> String:
	if is_rewarded_ad_ready():
		return "Ready to watch"
	elif is_loading():
		return "Loading ad..."
	elif current_state == AdState.SHOWING:
		return "Ad in progress..."
	elif _plugin_singleton == null and not _mock_mode_enabled:
		return "Ad unavailable offline"
	else:
		return "Ad not ready"

# ==============================================================================
# MOCK / UNIT TEST HARNESS METHODS (For automated CI and acceptance testing)
# ==============================================================================

func enable_mock_mode(initial_ready: bool = true) -> void:
	_mock_mode_enabled = true
	_mock_ad_ready = initial_ready
	current_state = AdState.READY if initial_ready else AdState.NOT_LOADED

func disable_mock_mode() -> void:
	_mock_mode_enabled = false
	_mock_ad_ready = false
	_detect_plugin()
	initialize()

func set_mock_ad_available(available: bool) -> void:
	_mock_ad_ready = available
	current_state = AdState.READY if available else AdState.NOT_LOADED
	if available:
		rewarded_ad_loaded.emit()

func simulate_mock_reward(currency_type: String = "Revive", amount: int = 1) -> void:
	_on_plugin_user_earned_reward(currency_type, amount)
	_on_plugin_rewarded_ad_closed()

func simulate_mock_dismiss_without_reward() -> void:
	_on_plugin_rewarded_ad_closed()

func simulate_mock_duplicate_reward_callback() -> void:
	_on_plugin_user_earned_reward("Revive", 1)

func simulate_mock_load_failure(err: String = "Network error") -> void:
	_mock_ad_ready = false
	_on_plugin_rewarded_ad_failed_to_load(err)
