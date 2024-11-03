extends Node2D

@export var auto_full_screen := false
@export var debug_instant_phase_two := false
@export var debug_dont_spawn := false
@export var player : CharacterBody2D
@export var every_enemies : Array[PackedScene]
@export_file("*.tscn") var game_over_scene
@export_file("*.tscn") var ending_scene
@export_file("*.tscn") var cutscene_scene

var boss = load("res://scenes/characters/ambaskele.tscn")
var bullet = load("res://scenes/bullet.tscn")
var score := 0
var round_duration := 60
var shield
var is_winning := false
var is_going_cutscene := false

func _ready() -> void:
	Engine.set_time_scale(1.0)
	if auto_full_screen:
		get_window().set_mode(Window.MODE_MAXIMIZED)
	if player:
		player.hp_updated.connect(_on_player_hp_updated)
	get_tree().paused = true
	%BlackFadeGame.show()
	%BlackFadeGame.initial_fade.connect(_on_enter_game_fade_finished)
	%BlackFadeGame.fade_finished.connect(_on_exit_game_fade_finished)
	%WhiteFadeGame.ramp_up_finished.connect(_on_final_blow_fade_finished)
	score = GlobalVar.game_score
	%Score.text = str(score).pad_zeros(3)
	if debug_instant_phase_two: GlobalVar.phase_two = true
	if GlobalVar.phase_two:
		%Clock.set_texture(load("res://assets/gamesprites/UI/heart_boss.png"))
		var summon_boss = boss.instantiate()
		%Enemies.add_child(summon_boss)
		summon_boss.position = Vector2(324, 63)
		summon_boss.spawn_bullet.connect(_on_boss_spawn_bullet)
		summon_boss.hp_updated.connect(_on_boss_hp_update)
		%Countdown.text = str(summon_boss.hp).pad_zeros(2)
		
		#$Sprites/Ambaskele.spawn_bullet.connect(_on_boss_spawn_bullet)

func _on_boss_hp_update(hp):
	if hp >= 0:
		%Countdown.text = str(hp).pad_zeros(2)
	if hp <= 0:
		GlobalVar.game_score = score
		%WhiteFadeGame.ramp_up()
		Engine.set_time_scale(0.8)
		player.set_collision_mask(CollisionCalc.mask([3,5,6]))
	
func _on_final_blow_fade_finished():
	is_winning = true
	Engine.set_time_scale(1.0)
	get_tree().paused = true
	%BlackFadeGame.do_fade_out()

func _on_boss_spawn_bullet(is_facing_right : bool, global_location : Vector2):
	print("shot")
	var new_bullet : CharacterBody2D = bullet.instantiate()
	new_bullet.global_position = global_location
	new_bullet.direction = 1.0 if is_facing_right else -1.0
	%Enemies.add_child(new_bullet)

func _on_enter_game_fade_finished():
	get_tree().paused = false

func _on_exit_game_fade_finished():
	get_tree().paused = false
	if is_going_cutscene:
		get_tree().change_scene_to_file(cutscene_scene)
		return
	if is_winning:
		get_tree().change_scene_to_file(ending_scene)
	else:
		get_tree().change_scene_to_file(game_over_scene)

func _on_player_hp_updated(hp):
	for hpicon in %HBoxHP.get_children():
		if hpicon is TextureRect:
			#hpicon.visible = int(hpicon.name.trim_prefix("HP")) <= hp
			if int(hpicon.name.trim_prefix("HP")) <= hp: hpicon.filled_heart()
			else: hpicon.empty_heart()
	if hp <= 0:
		Engine.set_time_scale(0.8)
		await get_tree().create_timer(1.0, true, true).timeout
		Engine.set_time_scale(1.0)
		get_tree().paused = true
		%BlackFadeGame.do_fade_out()

func instantiate_from_random_spawner(	spawnergroup_node : Node2D,
										target_groupnode : Node2D,
										array_to_pick : Array[PackedScene]	):
	var spawners : Array = spawnergroup_node.get_children()
	var spawner_node : Marker2D = spawners.pick_random()
	var new_enemy : CharacterBody2D = array_to_pick.pick_random().instantiate()
	new_enemy.position = spawner_node.position
	new_enemy.add_score.connect(_on_add_score)
	#print("new enemy spawned at %v" % new_enemy.global_position)
	target_groupnode.add_child(new_enemy)
	new_enemy._on_direction_update_timeout()
	if spawner_node.is_deploy and new_enemy.has_method("deploy"):
		new_enemy.deploy()
	#print("spawned at %v" % spawner_node.position)
	#new_enemy.start_wall_cooldown()

func _on_add_score(score_to_add):
	score += score_to_add
	%Score.text = str(score).pad_zeros(3)

func decide_spawn_timer_enemy() -> float:
	return randf_range(3.0, 5.0)

func _on_enemy_spawn_timer_timeout() -> void:
	if player.hp > 0 and !debug_dont_spawn:
		instantiate_from_random_spawner(%EnemySpawners, %Enemies, every_enemies)
		$EnemySpawnTimer.start(decide_spawn_timer_enemy())

func _on_second_timer_timeout() -> void:
	if !GlobalVar.phase_two:
		if round_duration > 0:
			round_duration -= 1
		%Countdown.text = str(round_duration).pad_zeros(2)
		if round_duration <= 0:
			await get_tree().create_timer(1.0, true, true).timeout
			#@TODO GANTI 
			is_going_cutscene = true
			GlobalVar.game_score = score
			get_tree().paused = true
			%BlackFadeGame.do_fade_out()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_reset_button"):
		GlobalVar.phase_two = true
		get_tree().reload_current_scene()
