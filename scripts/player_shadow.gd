extends Sprite2D

@export var player : CharacterBody2D

func _physics_process(delta: float) -> void:
	if player:
		position.x = player.position.x
