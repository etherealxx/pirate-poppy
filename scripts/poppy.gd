extends CharacterBody2D

signal hp_updated(current_hp : int)

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

@onready var body_sprite: AnimatedSprite2D = $BodyAnim
@onready var head_armor_sprite : AnimatedSprite2D = $HeadArmorAnim
@onready var head_bare_anim: AnimatedSprite2D = $HeadBareAnim
@onready var full_body_anim: AnimatedSprite2D = $FullBodyAnim
@onready var sword_hitboxshape : CollisionShape2D = $SwordHitbox/CollisionShape2D

var is_attacking := false
var is_flashing := false
var do_dash := false
var land_to_move := false
var hp := 3

enum State {MOVABLE, IDLING, ATTACKING, DAMAGED, DEAD}
var current_state : State = State.MOVABLE

func swordhitbox_enabled(is_enabled : bool):
	if is_enabled: sword_hitboxshape.disabled = false
	else: sword_hitboxshape.disabled = true

func _ready() -> void:
	#head_bare_anim.hide()
	sync_change_anim("idle")
	sync_framestart_anim()
	_on_position_update_timeout()
	full_body_anim.animation_finished.connect(_on_fullbody_animation_finished)
	full_body_anim.frame_changed.connect(_on_fullbody_anim_framechange)
	GlobalVar.player_hp = hp

func sync_change_anim(anim_name : String):
	if !body_sprite.get_animation() == anim_name: body_sprite.play(anim_name)
	if !head_armor_sprite.get_animation() == anim_name: head_armor_sprite.play(anim_name)
	if !head_bare_anim.get_animation() == anim_name: head_bare_anim.play(anim_name)
	if !full_body_anim.get_animation() == anim_name: full_body_anim.play(anim_name)

func sync_framestart_anim():
	body_sprite.frame = 0
	head_armor_sprite.frame = 0
	head_bare_anim.frame = 0
	full_body_anim.frame = 0

func sync_change_flip(flip : bool):
	body_sprite.flip_h = flip
	head_armor_sprite.flip_h = flip
	head_bare_anim.flip_h = flip
	full_body_anim.flip_h = flip
	$SwordHitbox.scale.x = -1.0 if flip else 1.0

func handle_jump_anim(velo_y : float):
	if velo_y < 0.0: sync_change_anim("jump")
	if velo_y > 0.0: sync_change_anim("fall")
	
func handle_run_anim(plus_right : float, velo_y : float):
	if plus_right > 0:
		sync_change_flip(false)
		#sprite.offset.x = 0.0
	else:
		sync_change_flip(true)
		#sprite.offset.x = -2.4
	if velo_y == 0:
		sync_change_anim("run")

	handle_jump_anim(velo_y)

func toggle_armor():
	$HeadArmorAnim.visible = !$HeadArmorAnim.visible
	$HeadBareAnim.visible = !$HeadBareAnim.visible

func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("debug_button"):
		#print("debug_pressed")
		#toggle_armor()
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match (current_state):
		State.DAMAGED:
			if is_on_floor() and land_to_move:
				land_to_move = false
				current_state = State.MOVABLE
		State.MOVABLE:
			if is_on_floor():
				if Input.is_action_just_pressed("action") and !is_flashing:
					is_attacking = true
					velocity.x = 0.0
					swordhitbox_enabled(false)
					sync_change_anim("attack")
					
			if !is_attacking:
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
					if is_on_floor(): sync_change_anim("idle")
					velocity.x = move_toward(velocity.x, 0, SPEED)
			else:
				if do_dash:
					do_dash = false
					var dash_direction = -1.0 if full_body_anim.flip_h else 1.0
					velocity.x = dash_direction * SPEED * 0.2
			
	move_and_slide()

func _on_position_update_timeout() -> void:
	GlobalVar.character_pos = global_position

func _on_fullbody_animation_finished():
	if full_body_anim.animation == "attack":
		is_attacking = false
		velocity.x = 0.0
		swordhitbox_enabled(false)

func _on_fullbody_anim_framechange():
	if full_body_anim.animation == "attack":
		match (full_body_anim.frame):
			2:
				do_dash = true
			3:
				swordhitbox_enabled(true)
			4:
				swordhitbox_enabled(false)

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if !body.is_flashing:
			body.take_damage(!full_body_anim.flip_h)

func take_damage(is_enemy_facing_right : bool):
	#anim.animation = "hurt"
	#damaged_multiplier = 0.5
	#$FlashRecover.start()
	#is_idling = false
	is_flashing = true
	current_state = State.DAMAGED
	var knockback_direction = 1.0 if is_enemy_facing_right else -1.0
	velocity = Vector2(70 * knockback_direction, -250)
	#velocity.x = SPEED # * damaged_multiplier
	#velocity.y = -300.0
	hp -= 1
	hp_updated.emit(hp)
	if hp <= 0:
		#trigger_death(is_enemy_facing_right)
		#return
		pass
	full_body_anim.get_material().set_shader_parameter("active", true)
	set_collision_mask(CollisionCalc.mask([3,4]))
	$DamagedIframeDuration.start()
	$KnockbackRecoverOnLanding.start()
	#$KnockbackRecoverTimer.start()

func _on_damaged_iframe_timeout() -> void:
	is_flashing = false
	full_body_anim.get_material().set_shader_parameter("active", false)
	set_collision_mask(CollisionCalc.mask([2,3,4]))

func _on_knockback_recover_on_landing_timeout() -> void:
	land_to_move = true
