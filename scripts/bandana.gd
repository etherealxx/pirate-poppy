extends CharacterBody2D

const JUMP_VELOCITY = -200.0

@export var parabolic_stat : Parabolic

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.x = 0
	move_and_slide()

func _on_despawn_timeout() -> void:
	queue_free()
