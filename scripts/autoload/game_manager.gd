extends Node

## GameManager manages level data, navigation flows, and gameplay state signals.

signal coin_collected(current: int, total: int)
signal level_completed(level_id: int)
signal player_died
signal coins_reset

var current_level_id: int = 1
var current_coins: int = 0
var total_coins_required: int = 10
var is_gameplay_active: bool = false

# 20 planned levels definitions as specified in section 7
var levels: Dictionary = {
	1: {"id": 1, "name": "The Warm-Up", "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_1.tscn", "coin_count": 10},
	2: {"id": 2, "name": "Trust Nothing", "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_2.tscn", "coin_count": 10},
	3: {"id": 3, "name": "Fire & Fury", "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_3.tscn", "coin_count": 10},
	4: {"id": 4, "name": "Crushing Silence", "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_4.tscn", "coin_count": 10},
	5: {"id": 5, "name": "The Last Laugh", "implemented": true, "scene": "res://scenes/coin_hell/coin_hell_level_5.tscn", "coin_count": 10},
	6: {"id": 6, "name": "Coin Thief", "implemented": false, "scene": "", "coin_count": 12},
	7: {"id": 7, "name": "The Vanishing Path", "implemented": false, "scene": "", "coin_count": 16},
	8: {"id": 8, "name": "Greed Trap", "implemented": false, "scene": "", "coin_count": 10},
	9: {"id": 9, "name": "The Fake Exit", "implemented": false, "scene": "", "coin_count": 15},
	10: {"id": 10, "name": "Just One More", "implemented": false, "scene": "", "coin_count": 18},
	11: {"id": 11, "name": "The Long Way", "implemented": false, "scene": "", "coin_count": 20},
	12: {"id": 12, "name": "Double Trouble", "implemented": false, "scene": "", "coin_count": 14},
	13: {"id": 13, "name": "The Coin Switch", "implemented": false, "scene": "", "coin_count": 12},
	14: {"id": 14, "name": "Nothing Is Safe", "implemented": false, "scene": "", "coin_count": 16},
	15: {"id": 15, "name": "The Betrayal", "implemented": false, "scene": "", "coin_count": 15},
	16: {"id": 16, "name": "Chaos Theory", "implemented": false, "scene": "", "coin_count": 18},
	17: {"id": 17, "name": "No Turning Back", "implemented": false, "scene": "", "coin_count": 20},
	18: {"id": 18, "name": "The Developer Laughs", "implemented": false, "scene": "", "coin_count": 15},
	19: {"id": 19, "name": "Dragon's Doorstep", "implemented": false, "scene": "", "coin_count": 22},
	20: {"id": 20, "name": "Dragon's Den", "implemented": false, "scene": "", "coin_count": 25}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	_setup_input_actions()

func _setup_input_actions() -> void:
	# Ensure custom actions exist with desktop and keyboard bindings
	_ensure_action("move_left", [KEY_LEFT, KEY_A])
	_ensure_action("move_right", [KEY_RIGHT, KEY_D])
	_ensure_action("jump", [KEY_SPACE, KEY_UP, KEY_W])
	_ensure_action("pause", [KEY_ESCAPE])

func _ensure_action(action_name: String, key_codes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for code in key_codes:
		var has_key := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == code:
				has_key = true
				break
		if not has_key:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action_name, event)

func get_level_info(level_id: int) -> Dictionary:
	return levels.get(level_id, {})

func can_play_level(level_id: int) -> bool:
	var info: Dictionary = get_level_info(level_id)
	return bool(info.get("implemented", false))

func go_to_main_menu() -> void:
	is_gameplay_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func go_to_level_select() -> void:
	is_gameplay_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/coin_hell_level_select.tscn")

func start_level(level_id: int) -> bool:
	var info: Dictionary = get_level_info(level_id)
	if not info.get("implemented", false):
		return false

	current_level_id = level_id
	total_coins_required = int(info.get("coin_count", 10))
	current_coins = 0
	is_gameplay_active = true
	get_tree().paused = false

	var scene_path: String = info.get("scene", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Scene file missing: " + scene_path)
		return false

	get_tree().change_scene_to_file(scene_path)
	return true

func restart_current_level() -> void:
	start_level(current_level_id)

func reset_coins() -> void:
	current_coins = 0
	coin_collected.emit(current_coins, total_coins_required)
	coins_reset.emit()

func collect_coin() -> void:
	current_coins = clampi(current_coins + 1, 0, total_coins_required)
	coin_collected.emit(current_coins, total_coins_required)
	AudioManager.play_sfx("coin")

func are_all_coins_collected() -> bool:
	return current_coins >= total_coins_required

func trigger_level_complete() -> void:
	if not is_gameplay_active:
		return
	is_gameplay_active = false
	SaveManager.complete_level(current_level_id)
	AudioManager.play_sfx("complete")
	level_completed.emit(current_level_id)

func trigger_player_death() -> void:
	AudioManager.play_sfx("death")
	player_died.emit()
