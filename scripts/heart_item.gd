extends CharacterBody2D

const JUMP_VELOCITY = -200.0

func _ready() -> void:
	velocity.y = JUMP_VELOCITY

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
