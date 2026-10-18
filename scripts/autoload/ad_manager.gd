extends Node

## AdManager — Centralized, Reusable Rewarded Ad Service for Retro Rage Arcade
## Integrates with Google Mobile Ads (AdMob) via Android Engine singleton (e.g. GodotAdMob / PoingGodotAdMob).
## Features safe pre-loading, exponential backoff retries, single-transaction security,
## authoritative reward verification, duplicate/stale callback protection, and accurate error attribution.

signal initialization_completed(success: bool)
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error_type: int, error_code: Variant, error_message: String)
signal rewarded_ad_opened
signal rewarded_ad_closed
signal user_earned_reward(currency_type: String, amount: int)
signal revive_reward_verified(transaction_id: String)
signal revive_flow_failed(reason: String)
signal network_state_changed(is_available: bool)

enum AdState {
	UNINITIALIZED,
	INITIALIZING,
	NOT_LOADED,
	LOADING,
	READY,
	SHOWING,
	ERROR
}

enum AdErrorType {
	NONE,
	NO_FILL,
	NETWORK_ERROR,
	TIMEOUT,
	INVALID_REQUEST,
	INTERNAL_ERROR,
	PLUGIN_NOT_CONFIGURED,
	NOT_INITIALIZED,
	UNKNOWN
}

# Google Official Test AdMob IDs for Android (Production IDs configured via ad_config.json)
const DEFAULT_TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const DEFAULT_TEST_REWARDED_AD_UNIT_ID := "ca-app-pub-3940256099942544/5224354917"
const CONFIG_PATH := "res://ad_config.json"

const MAX_LOAD_RETRIES := 3
const RETRY_BACKOFF_DELAYS: Array[float] = [5.0, 15.0, 30.0]
const NO_FILL_COOLDOWN := 30.0

var is_test_mode: bool = true
var app_id: String = DEFAULT_TEST_APP_ID
var rewarded_ad_unit_id: String = DEFAULT_TEST_REWARDED_AD_UNIT_ID

var current_state: AdState = AdState.UNINITIALIZED
var last_error_type: AdErrorType = AdErrorType.NONE
var last_error_code: Variant = null
var last_error_message: String = ""
var is_network_available: bool = true

var _plugin_singleton: Object = null
var _plugin_name: String = ""
var _last_loaded_ad_id: String = ""

# Preloading retry & backoff tracking
var _load_retry_count: int = 0
var _retry_timer: float = 0.0
var _is_retrying: bool = false
var _cooldown_timer: float = 0.0

# Transaction safety variables
var _current_transaction_id: String = ""
var _transaction_in_progress: bool = false
var _transaction_consumed: bool = false
var _active_reward_callback: Callable = Callable()
var _active_failure_callback: Callable = Callable()
var _transaction_counter: int = 0

# Mock / Unit Testing support
var _mock_mode_enabled: bool = false
var _mock_ad_ready: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_configuration()
	_detect_plugin()
	initialize()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

	if _is_retrying:
		_retry_timer -= delta
		if _retry_timer <= 0.0:
			_is_retrying = false
			print("[AdManager] Retry timer expired. Attempting rewarded ad reload (attempt %d/%d)..." % [_load_retry_count, MAX_LOAD_RETRIES])
			load_rewarded_ad()

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
				print("[AdManager] Configuration loaded. TestMode: %s, RewardedUnit: %s" % [is_test_mode, rewarded_ad_unit_id])
				return
	# Fallback to test defaults
	is_test_mode = true
	app_id = DEFAULT_TEST_APP_ID
	rewarded_ad_unit_id = DEFAULT_TEST_REWARDED_AD_UNIT_ID

func _detect_plugin() -> void:
	if Engine.has_singleton("AdmobPlugin"):
		_plugin_singleton = Engine.get_singleton("AdmobPlugin")
		_plugin_name = "AdmobPlugin"
		print("[AdManager] Detected native Android singleton: AdmobPlugin")
	elif Engine.has_singleton("GodotAdMob"):
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
		print("[AdManager] No native AdMob plugin singleton detected on platform: %s (AdMob native library pending build configuration)" % OS.get_name())

func initialize() -> void:
	print("[AdManager] SDK Initializing... (plugin: %s, test_mode: %s)" % [_plugin_name if _plugin_name != "" else "none", is_test_mode])
	
	if _mock_mode_enabled:
		current_state = AdState.READY if _mock_ad_ready else AdState.NOT_LOADED
		last_error_type = AdErrorType.NONE
		initialization_completed.emit(true)
		print("[AdManager] SDK initialized in mock test mode.")
		return

	if _plugin_singleton == null:
		current_state = AdState.NOT_LOADED
		last_error_type = AdErrorType.PLUGIN_NOT_CONFIGURED
		last_error_message = "Native AdMob plugin is not configured in this export."
		initialization_completed.emit(false)
		print("[AdManager] SDK initialization incomplete: native plugin singleton not present.")
		return

	current_state = AdState.INITIALIZING
	_connect_plugin_signals()

	if _plugin_singleton.has_method("initialize"):
		_plugin_singleton.call("initialize")
		if _plugin_singleton.has_method("set_request_configuration"):
			var req_config := {"test_device_ids": []}
			_plugin_singleton.call("set_request_configuration", req_config)
		current_state = AdState.NOT_LOADED
		last_error_type = AdErrorType.NONE
		initialization_completed.emit(true)
		print("[AdManager] SDK initialized successfully with native provider: %s" % _plugin_name)
		# Proactively preload rewarded ad in background
		load_rewarded_ad()
	else:
		current_state = AdState.NOT_LOADED
		last_error_type = AdErrorType.NONE
		initialization_completed.emit(true)
		print("[AdManager] SDK initialized with native provider.")
		load_rewarded_ad()

func _connect_plugin_signals() -> void:
	if not _plugin_singleton:
		return

	# Loaded signals
	_safe_connect_signal("rewarded_video_loaded", _on_plugin_rewarded_ad_loaded)
	_safe_connect_signal("on_rewarded_video_ad_loaded", _on_plugin_rewarded_ad_loaded)
	_safe_connect_signal("rewarded_ad_loaded", _on_plugin_rewarded_ad_loaded)

	# Load failure signals
	_safe_connect_signal("rewarded_video_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)
	_safe_connect_signal("on_rewarded_video_ad_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)
	_safe_connect_signal("rewarded_ad_failed_to_load", _on_plugin_rewarded_ad_failed_to_load)

	# Ad opened / full screen content showed
	_safe_connect_signal("rewarded_video_opened", _on_plugin_rewarded_ad_opened)
	_safe_connect_signal("on_rewarded_video_ad_opened", _on_plugin_rewarded_ad_opened)
	_safe_connect_signal("rewarded_ad_opened", _on_plugin_rewarded_ad_opened)
	_safe_connect_signal("rewarded_ad_showed_full_screen_content", _on_plugin_rewarded_ad_opened)

	# Show failures
	_safe_connect_signal("rewarded_ad_failed_to_show_full_screen_content", _on_plugin_rewarded_ad_failed_to_show)

	# Ad closed / dismissed
	_safe_connect_signal("rewarded_video_closed", _on_plugin_rewarded_ad_closed)
	_safe_connect_signal("on_rewarded_video_ad_closed", _on_plugin_rewarded_ad_closed)
	_safe_connect_signal("rewarded_ad_closed", _on_plugin_rewarded_ad_closed)
	_safe_connect_signal("rewarded_ad_dismissed_full_screen_content", _on_plugin_rewarded_ad_closed)

	# User earned reward
	_safe_connect_signal("rewarded", _on_plugin_user_earned_reward)
	_safe_connect_signal("on_rewarded", _on_plugin_user_earned_reward)
	_safe_connect_signal("user_earned_reward", _on_plugin_user_earned_reward)
	_safe_connect_signal("rewarded_ad_user_earned_reward", _on_plugin_user_earned_reward)

func _safe_connect_signal(signal_name: String, target_callable: Callable) -> void:
	if _plugin_singleton and _plugin_singleton.has_signal(signal_name):
		if not _plugin_singleton.is_connected(signal_name, target_callable):
			_plugin_singleton.connect(signal_name, target_callable)

## Safely request and preload a rewarded ad before it is needed
func load_rewarded_ad() -> void:
	if _mock_mode_enabled:
		return

	if current_state == AdState.READY:
		print("[AdManager] Rewarded ad already cached and ready to show.")
		return

	if current_state == AdState.LOADING:
		print("[AdManager] Rewarded ad request already in progress.")
		return

	if _cooldown_timer > 0.0:
		print("[AdManager] Ad request cooldown active (%.1fs remaining). Avoiding server spam." % _cooldown_timer)
		return

	if not is_network_available:
		current_state = AdState.ERROR
		last_error_type = AdErrorType.NETWORK_ERROR
		last_error_message = "No network connection available."
		print("[AdManager] Cannot load ad: network connection unavailable.")
		return

	if _plugin_singleton == null:
		current_state = AdState.NOT_LOADED
		last_error_type = AdErrorType.PLUGIN_NOT_CONFIGURED
		last_error_message = "Native ad plugin not configured."
		return

	current_state = AdState.LOADING
	print("[AdManager] Ad request started (attempt %d, ad_unit: %s)..." % [_load_retry_count + 1, rewarded_ad_unit_id])

	if _plugin_name == "AdmobPlugin":
		_plugin_singleton.call("load_rewarded_ad", {"ad_unit_id": rewarded_ad_unit_id})
	elif _plugin_singleton.has_method("load_rewarded_video"):
		_plugin_singleton.call("load_rewarded_video", rewarded_ad_unit_id)
	elif _plugin_singleton.has_method("load_rewarded_ad"):
		_plugin_singleton.call("load_rewarded_ad", {"ad_unit_id": rewarded_ad_unit_id})

func is_rewarded_ad_ready() -> bool:
	if _mock_mode_enabled:
		return _mock_ad_ready
	return current_state == AdState.READY

func is_loading() -> bool:
	return current_state == AdState.LOADING

func show_rewarded_ad_for_revive(on_reward: Callable, on_failure: Callable) -> bool:
	if _transaction_in_progress:
		print("[AdManager] Revive requested while a transaction is already in progress.")
		if on_failure.is_valid():
			on_failure.call("Ad request already in progress. Please wait.")
		return false

	if not is_rewarded_ad_ready():
		print("[AdManager] Revive requested but rewarded ad is not ready. Current state: %s, Last error: %s" % [current_state, last_error_type])
		if on_failure.is_valid():
			on_failure.call(get_status_text())
		return false

	_transaction_counter += 1
	_current_transaction_id = "revive_%d_%d" % [Time.get_ticks_msec(), _transaction_counter]
	_transaction_in_progress = true
	_transaction_consumed = false
	_active_reward_callback = on_reward
	_active_failure_callback = on_failure
	current_state = AdState.SHOWING
	print("[AdManager] Starting revive ad presentation (transaction: %s)" % _current_transaction_id)

	if _mock_mode_enabled:
		rewarded_ad_opened.emit()
		return true

	if _plugin_singleton != null:
		if _plugin_name == "AdmobPlugin":
			_plugin_singleton.call("show_rewarded_ad", _last_loaded_ad_id)
		elif _plugin_singleton.has_method("show_rewarded_video"):
			_plugin_singleton.call("show_rewarded_video")
		elif _plugin_singleton.has_method("show_rewarded_ad"):
			_plugin_singleton.call("show_rewarded_ad", _last_loaded_ad_id)
		rewarded_ad_opened.emit()
		return true
	else:
		_handle_transaction_failure("Native ad provider unavailable on this platform.")
		return false

## Authoritative reward callback received from the SDK
func _on_plugin_user_earned_reward(arg1: Variant = "Revive", arg2: Variant = 1) -> void:
	var currency_type: String = "Revive"
	var amount: int = 1
	if arg2 is Dictionary:
		currency_type = str(arg2.get("type", "Revive"))
		amount = int(arg2.get("amount", 1))
	elif arg1 is Dictionary:
		currency_type = str(arg1.get("type", "Revive"))
		amount = int(arg1.get("amount", 1))
	else:
		if arg1 != null and typeof(arg1) == TYPE_STRING:
			currency_type = str(arg1)
		if arg2 != null and (typeof(arg2) == TYPE_INT or typeof(arg2) == TYPE_FLOAT):
			amount = int(arg2)

	if not _transaction_in_progress:
		print("[AdManager] Discarding unexpected reward callback (no active revive transaction).")
		return

	if _transaction_consumed:
		print("[AdManager] Duplicate reward callback received for transaction %s. Discarded safely." % _current_transaction_id)
		return

	_transaction_consumed = true
	print("[AdManager] Authoritative reward verified: %s x %d (transaction: %s)" % [currency_type, amount, _current_transaction_id])
	user_earned_reward.emit(currency_type, amount)
	revive_reward_verified.emit(_current_transaction_id)

	if _active_reward_callback.is_valid():
		var cb := _active_reward_callback
		_active_reward_callback = Callable()
		cb.call()

func _on_plugin_rewarded_ad_loaded(arg1: Variant = null, _arg2: Variant = null) -> void:
	if arg1 is Dictionary:
		_last_loaded_ad_id = str(arg1.get("ad_id", ""))
	current_state = AdState.READY
	last_error_type = AdErrorType.NONE
	last_error_code = null
	last_error_message = ""
	_load_retry_count = 0
	_is_retrying = false
	print("[AdManager] Rewarded ad loaded successfully and cached (ad_id: %s)." % _last_loaded_ad_id)
	rewarded_ad_loaded.emit()

func _on_plugin_rewarded_ad_failed_to_load(arg1: Variant = 0, arg2: Variant = null) -> void:
	current_state = AdState.ERROR
	var code_val: Variant = 0
	var msg_val: String = ""

	if arg2 is Dictionary:
		code_val = arg2.get("code", 0)
		msg_val = str(arg2.get("message", ""))
	elif arg1 is Dictionary:
		code_val = arg1.get("code", 0)
		msg_val = str(arg1.get("message", ""))
	else:
		code_val = arg1
		msg_val = str(arg1)

	last_error_code = code_val
	var code_int: int = int(code_val) if (typeof(code_val) == TYPE_INT or typeof(code_val) == TYPE_FLOAT) else -1
	var code_str := (str(code_val) + " " + msg_val).to_lower()

	# Categorize Google AdMob error codes cleanly:
	# 0: ERROR_CODE_INTERNAL_ERROR
	# 1: ERROR_CODE_INVALID_REQUEST
	# 2: ERROR_CODE_NETWORK_ERROR
	# 3: ERROR_CODE_NO_FILL
	if code_int == 3 or "no_fill" in code_str or "no fill" in code_str:
		last_error_type = AdErrorType.NO_FILL
		last_error_message = "No ad inventory currently available from ad network."
		_cooldown_timer = NO_FILL_COOLDOWN
	elif code_int == 2 or "network" in code_str or "connection" in code_str or "offline" in code_str:
		last_error_type = AdErrorType.NETWORK_ERROR
		last_error_message = "Network error during ad request."
	elif code_int == 4 or "timeout" in code_str:
		last_error_type = AdErrorType.TIMEOUT
		last_error_message = "Ad request timed out."
	elif code_int == 1 or "invalid" in code_str:
		last_error_type = AdErrorType.INVALID_REQUEST
		last_error_message = "Invalid ad request configuration."
	elif code_int == 0 or "internal" in code_str:
		last_error_type = AdErrorType.INTERNAL_ERROR
		last_error_message = "Internal ad server error."
	else:
		last_error_type = AdErrorType.UNKNOWN
		last_error_message = "Ad load failed (code: %s)" % str(code_val)

	print("[AdManager] Ad load failed (error_type: %s, code: %s, message: %s)" % [last_error_type, str(code_val), last_error_message])
	rewarded_ad_failed_to_load.emit(last_error_type, code_val, last_error_message)

	# Bounded exponential backoff retry for transient network/timeout errors
	if (last_error_type == AdErrorType.NETWORK_ERROR or last_error_type == AdErrorType.TIMEOUT) and _load_retry_count < MAX_LOAD_RETRIES:
		var delay: float = RETRY_BACKOFF_DELAYS[clampi(_load_retry_count, 0, RETRY_BACKOFF_DELAYS.size() - 1)]
		_load_retry_count += 1
		_is_retrying = true
		_retry_timer = delay
		print("[AdManager] Scheduling ad reload retry in %.1fs (attempt %d/%d)..." % [delay, _load_retry_count, MAX_LOAD_RETRIES])

func _on_plugin_rewarded_ad_opened(_arg1: Variant = null) -> void:
	print("[AdManager] Rewarded ad opened fullscreen (transaction: %s)" % _current_transaction_id)
	rewarded_ad_opened.emit()

func _on_plugin_rewarded_ad_failed_to_show(arg1: Variant = null, arg2: Variant = null) -> void:
	var reason := "Failed to display ad."
	if arg2 is Dictionary:
		reason = str(arg2.get("message", reason))
	elif arg1 is Dictionary:
		reason = str(arg1.get("message", reason))
	print("[AdManager] Rewarded ad failed to show: %s" % reason)
	_handle_transaction_failure(reason)
	_finish_transaction()
	load_rewarded_ad()

func _on_plugin_rewarded_ad_closed(_arg1: Variant = null) -> void:
	print("[AdManager] Rewarded ad dismissed/closed (transaction: %s)" % _current_transaction_id)
	rewarded_ad_closed.emit()

	if _transaction_in_progress and not _transaction_consumed:
		_handle_transaction_failure("Ad was closed before completing the reward requirement.")

	_finish_transaction()
	# Proactively preload next ad for subsequent deaths
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

## Cancel transaction when player restarts or navigates away
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

## Clear, non-misleading user-facing message corresponding to the exact current state
func get_status_text() -> String:
	if is_rewarded_ad_ready():
		return "Watch a short ad to revive here!"
	elif is_loading():
		return "Loading ad..."
	elif current_state == AdState.SHOWING:
		return "Preparing ad..."
	elif last_error_type == AdErrorType.NO_FILL:
		return "No ads available right now"
	elif last_error_type == AdErrorType.NETWORK_ERROR:
		return "Network connection needed"
	elif last_error_type == AdErrorType.TIMEOUT:
		return "Ad request timed out"
	elif last_error_type == AdErrorType.PLUGIN_NOT_CONFIGURED:
		return "Ad service not configured"
	elif not is_network_available:
		return "Network connection needed"
	else:
		return "Ad temporarily unavailable"

# ==============================================================================
# MOCK / UNIT TEST HARNESS METHODS (For Part E Automated Acceptance Testing)
# ==============================================================================

func enable_mock_mode(initial_ready: bool = true) -> void:
	_mock_mode_enabled = true
	_mock_ad_ready = initial_ready
	_is_retrying = false
	_load_retry_count = 0
	last_error_type = AdErrorType.NONE
	current_state = AdState.READY if initial_ready else AdState.NOT_LOADED
	print("[AdManager] Mock mode enabled (initial_ready: %s)" % initial_ready)

func disable_mock_mode() -> void:
	_mock_mode_enabled = false
	_mock_ad_ready = false
	_is_retrying = false
	_load_retry_count = 0
	_detect_plugin()
	initialize()

func set_mock_plugin(mock: Object, plugin_name: String = "AdmobPlugin") -> void:
	_plugin_singleton = mock
	_plugin_name = plugin_name
	_mock_mode_enabled = false
	if _plugin_singleton != null:
		_connect_plugin_signals()

func restore_plugin_detection() -> void:
	_mock_mode_enabled = false
	_detect_plugin()

func get_plugin_singleton() -> Object:
	return _plugin_singleton

func get_plugin_name() -> String:
	return _plugin_name

func get_last_loaded_ad_id() -> String:
	return _last_loaded_ad_id

func reset_cooldown() -> void:
	_cooldown_timer = 0.0
	_retry_timer = 0.0
	_is_retrying = false
	_load_retry_count = 0

func set_mock_ad_available(available: bool) -> void:
	_mock_ad_ready = available
	current_state = AdState.READY if available else AdState.NOT_LOADED
	if available:
		last_error_type = AdErrorType.NONE
		rewarded_ad_loaded.emit()

func simulate_mock_load_failure(error_type: AdErrorType = AdErrorType.NO_FILL, err_code: Variant = 3, message: String = "No fill") -> void:
	_mock_ad_ready = false
	current_state = AdState.ERROR
	last_error_type = error_type
	last_error_code = err_code
	last_error_message = message
	print("[AdManager] Mock load failure simulated: %s (%s)" % [error_type, message])
	rewarded_ad_failed_to_load.emit(error_type, err_code, message)

func simulate_mock_reward(currency_type: String = "Revive", amount: int = 1) -> void:
	_on_plugin_user_earned_reward(currency_type, amount)
	_on_plugin_rewarded_ad_closed()

func simulate_mock_dismiss_without_reward() -> void:
	_on_plugin_rewarded_ad_closed()

func simulate_mock_duplicate_reward_callback() -> void:
	_on_plugin_user_earned_reward("Revive", 1)

func simulate_network_loss() -> void:
	is_network_available = false
	_mock_ad_ready = false
	current_state = AdState.ERROR
	last_error_type = AdErrorType.NETWORK_ERROR
	last_error_message = "Network connection lost."
	print("[AdManager] Network loss simulated.")
	network_state_changed.emit(false)

func simulate_network_recovery() -> void:
	is_network_available = true
	print("[AdManager] Network recovery: attempting ad pre-load...")
	network_state_changed.emit(true)
	if _mock_mode_enabled:
		set_mock_ad_available(true)
	else:
		load_rewarded_ad()
