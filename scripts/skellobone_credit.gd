extends CharacterBody2D

const SPEED = 25.0

func _physics_process(delta: float) -> void:
	velocity.x = SPEED
	move_and_slide()
