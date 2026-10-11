extends SceneTree

## Entrypoint for executing test runner via command line script.
## Switches scene to test_runner.tscn which runs inside active tree with autoloads.

func _init() -> void:
	change_scene_to_file("res://scenes/tests/test_runner.tscn")
