extends Node2D

@export var auto_full_screen := false
@export_file("*.tscn") var main_menu_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if auto_full_screen:
		get_window().set_mode(Window.MODE_MAXIMIZED)
	%BlackFadeCredit.fade_finished.connect(_on_fade_finished)

func _on_fade_finished():
	await get_tree().create_timer(0.5, true, true).timeout
	get_tree().change_scene_to_file(main_menu_scene)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("action"):
		#get_tree().change_scene_to_packed(main_menu_scene)
		get_tree().change_scene_to_file(main_menu_scene)
