extends Node2D

@export_file("*.tscn") var main_menu_scene
@export_file("*.tscn") var main_gameplay_scene

var first_fade := false
var next_input := ""

func _ready() -> void:
	%BlackFadeMenu.initial_fade.connect(func(): first_fade = true)
	%BlackFadeMenu.fade_finished.connect(_on_fade_finished)
	%AnimationPlayer.play("game_over_anim")

func _on_fade_finished():
	await get_tree().create_timer(0.5, true, true).timeout
	if next_input == "main_menu":
		get_tree().change_scene_to_file(main_menu_scene)
	elif next_input == "restart":
		get_tree().change_scene_to_file(main_gameplay_scene)
		
func _unhandled_input(_event: InputEvent) -> void:
	if next_input.is_empty() and first_fade:
		if Input.is_action_just_pressed("action"):
			next_input = "restart"
			%BlackFadeMenu.do_fade_out()
		elif Input.is_action_just_pressed("action2"):
			next_input = "main_menu"
			%BlackFadeMenu.do_fade_out()
