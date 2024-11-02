extends CharacterBody2D


const JUMP_VELOCITY = -400.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var SPEED = 25.0
var hp := 2
var direction := 1.0
var is_idling := false
var is_damaged := false

func _ready() -> void:
	$IdleTimer.start(randf_range(1.0, 4.0))

func change_anim(anim_name : String):
	if !anim.get_animation() == anim_name: anim.play(anim_name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#if !is_damaged:
		#velocity = Vector2.ZERO
		
	if is_idling:
		velocity = Vector2.ZERO
		change_anim("idle")
	else:
		if !is_damaged:
			if direction and hp > 0:
				change_anim("walk")
			#if anim.animation != "run" and !is_flashing:
				#anim.animation = "run"
			velocity.x = direction * SPEED # * damaged_multiplier

	move_and_slide()

func _on_direction_update_timeout() -> void:
	if !is_idling:
		if global_position > GlobalVar.character_pos:
			direction = -1.0
			anim.flip_h = true
		else:
			direction = 1.0
			anim.flip_h = false

func _on_idle_timer_timeout() -> void:
	if !is_damaged:
		is_idling = !is_idling
		if is_idling: $IdleTimer.start(randf_range(1.0, 2.0)) # recover faster
		else: $IdleTimer.start(randf_range(1.0, 4.0))

func take_damage(is_player_facing_right : bool):
	print("damage taken!")
	#is_flashing = true
	#anim.animation = "hurt"
	#$AnimatedSprite2D.get_material().set_shader_parameter("active", true)
	#damaged_multiplier = 0.5
	#$FlashRecover.start()
	is_idling = false
	is_damaged = true
	var direction = 1.0 if is_player_facing_right else -1.0
	velocity = Vector2(50 * direction, -200)
	#velocity.x = SPEED # * damaged_multiplier
	#velocity.y = -300.0
	hp -= 1
	#if hp <= 0:
		#SPEED = 0
		#velocity.x = 0
	print(hp)
	$KnockbackRecoverTimer.start()

func _on_knockback_recover_timer_timeout() -> void:
	is_damaged = false
	$IdleTimer.start(randf_range(1.0, 4.0))
