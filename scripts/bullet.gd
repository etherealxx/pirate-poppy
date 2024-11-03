extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -400.0

var direction = 1.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += 70 * delta
	
	velocity.x = direction * SPEED
	$Sprite2D.flip_h = true if direction < 0 else false

	if position.y > 160:
		queue_free()
		return
	
	move_and_slide()

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if !body.is_flashing:
			body.take_damage(!$Sprite2D.flip_h)
			queue_free()
