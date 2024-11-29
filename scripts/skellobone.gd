extends CharacterBody2D

signal add_score(score_amount : int)

const JUMP_VELOCITY = -400.0

var heart_item = load("res://scenes/main_gameplay/heart_item.tscn")

@export var parabolic_stat : Parabolic
@export var hp := 2
@export var debug_instant_deploy := false
@export var resist_hit := false # hitting the enemy on his attacking frame onward won't give knockback
#@export_range(0.0, 10.0) var test : float

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var staff_hitbox: Area2D = $StaffHitbox
@onready var player_detector: Area2D = $PlayerDetector

var SPEED = 25.0

var direction := 1.0
#@TODO afterjam : change this to state / state machine
#var is_idling := false
var is_damaged := false
var is_flashing := false
var is_dead := false
#var is_attacking := false

enum State {DEPLOYING, MOVING, IDLING, ATTACKING, DAMAGED, DEAD}
var current_state : State = State.MOVING

func _ready() -> void:
	anim.frame_changed.connect(_on_anim_frame_change)
	anim.animation_finished.connect(_on_animation_finished)
	if debug_instant_deploy:
		deploy()
		return
	current_state = State.MOVING
	$IdleTimer.start(randf_range(1.0, 4.0))
	SPEED = randf_range(20, 30)
	anim.material = anim.material.duplicate()
	
func deploy():
	current_state = State.DEPLOYING
	set_z_index(-1)
	velocity.y = -300.0
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self,
	"scale",
	Vector2.ONE, 
	0.5)
	tween.tween_callback(_after_deploy)
	
func _after_deploy():
	current_state = State.MOVING
	$IdleTimer.start(randf_range(1.0, 4.0))
	set_z_index(0)
	
func change_anim(anim_name : String):
	if !anim.get_animation() == anim_name: anim.play(anim_name)

func _physics_process(delta: float) -> void:
	if not is_on_floor() and current_state != State.DEAD:
		velocity += get_gravity() * delta
	
	match (current_state):
		State.IDLING:
			velocity = Vector2.ZERO
			change_anim("idle")
		State.MOVING:
			velocity.x = direction * SPEED
			change_anim("walk")
		State.DAMAGED:
			change_anim("hurt")
		State.DEAD:
			velocity.y += parabolic_stat.gravity * delta
			if position.y > 160:
				queue_free()
				return
		State.DEPLOYING:
			if velocity.y > 0:
				set_z_index(0)
		
	move_and_slide()

func _on_direction_update_timeout() -> void:
	if !(current_state in [State.IDLING, State.ATTACKING])  and !is_flashing:
		if global_position > GlobalVar.character_pos:
			direction = -1.0
			anim.flip_h = true
		else:
			direction = 1.0
			anim.flip_h = false
		staff_hitbox.scale.x = direction
		player_detector.scale.x = direction

func _on_idle_timer_timeout() -> void:
	if current_state in [State.MOVING, State.IDLING]:
		match (current_state):
			State.IDLING:
				var bodies = $PlayerDetector.get_overlapping_bodies()
				for body in bodies:
					if body.is_in_group("player"):
						current_state = State.MOVING
						$AttackDelay.start(randf_range(0.2, 0.2))
						#_on_attack_delay_timeout()
						return
				current_state = State.MOVING
				$IdleTimer.start(randf_range(1.0, 4.0))
			State.MOVING:
				current_state = State.IDLING
				$IdleTimer.start(randf_range(1.0, 2.0)) # recover faster
	else:
		if $IdleTimer.is_stopped():
			$IdleTimer.start(randf_range(1.0, 2.0)) # recover faster
		
func take_damage(is_player_facing_right : bool):
	#anim.animation = "hurt"
	#damaged_multiplier = 0.5
	#$FlashRecover.start()
	#is_idling = false
	is_flashing = true
	staffhitbox_enabled(false)
	$IdleTimer.stop()
	if anim.animation == "attack" and (anim.frame in [3, 4, 5]) and resist_hit:
		pass
	else:
		current_state = State.DAMAGED
		var knockback_direction = 1.0 if is_player_facing_right else -1.0
		velocity = Vector2(randf_range(40, 60) * knockback_direction, -200)
	#velocity.x = SPEED # * damaged_multiplier
	#velocity.y = -300.0
	hp -= 1
	if hp <= 0:
		trigger_death(is_player_facing_right)
		return
	anim.get_material().set_shader_parameter("active", true)
	$KnockbackRecoverTimer.start()

func trigger_death(is_player_facing_right):

	current_state = State.DEAD
	$IdleTimer.stop()
	change_anim("hurt")
	set_collision_mask(0)
	set_collision_layer(0)
	staffhitbox_enabled(false)
	
	var angle_radians = deg_to_rad(parabolic_stat.angle_degrees)
	var d : int = 1 if is_player_facing_right else -1
	velocity.x = d * parabolic_stat.initial_velocity * cos(angle_radians)
	velocity.y = -parabolic_stat.initial_velocity * sin(angle_radians) # Negative because Godot's y-axis is downwards
	anim.flip_v = true
	anim.stop()
	$Shadow.hide()
	set_z_index(2)
	add_score.emit(1)
	if randi_range(1, 5) == 1:
		call_deferred("spawn_heart")

func spawn_heart():
	var new_heart = heart_item.instantiate()
	new_heart.position = position
	add_sibling(new_heart)

func _on_knockback_recover_timer_timeout() -> void:
	if is_flashing:
		is_flashing = false
		anim.get_material().set_shader_parameter("active", false)
		current_state = State.MOVING
		$IdleTimer.start(randf_range(1.0, 4.0))

func staffhitbox_enabled(is_enabled : bool):
	staff_hitbox.set_monitoring(is_enabled)

func _on_anim_frame_change():
	if anim.animation == "attack" and current_state == State.ATTACKING:
		match (anim.frame):
			4:
				if is_on_floor():
					staffhitbox_enabled(true)
			5:
				staffhitbox_enabled(false)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state in [State.MOVING, State.IDLING]:
		$AttackDelay.start(randf_range(0.2, 0.7))

func _on_attack_delay_timeout() -> void:
	#@TODO cekkk
	if current_state in [State.MOVING, State.IDLING]:
		current_state = State.ATTACKING
		velocity.x = 0.0
		change_anim("attack")

func _on_animation_finished() -> void:
	if anim.animation == "attack":
		current_state = State.IDLING
		if $IdleTimer.is_stopped():
			$IdleTimer.start(randf_range(1.0, 3.0))
		staffhitbox_enabled(false)

func _on_staff_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if !body.is_flashing and !body.is_invincible:
			body.take_damage(!anim.flip_h)
