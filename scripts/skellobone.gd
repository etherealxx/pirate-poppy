extends CharacterBody2D


const JUMP_VELOCITY = -400.0

@export var parabolic_stat : Parabolic
@export var hp := 2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var staff_hitbox: Area2D = $StaffHitbox

var SPEED = 25.0

var direction := 1.0
#@TODO afterjam : change this to state / state machine
var is_idling := false
var is_damaged := false
var is_flashing := false
var is_dead := false
var is_attacking := false

func _ready() -> void:
	$IdleTimer.start(randf_range(1.0, 4.0))
	anim.frame_changed.connect(_on_anim_frame_change)

func change_anim(anim_name : String):
	if !anim.get_animation() == anim_name: anim.play(anim_name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#if !is_damaged:
		#velocity = Vector2.ZERO
	if !is_dead:
		if is_idling:
			velocity = Vector2.ZERO
			change_anim("idle")
		else:
			if !is_damaged:
				if direction: # and hp > 0:
					change_anim("walk")
				#if anim.animation != "run" and !is_flashing:
					#anim.animation = "run"
				velocity.x = direction * SPEED # * damaged_multiplier
	else:
		velocity.y += parabolic_stat.gravity * delta
		
	move_and_slide()

func _on_direction_update_timeout() -> void:
	if !is_idling and !is_flashing:
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
	is_flashing = true
	anim.animation = "hurt"
	#damaged_multiplier = 0.5
	#$FlashRecover.start()
	is_idling = false
	is_damaged = true
	$IdleTimer.stop()
	var knockback_direction = 1.0 if is_player_facing_right else -1.0
	velocity = Vector2(50 * knockback_direction, -200)
	#velocity.x = SPEED # * damaged_multiplier
	#velocity.y = -300.0
	hp -= 1
	if hp <= 0:
		trigger_death(is_player_facing_right)
		return
	anim.get_material().set_shader_parameter("active", true)
	print(hp)
	$KnockbackRecoverTimer.start()

func trigger_death(is_player_facing_right):
	is_dead = true
	set_collision_mask(0)
	set_collision_layer(0)
	var angle_radians = deg_to_rad(parabolic_stat.angle_degrees)
	var d : int = 1 if is_player_facing_right else -1
	velocity.x = d * parabolic_stat.initial_velocity * cos(angle_radians)
	velocity.y = -parabolic_stat.initial_velocity * sin(angle_radians) # Negative because Godot's y-axis is downwards
	anim.flip_v = true
	anim.stop()
	$Shadow.hide()
	set_z_index(2)

func _on_knockback_recover_timer_timeout() -> void:
	if is_flashing:
		is_flashing = false
		anim.get_material().set_shader_parameter("active", false)
		is_damaged = false
		change_anim("idle")
		$IdleTimer.start(randf_range(1.0, 4.0))

func staffhitbox_enabled(is_enabled : bool):
	if is_enabled: staff_hitbox.disabled = false
	else: staff_hitbox.disabled = true

func _on_anim_frame_change():
	if anim.animation == "attack":
		match (anim.frame):
			3:
				staffhitbox_enabled(true)
			4:
				staffhitbox_enabled(false)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$AttackDelay.start(randf_range(0.1, 0.6))

func _on_attack_delay_timeout() -> void:
	pass # Replace with function body.
