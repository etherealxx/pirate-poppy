extends Node2D

@export var auto_full_screen := false
@export var player : CharacterBody2D
@export var every_enemies : Array[PackedScene]

var score := 0
var round_duration := 60

func _ready() -> void:
	if auto_full_screen:
		get_window().set_mode(Window.MODE_MAXIMIZED)
	if player:
		player.hp_updated.connect(_on_player_hp_updated)

func _on_player_hp_updated(hp):
	for hpicon in %HBoxHP.get_children():
		if hpicon is TextureRect:
			#hpicon.visible = int(hpicon.name.trim_prefix("HP")) <= hp
			if int(hpicon.name.trim_prefix("HP")) <= hp: hpicon.filled_heart()
			else: hpicon.empty_heart()

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
	if player.hp > 0:
		instantiate_from_random_spawner(%EnemySpawners, %Enemies, every_enemies)
		$EnemySpawnTimer.start(decide_spawn_timer_enemy())

func _on_second_timer_timeout() -> void:
	if round_duration > 0:
		round_duration -= 1
	%Countdown.text = str(round_duration).pad_zeros(2)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_reset_button"):
		get_tree().reload_current_scene()
