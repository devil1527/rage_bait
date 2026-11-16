class_name BulletBetrayalLadder
extends Area2D

## Interactive ladder volume allowing natural vertical climbing,
## holding position on rungs, and reliable platform dismounting.

@export var climb_speed: float = 165.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is BulletBetrayalPlayer or body.has_method("set_on_ladder"):
		body.set_on_ladder(true)

func _on_body_exited(body: Node2D) -> void:
	if body is BulletBetrayalPlayer or body.has_method("set_on_ladder"):
		body.set_on_ladder(false)
