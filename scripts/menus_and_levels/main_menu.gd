extends Node2D

#@export var main_gameplay_scene : PackedScene
@export_file("*.tscn") var main_gameplay_scene

func _ready() -> void:
	%BlackFadeMenu.fade_finished.connect(_on_fade_finished)
	%AnimationPlayer.play("ref_move_for_text_bounce")

func _on_fade_finished():
	await get_tree().create_timer(0.5, true, true).timeout
	GlobalVar.phase_two = false
	get_tree().change_scene_to_file(main_gameplay_scene)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("action"):
		%BlackFadeMenu.do_fade_out()
	
