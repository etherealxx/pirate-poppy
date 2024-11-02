extends CharacterBody2D

@warning_ignore("unused_signal")
signal shoot_spear(direction: float)
signal kill

var SPEED = 100.0
var startup_speed_boost = 100.00
var direction := 1.0
var is_flashing = false
var damaged_multiplier = 1.0
const default_direction = "left" # from left to right
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var hp := 3

func _ready() -> void:
	$AnimatedSprite2D.material = $AnimatedSprite2D.get_material().duplicate()
	SPEED += startup_speed_boost
	$StartupSpeedboostDuration.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if direction and hp > 0:
		if anim.animation != "run" and !is_flashing:
			anim.animation = "run"
		velocity.x = direction * SPEED * damaged_multiplier

	#else:
		#if anim.animation != "idle": anim.animation = "idle"
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()
	
	if get_slide_collision_count():
		for i in get_slide_collision_count():
			var collider = get_slide_collision(i).get_collider()
			if collider is Node2D:
				if collider.is_in_group("chara"):
					if !collider.is_flashing:
						if collider.is_thrustingdown and collider.position.y < position.y - 50:
							return
						collider.damaged()
	if position.y > 700: queue_free()

func adjust_spawn_direction(leftorright : String):
	if default_direction != leftorright:
		direction = -1.0
		anim.flip_h = true

func damaged():
	is_flashing = true
	anim.animation = "hurt"
	$AnimatedSprite2D.get_material().set_shader_parameter("active", true)
	damaged_multiplier = 0.5
	$FlashRecover.start()
	hp -= 1
	if hp <= 0:
		SPEED = 0
		velocity.x = 0
		anim.animation = "death"

func _on_flash_recover_timeout() -> void:
	is_flashing = false
	damaged_multiplier = 1.0
	$AnimatedSprite2D.get_material().set_shader_parameter("active", false)
	if hp <= 0:
		kill.emit()
		queue_free()

func _on_direction_update_timeout() -> void:
	if global_position > GlobalVar.character_pos:
		direction = -1.0
		anim.flip_h = true
	else:
		direction = 1.0
		anim.flip_h = false

func _on_startup_speedboost_duration_timeout() -> void:
	SPEED -= startup_speed_boost
	$StartupSpeedboostDuration.queue_free()
	if SPEED < 0: SPEED = 0
