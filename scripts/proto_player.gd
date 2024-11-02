extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func handle_jump_anim(velo_y : float):
	if velo_y < 0.0: if !sprite.get_animation() == "jump": sprite.play("jump")
	if velo_y > 0.0: if !sprite.get_animation() == "fall": sprite.play("fall")
	
func handle_run_anim(plus_right : float, velo_y : float):
	if plus_right > 0:
		sprite.flip_h = false
		sprite.offset.x = 0.0
	else:
		sprite.flip_h = true
		sprite.offset.x = -2.4
	if velo_y == 0:
		if !sprite.get_animation() == "run": sprite.play("run")

	handle_jump_anim(velo_y)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		handle_run_anim(direction, velocity.y)
	else:
		handle_jump_anim(velocity.y)
		if !sprite.get_animation() == "idle" and is_on_floor(): sprite.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
