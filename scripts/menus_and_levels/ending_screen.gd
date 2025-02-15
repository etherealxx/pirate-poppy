extends Node2D

@export_file("*.tscn") var main_menu_scene

var ending_bandana_out = load("res://assets/gamesprites/backgrounds/ending_raft_no_bandana.png")

var first_fade := false
var next_input := ""

func _ready() -> void:
	%BlackFadeMenu.initial_fade.connect(func(): first_fade = true)
	%BlackFadeMenu.fade_finished.connect(_on_fade_finished)
	if GlobalVar.bandana_out:
		%EndingShip.set_texture(ending_bandana_out)
	%AnimationPlayer.play("ending")

func _on_fade_finished():
	await get_tree().create_timer(0.5, true, true).timeout
	if next_input == "main_menu":
		get_tree().change_scene_to_file(main_menu_scene)
		
func _unhandled_input(_event: InputEvent) -> void:
	if next_input.is_empty() and first_fade:
		if Input.is_action_just_pressed("action"):
			next_input = "main_menu"
			%BlackFadeMenu.do_fade_out()
