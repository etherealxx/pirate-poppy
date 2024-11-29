extends Node2D

var tickpassed := 0
var secondpassed := 0
var happened_event = Array()

# amount of second needed to hold the skip cutscene button
const SKIP_CUTSENE_DURATION := 3.0
var skip_cutscene_held_time := 0.0

@onready var barrel_boy: AnimatedSprite2D = %BarrelBoy
@onready var anim: AnimationPlayer = $AnimationPlayer
#@onready var skip_text_outline_size : int = %SkipCutsceneText.get_label_settings().outline_size

@export_file("*.tscn") var main_gameplay_scene

func _ready() -> void:
	anim.play("boss_entrance")
	anim.stop()
	get_tree().paused = true
	%BlackFadeGame.show()
	%BlackFadeGame.initial_fade.connect(_on_enter_game_fade_finished)
	%BlackFadeGame.fade_finished.connect(_on_exit_game_fade_finished)
	%SkipCutsceneText.hide()
	if GlobalVar.bandana_out:
		%FullBodyAnim.hide()
		%HairOpenAnim.show()

func _on_enter_game_fade_finished():
	get_tree().paused = false

func _on_exit_game_fade_finished():
	get_tree().paused = false
	get_tree().change_scene_to_file(main_gameplay_scene)

func check_event(second):
	var value = ((secondpassed == second) and !(second in happened_event))
	if value:
		happened_event.append(second)
	return value

func _physics_process(delta: float) -> void:
	tickpassed += 1
	if $DebugSeconds.visible: $DebugSeconds.text = str(secondpassed)
	
	if Input.is_action_pressed("action"):
		%SkipCutsceneText.show()
		skip_cutscene_held_time += delta
		if skip_cutscene_held_time >= SKIP_CUTSENE_DURATION:
			transition_to_next_scene()
	else:
		%SkipCutsceneText.hide()
		skip_cutscene_held_time = 0.0
		#if skip_cutscene_held_time > 0.0:
			#skip_cutscene_held_time -= delta
	%SkipCutsceneText.get_label_settings().outline_size = floori(skip_cutscene_held_time) + 2
	
	if check_event(2): barrel_boy.play("barrel_out")
	if check_event(4): barrel_boy.flip_h = true
	if check_event(5): barrel_boy.flip_h = false
	if check_event(6):
		barrel_boy.flip_h = true
		anim.play("boss_entrance")
	if check_event(8):
		barrel_boy.flip_h = false
		barrel_boy.play("surprised")
	if check_event(12):
		barrel_boy.flip_h = true
		barrel_boy.play("surprise_loop")
	if check_event(14):
		barrel_boy.play("barrel_in")
	if check_event(16):
		transition_to_next_scene()

func transition_to_next_scene():
	GlobalVar.phase_two = true
	get_tree().paused = true
	%BlackFadeGame.do_fade_out()

func _on_second_timer_timeout() -> void:
	secondpassed += 1
