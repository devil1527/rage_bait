extends Node

## SaveManager handles persistence for Retro Rage Arcade using local user:// storage.
## Gracefully recovers from missing or corrupted save files.

const SAVE_PATH: String = "user://retro_rage_save.json"
const WEB_IDBFS_KEY: String = "/userfs/godot/app_userdata/Retro Rage Arcade/retro_rage_save.json"
const WEB_PENDING_STORAGE_KEY: String = "retro_rage_arcade_pending_save"
const CURRENT_SCHEMA_VERSION: int = 2

enum PersistState {
	IDLE,
	PENDING,
	SYNCED,
	UNAVAILABLE,
	FAILED,
}

var schema_version: int = CURRENT_SCHEMA_VERSION
var highest_unlocked_level: int = 1
var completed_levels: Array = []
var stage_stars: Dictionary = {}
var sfx_enabled: bool = true
var music_enabled: bool = true
var level_15_secret_revealed: bool = false
var level_16_secret_revealed: bool = false

# Bullet Betrayal progression tracking (isolated from Coin Hell)
var bb_highest_unlocked_level: int = 1
var bb_completed_levels: Array = []
var bb_stage_stars: Dictionary = {}

# Persistence status tracking (asynchronous confirmation on Web; immediate on native)
var last_persist_state: PersistState = PersistState.IDLE
var last_persist_error: String = ""
var last_save_confirmed_persistent: bool = false

var _web_sync_in_flight: bool = false
var _web_sync_resync_needed: bool = false
var _web_sync_debounce_queued: bool = false
var _web_save_generation: int = 0
var _web_pending_generation: int = 0
var _web_confirmed_generation: int = 0
var _web_last_written_json: String = ""
var _web_sync_callback: Variant = null

signal progress_updated
signal save_persistence_completed(persisted: bool, detail: String)

func _ready() -> void:
	load_save()

func _exit_tree() -> void:
	if _web_sync_callback != null and OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var win: Variant = JavaScriptBridge.get_interface("window")
		if win:
			win._retroRageSaveCb = null
			win._retroRageSaveExpected = ""
			win._retroRageSaveIdbKey = ""
	_web_sync_callback = null

func get_default_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"highest_unlocked_level": 1,
		"completed_levels": [],
		"stage_stars": {},
		"sfx_enabled": true,
		"music_enabled": true,
		"level_15_secret_revealed": false,
		"bb_highest_unlocked_level": 1,
		"bb_completed_levels": [],
		"bb_stage_stars": {}
	}

func load_save() -> void:
	if OS.has_feature("web") and OS.is_userfs_persistent():
		var pending_data: Variant = _try_read_pending_web_save()
		if typeof(pending_data) == TYPE_DICTIONARY:
			_apply_dict(pending_data)
			save_data()
			return

	if not FileAccess.file_exists(SAVE_PATH):
		_apply_defaults()
		save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("Failed to open save file. Using defaults.")
		_apply_defaults()
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		push_warning("Save file corrupted. Using safe defaults.")
		_apply_defaults()
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save format unexpected. Using safe defaults.")
		_apply_defaults()
		return

	_apply_dict(data)

func _apply_defaults() -> void:
	schema_version = CURRENT_SCHEMA_VERSION
	highest_unlocked_level = 1
	completed_levels = []
	stage_stars = {}
	sfx_enabled = true
	music_enabled = true
	level_15_secret_revealed = false
	level_16_secret_revealed = false
	bb_highest_unlocked_level = 1
	bb_completed_levels = []
	bb_stage_stars = {}
	progress_updated.emit()

func _apply_dict(data: Dictionary) -> void:
	schema_version = int(data.get("schema_version", CURRENT_SCHEMA_VERSION))
	highest_unlocked_level = clampi(int(data.get("highest_unlocked_level", 1)), 1, 20)
	
	var raw_completed = data.get("completed_levels", [])
	completed_levels = []
	if typeof(raw_completed) == TYPE_ARRAY:
		for item in raw_completed:
			var lvl := int(item)
			if lvl >= 1 and lvl <= 20 and not completed_levels.has(lvl):
				completed_levels.append(lvl)

	var raw_stars = data.get("stage_stars", {})
	stage_stars = {}
	if typeof(raw_stars) == TYPE_DICTIONARY:
		for k in raw_stars.keys():
			var lvl_id := int(k)
			var stars_val := clampi(int(raw_stars[k]), 0, 3)
			if lvl_id >= 1 and lvl_id <= 20:
				stage_stars[str(lvl_id)] = stars_val

	bb_highest_unlocked_level = clampi(int(data.get("bb_highest_unlocked_level", 1)), 1, 20)
	
	var raw_bb_completed = data.get("bb_completed_levels", [])
	bb_completed_levels = []
	if typeof(raw_bb_completed) == TYPE_ARRAY:
		for item in raw_bb_completed:
			var lvl := int(item)
			if lvl >= 1 and lvl <= 20 and not bb_completed_levels.has(lvl):
				bb_completed_levels.append(lvl)

	var raw_bb_stars = data.get("bb_stage_stars", {})
	bb_stage_stars = {}
	if typeof(raw_bb_stars) == TYPE_DICTIONARY:
		for k in raw_bb_stars.keys():
			var lvl_id := int(k)
			var stars_val := clampi(int(raw_bb_stars[k]), 0, 3)
			if lvl_id >= 1 and lvl_id <= 20:
				bb_stage_stars[str(lvl_id)] = stars_val

	sfx_enabled = bool(data.get("sfx_enabled", true))
	music_enabled = bool(data.get("music_enabled", true))
	level_15_secret_revealed = bool(data.get("level_15_secret_revealed", false))
	level_16_secret_revealed = false
	progress_updated.emit()

func save_data() -> bool:
	var data := {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels,
		"stage_stars": stage_stars,
		"sfx_enabled": sfx_enabled,
		"music_enabled": music_enabled,
		"level_15_secret_revealed": level_15_secret_revealed,
		"bb_highest_unlocked_level": bb_highest_unlocked_level,
		"bb_completed_levels": bb_completed_levels,
		"bb_stage_stars": bb_stage_stars
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.FAILED
		last_persist_error = "Failed to open save file for writing."
		push_error("Failed to write save file at: " + SAVE_PATH)
		save_persistence_completed.emit(false, last_persist_error)
		return false

	var json_string := JSON.stringify(data, "  ")
	file.store_string(json_string)
	file.close()
	progress_updated.emit()

	if OS.has_feature("web"):
		_queue_web_persistence_sync(json_string)
	else:
		last_persist_state = PersistState.SYNCED
		last_persist_error = ""
		last_save_confirmed_persistent = true
		save_persistence_completed.emit(true, "")
	return true

func is_browser_persistence_confirmed() -> bool:
	return last_save_confirmed_persistent

func _queue_web_persistence_sync(json_string: String) -> void:
	if last_save_confirmed_persistent and json_string == _web_last_written_json and not _web_sync_in_flight:
		return

	_web_last_written_json = json_string
	_web_save_generation += 1
	last_save_confirmed_persistent = false
	last_persist_error = ""

	if not OS.is_userfs_persistent():
		last_persist_state = PersistState.UNAVAILABLE
		last_persist_error = "Browser persistent storage unavailable (Private Browsing or storage blocked)."
		push_warning("[SaveManager] %s" % last_persist_error)
		save_persistence_completed.emit(false, last_persist_error)
		return

	_write_pending_web_save(json_string)
	last_persist_state = PersistState.PENDING
	if not _web_sync_debounce_queued:
		_web_sync_debounce_queued = true
		call_deferred("_start_web_persistence_sync")

func _try_read_pending_web_save() -> Variant:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return null
	var win: Variant = JavaScriptBridge.get_interface("window")
	if win == null:
		return null
	win._retroRagePendingKey = WEB_PENDING_STORAGE_KEY
	var raw: Variant = JavaScriptBridge.eval(
		"(function(){try{return window.localStorage?window.localStorage.getItem(window._retroRagePendingKey)||'':'';}catch(_e){return '';}}())",
		true
	)
	if typeof(raw) != TYPE_STRING or String(raw).is_empty():
		return null
	var json := JSON.new()
	if json.parse(String(raw)) != OK:
		return null
	var parsed: Variant = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return parsed

func _write_pending_web_save(json_string: String) -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	var win: Variant = JavaScriptBridge.get_interface("window")
	if win == null:
		return
	win._retroRagePendingKey = WEB_PENDING_STORAGE_KEY
	win._retroRagePendingVal = json_string
	JavaScriptBridge.eval(
		"(function(){try{if(window.localStorage){window.localStorage.setItem(window._retroRagePendingKey,window._retroRagePendingVal);}}catch(_e){}}())",
		true
	)

func _start_web_persistence_sync() -> void:
	_web_sync_debounce_queued = false
	if not OS.has_feature("web"):
		return
	if not OS.is_userfs_persistent():
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.UNAVAILABLE
		last_persist_error = "Browser persistent storage unavailable (Private Browsing or storage blocked)."
		save_persistence_completed.emit(false, last_persist_error)
		return
	if _web_sync_in_flight:
		_web_sync_resync_needed = true
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.FAILED
		last_persist_error = "JavaScriptBridge unavailable for Web storage confirmation."
		save_persistence_completed.emit(false, last_persist_error)
		return

	var win: Variant = JavaScriptBridge.get_interface("window")
	if win == null:
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.FAILED
		last_persist_error = "Browser window interface unavailable."
		save_persistence_completed.emit(false, last_persist_error)
		return

	if _web_sync_callback == null:
		_web_sync_callback = JavaScriptBridge.create_callback(_on_web_sync_js_result)

	_web_sync_in_flight = true
	_web_sync_resync_needed = false
	_web_pending_generation = _web_save_generation

	win._retroRageSaveCb = _web_sync_callback
	win._retroRageSaveExpected = _web_last_written_json
	win._retroRageSaveIdbKey = WEB_IDBFS_KEY
	win._retroRagePendingKey = WEB_PENDING_STORAGE_KEY

	# Godot 4.7.2 Web encapsulates Emscripten FS/IDBFS internally and flushes via GodotFS.sync();
	# if a runtime exposes global FS.syncfs, call it first, then verify async IDB persistence cleanly.
	var js_script := """
(function () {
	var cb = window._retroRageSaveCb;
	var expected = window._retroRageSaveExpected;
	var key = window._retroRageSaveIdbKey;
	var pendingKey = window._retroRagePendingKey;
	function finish(ok, detail) {
		if (typeof cb === 'function') {
			try { cb(ok ? 'ok' : 'err', detail || ''); } catch (_e) {}
		}
	}
	function clearPendingIfCurrent() {
		try {
			if (window.localStorage && window.localStorage.getItem(pendingKey) === expected) {
				window.localStorage.removeItem(pendingKey);
			}
		} catch (_e) {}
	}
	try {
		var verifyIdb = function (attempt) {
			try {
				if (!window.indexedDB) {
					finish(false, 'IndexedDB API unavailable');
					return;
				}
				var openReq = window.indexedDB.open('/userfs');
				var settled = false;
				openReq.onerror = function () {
					if (settled) return;
					settled = true;
					finish(false, String(openReq.error || 'IndexedDB open error'));
				};
				openReq.onblocked = function () {
					if (settled) return;
					settled = true;
					finish(false, 'IndexedDB open blocked');
				};
				openReq.onsuccess = function () {
					if (settled) return;
					var db = openReq.result;
					function closeDb() {
						try { db && db.close(); } catch (_c) {}
					}
					if (!db || !db.objectStoreNames || !db.objectStoreNames.contains('FILE_DATA')) {
						settled = true;
						closeDb();
						finish(false, 'FILE_DATA store missing');
						return;
					}
					try {
						var tx = db.transaction(['FILE_DATA'], 'readonly');
						var req = tx.objectStore('FILE_DATA').get(key);
						req.onerror = function () {
							if (settled) return;
							settled = true;
							closeDb();
							finish(false, String(req.error || 'IndexedDB read error'));
						};
						tx.onerror = function () {
							if (settled) return;
							settled = true;
							closeDb();
							finish(false, String(tx.error || 'IndexedDB transaction error'));
						};
						req.onsuccess = function () {
							if (settled) return;
							settled = true;
							closeDb();
							var rec = req.result;
							var actual = '';
							if (rec && rec.contents) {
								try {
									actual = new TextDecoder().decode(new Uint8Array(rec.contents));
								} catch (_d) {}
							}
							if (actual === expected) {
								clearPendingIfCurrent();
								finish(true, '');
							} else if (attempt < 11) {
								var delays = [50, 100, 200, 350, 600, 1000, 1500, 2000, 2500, 3000, 3000];
								setTimeout(function () { verifyIdb(attempt + 1); }, delays[attempt] || 2000);
							} else {
								finish(false, 'Save sync verification timed out before matching IndexedDB');
							}
						};
					} catch (txErr) {
						settled = true;
						closeDb();
						finish(false, String(txErr));
					}
				};
			} catch (idbErr) {
				finish(false, String(idbErr));
			}
		};
		if (typeof FS !== 'undefined' && FS && typeof FS.syncfs === 'function') {
			FS.syncfs(false, function (fsErr) {
				if (fsErr) {
					finish(false, String(fsErr));
				} else {
					verifyIdb(0);
				}
			});
		} else {
			setTimeout(function () { verifyIdb(0); }, 25);
		}
	} catch (outerErr) {
		finish(false, String(outerErr));
	}
}());
"""
	JavaScriptBridge.eval(js_script, true)

func _on_web_sync_js_result(args: Array) -> void:
	_web_sync_in_flight = false
	var status := str(args[0]) if args.size() > 0 else "err"
	var detail := str(args[1]) if args.size() > 1 else "Unknown persistence error"

	if _web_sync_resync_needed or _web_save_generation != _web_pending_generation:
		_web_sync_resync_needed = false
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.PENDING
		if not _web_sync_debounce_queued:
			_web_sync_debounce_queued = true
			call_deferred("_start_web_persistence_sync")
		return

	if status == "ok":
		_web_confirmed_generation = _web_pending_generation
		last_save_confirmed_persistent = true
		last_persist_state = PersistState.SYNCED
		last_persist_error = ""
		save_persistence_completed.emit(true, "")
	else:
		last_save_confirmed_persistent = false
		last_persist_state = PersistState.FAILED
		last_persist_error = detail
		push_warning("[SaveManager] Web storage sync unconfirmed: %s" % detail)
		save_persistence_completed.emit(false, detail)

func is_level_unlocked(level_id: int) -> bool:
	if level_id == 1:
		return true
	return level_id <= highest_unlocked_level

func is_level_completed(level_id: int) -> bool:
	return completed_levels.has(level_id)

func get_level_stars(level_id: int) -> int:
	var key := str(level_id)
	if stage_stars.has(key):
		return int(stage_stars[key])
	if stage_stars.has(level_id):
		return int(stage_stars[level_id])
	return 0

func record_level_stars(level_id: int, earned_stars: int) -> int:
	var current_best := get_level_stars(level_id)
	var new_best := maxi(current_best, clampi(earned_stars, 0, 3))
	stage_stars[str(level_id)] = new_best
	save_data()
	return new_best

func complete_level(level_id: int, earned_stars: int = 0) -> void:
	var changed := false
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
		changed = true

	var next_level := level_id + 1
	if next_level <= 20 and next_level > highest_unlocked_level:
		highest_unlocked_level = next_level
		changed = true

	if earned_stars > 0:
		var current_best := get_level_stars(level_id)
		var new_best := maxi(current_best, clampi(earned_stars, 0, 3))
		if new_best != current_best or not stage_stars.has(str(level_id)):
			stage_stars[str(level_id)] = new_best
			changed = true

	if changed:
		save_data()

func get_completed_count() -> int:
	return completed_levels.size()

func toggle_sfx() -> bool:
	sfx_enabled = not sfx_enabled
	save_data()
	return sfx_enabled

func toggle_music() -> bool:
	music_enabled = not music_enabled
	save_data()
	return music_enabled

func is_level_15_secret_revealed() -> bool:
	return level_15_secret_revealed

func set_level_15_secret_revealed(revealed: bool = true) -> void:
	if level_15_secret_revealed != revealed:
		level_15_secret_revealed = revealed
		save_data()

func is_level_16_secret_revealed() -> bool:
	return level_16_secret_revealed

func set_level_16_secret_revealed(revealed: bool = true) -> void:
	level_16_secret_revealed = revealed





func is_bb_level_unlocked(level_id: int) -> bool:
	if level_id == 1:
		return true
	return level_id <= bb_highest_unlocked_level

func is_bb_level_completed(level_id: int) -> bool:
	return bb_completed_levels.has(level_id)

func get_bb_level_stars(level_id: int) -> int:
	var key := str(level_id)
	if bb_stage_stars.has(key):
		return int(bb_stage_stars[key])
	if bb_stage_stars.has(level_id):
		return int(bb_stage_stars[level_id])
	return 0

func record_bb_level_stars(level_id: int, earned_stars: int) -> int:
	var current_best := get_bb_level_stars(level_id)
	var new_best := maxi(current_best, clampi(earned_stars, 0, 3))
	bb_stage_stars[str(level_id)] = new_best
	save_data()
	return new_best

func complete_bb_level(level_id: int, earned_stars: int = 0) -> void:
	var changed := false
	if not bb_completed_levels.has(level_id):
		bb_completed_levels.append(level_id)
		changed = true

	var next_level := level_id + 1
	if next_level <= 20 and next_level > bb_highest_unlocked_level:
		bb_highest_unlocked_level = next_level
		changed = true

	if earned_stars > 0:
		var current_best := get_bb_level_stars(level_id)
		var new_best := maxi(current_best, clampi(earned_stars, 0, 3))
		if new_best != current_best or not bb_stage_stars.has(str(level_id)):
			bb_stage_stars[str(level_id)] = new_best
			changed = true

	if changed:
		save_data()

func get_bb_completed_count() -> int:
	return bb_completed_levels.size()
