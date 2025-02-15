extends CharacterBody2D

signal hp_updated(current_hp : int)

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

@export var can_attack_while_iframe := false

#@onready var body_sprite: AnimatedSprite2D = $BodyAnim
#@onready var head_armor_sprite : AnimatedSprite2D = $HeadArmorAnim
#@onready var head_bare_anim: AnimatedSprite2D = $HeadBareAnim
@onready var full_body_anim: AnimatedSprite2D = $FullBodyAnim
@onready var hair_open_anim: AnimatedSprite2D = $HairOpenAnim
@onready var sword_hitboxshape : CollisionShape2D = $SwordHitbox/CollisionShape2D

var bandana = load("res://scenes/main_gameplay/bandana.tscn")

var is_attacking := false
var is_flashing := false
var is_invincible := false #@TBD
var do_dash := false
var land_to_move := false
var hp := 3
var hair_out := false

const MAX_BLOCK_FUEL := 140
var block_fuel := MAX_BLOCK_FUEL

enum State {MOVABLE, IDLING, ATTACKING, DAMAGED, DEAD, BLOCKING}
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
	full_body_anim.get_material().set_shader_parameter("active", false)
	GlobalVar.player_hp = hp
	$FullBodyAnim.show()
	$HairOpenAnim.hide()
	set_collision_mask(CollisionCalc.mask([2,3,5,6]))
	if GlobalVar.bandana_out:
		hair_out = true
		$FullBodyAnim.hide()
		$HairOpenAnim.show()

func sync_change_anim(anim_name : String):
	if !full_body_anim.get_animation() == anim_name: full_body_anim.play(anim_name)
	if !hair_open_anim.get_animation() == anim_name: hair_open_anim.play(anim_name)

func sync_framestart_anim():
	hair_open_anim.frame = 0
	full_body_anim.frame = 0

func sync_change_flip(flip : bool):
	hair_open_anim.flip_h = flip
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
	
	if $DebugState.visible: $DebugState.text = str(current_state)
	
	match (current_state):
		State.DAMAGED:
			if is_on_floor() and land_to_move:
				land_to_move = false
				current_state = State.MOVABLE
				swordhitbox_enabled(false)
				velocity.x = 0.0
		State.BLOCKING:
			if Input.is_action_pressed("action2"):
				if block_fuel > 0:
					block_fuel -= 1
					sync_change_anim("block")
					if $ShieldKnockDuration.time_left > 0:
						velocity.x = move_toward(velocity.x, 0, 1) # slowing speed
					else: velocity.x = move_toward(velocity.x, 0, SPEED)
				else:
					sync_change_anim("shield_drop")
					is_attacking = false
					swordhitbox_enabled(false)
					current_state = State.MOVABLE
			else:
				is_attacking = false
				swordhitbox_enabled(false)
				current_state = State.MOVABLE
		State.MOVABLE:
			if is_on_floor():
				if Input.is_action_just_pressed("action"):
					if !can_attack_while_iframe and is_flashing:
						return
					is_attacking = true
					velocity.x = 0.0
					swordhitbox_enabled(false)
					sync_change_anim("attack")
				elif Input.is_action_just_pressed("action2") and !is_attacking and block_fuel > 60: # block
					block_fuel -= 10
					velocity.x = 0.0
					current_state = State.BLOCKING
				if !Input.is_action_pressed("action2") and block_fuel < MAX_BLOCK_FUEL:
					block_fuel += 1
					
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
					if is_on_floor() and full_body_anim.get_animation() != "shield_drop":
						sync_change_anim("idle")
					velocity.x = move_toward(velocity.x, 0, SPEED)
			else:
				if do_dash:
					do_dash = false
					var dash_direction = -1.0 if full_body_anim.flip_h else 1.0
					velocity.x = dash_direction * SPEED * 0.2
		State.DEAD:
			if is_on_floor() and land_to_move:
				sync_change_anim("knocked")
	
	if $DebugFuel.visible: $DebugFuel.text = str(block_fuel)
	move_and_slide()

func _on_position_update_timeout() -> void:
	GlobalVar.character_pos = global_position

func _on_fullbody_animation_finished():
	if full_body_anim.animation == "attack":
		is_attacking = false
		velocity.x = 0.0
		swordhitbox_enabled(false)
	elif full_body_anim.animation == "shield_drop" and current_state != State.DAMAGED:
		current_state = State.MOVABLE

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
	var is_colliding_wall = false
	
	#@TODO this cannot work somehow
	#var bodies = $PoppyWallDetector.get_overlapping_bodies()
	#if !bodies.is_empty():
		#for body in bodies:
			#print(body.name)
			#if body.is_in_group("poppy_wall"):
				#is_colliding_wall = true
				#break
	
	if current_state == State.BLOCKING \
	and (is_enemy_facing_right == full_body_anim.flip_h) and !is_colliding_wall: #opposite direction
		var knockback_direction = 1.0 if is_enemy_facing_right else -1.0
		velocity = Vector2(70 * knockback_direction, 0)
		$ShieldKnockDuration.start()
	else:
		is_flashing = true
		
		current_state = State.DAMAGED
		var knockback_direction = 1.0 if is_enemy_facing_right else -1.0
		velocity = Vector2(70 * knockback_direction, -250)
		#velocity.x = SPEED # * damaged_multiplier
		#velocity.y = -300.0
		hp -= 1
		hp_updated.emit(hp)
		if hp == 1 and !hair_out:
			hair_out = true
			$FullBodyAnim.hide()
			$HairOpenAnim.show()
			call_deferred("throw_bandana")
		full_body_anim.get_material().set_shader_parameter("active", true)
		set_collision_mask(CollisionCalc.mask([3,5,6]))
		is_attacking = false
		sync_change_anim("hurt")
		$DamagedIframeDuration.start()
		$KnockbackRecoverOnLanding.start()
		if hp <= 0:
			current_state = State.DEAD
		#$KnockbackRecoverTimer.start()

func throw_bandana():
	var new_bandana = bandana.instantiate()
	new_bandana.position = position
	#add_sibling(new_bandana)
	var index = get_index()
	get_parent().add_child(new_bandana)
	get_parent().move_child(new_bandana, index)
	var angle_radians = deg_to_rad(new_bandana.parabolic_stat.angle_degrees)
	var d : int = 1 if full_body_anim.flip_h else -1
	new_bandana.velocity.x = d * new_bandana.parabolic_stat.initial_velocity * cos(angle_radians)
	new_bandana.velocity.y = -new_bandana.parabolic_stat.initial_velocity * sin(angle_radians)
	GlobalVar.bandana_out = true

func _on_damaged_iframe_timeout() -> void:
	is_flashing = false
	full_body_anim.get_material().set_shader_parameter("active", false)
	set_collision_mask(CollisionCalc.mask([2,3,5,6]))
	if !full_body_anim.animation == "attack":
		is_attacking = false

func _on_knockback_recover_on_landing_timeout() -> void:
	land_to_move = true

func _on_item_collector_body_entered(body: Node2D) -> void:
	if body.is_in_group("heart_item"):
		body.queue_free()
		if hp > 0 and hp < 3:
			hp += 1
			hp_updated.emit(hp)

func _on_stuck_checker_timeout() -> void:
	if !full_body_anim.is_playing() and full_body_anim.animation == "attack" \
	and full_body_anim.frame == 5:
		is_attacking = false
		velocity.x = 0.0
		swordhitbox_enabled(false)
		
