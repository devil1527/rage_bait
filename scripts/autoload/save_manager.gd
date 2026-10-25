extends Node

## SaveManager handles persistence for Retro Rage Arcade using local user:// storage.
## Gracefully recovers from missing or corrupted save files.

const SAVE_PATH: String = "user://retro_rage_save.json"
const CURRENT_SCHEMA_VERSION: int = 2

var schema_version: int = CURRENT_SCHEMA_VERSION
var highest_unlocked_level: int = 1
var completed_levels: Array = []
var stage_stars: Dictionary = {}
var sfx_enabled: bool = true
var music_enabled: bool = true
var level_15_secret_revealed: bool = false
var level_16_secret_revealed: bool = false

signal progress_updated

func _ready() -> void:
	load_save()

func get_default_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"highest_unlocked_level": 1,
		"completed_levels": [],
		"stage_stars": {},
		"sfx_enabled": true,
		"music_enabled": true,
		"level_15_secret_revealed": false
	}

func load_save() -> void:
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
		"level_15_secret_revealed": level_15_secret_revealed
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to write save file at: " + SAVE_PATH)
		return false

	var json_string := JSON.stringify(data, "  ")
	file.store_string(json_string)
	file.close()
	progress_updated.emit()
	return true

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



