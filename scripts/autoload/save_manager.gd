extends Node

## SaveManager handles persistence for Retro Rage Arcade using local user:// storage.
## Gracefully recovers from missing or corrupted save files.

const SAVE_PATH: String = "user://retro_rage_save.json"
const CURRENT_SCHEMA_VERSION: int = 1

var schema_version: int = CURRENT_SCHEMA_VERSION
var highest_unlocked_level: int = 1
var completed_levels: Array = []
var sfx_enabled: bool = true
var music_enabled: bool = true

signal progress_updated

func _ready() -> void:
	load_save()

func get_default_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"highest_unlocked_level": 1,
		"completed_levels": [],
		"sfx_enabled": true,
		"music_enabled": true
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
	sfx_enabled = true
	music_enabled = true
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

	sfx_enabled = bool(data.get("sfx_enabled", true))
	music_enabled = bool(data.get("music_enabled", true))
	progress_updated.emit()

func save_data() -> bool:
	var data := {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels,
		"sfx_enabled": sfx_enabled,
		"music_enabled": music_enabled
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

func complete_level(level_id: int) -> void:
	var changed := false
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
		changed = true

	var next_level := level_id + 1
	if next_level <= 20 and next_level > highest_unlocked_level:
		highest_unlocked_level = next_level
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
