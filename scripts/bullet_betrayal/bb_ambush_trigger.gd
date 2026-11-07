class_name BulletBetrayalAmbushTrigger
extends Area2D

## Trigger zone that safely activates intentional ambushes in Bullet Betrayal.
## Ensures enemies emerge from designated covers/perches rather than directly on the player.

@export var target_enemies: Array[NodePath] = []
var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is BulletBetrayalPlayer or body.is_in_group("player"):
		_triggered = true
		for path in target_enemies:
			var node = get_node_or_null(path)
			if node and node.has_method("trigger_ambush"):
				node.trigger_ambush()

func reset() -> void:
	_triggered = false
