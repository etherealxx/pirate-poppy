extends Node

var character_pos := Vector2.ZERO
var player_hp := 3
var phase_two := false
var bandana_out := false
var game_score := 0

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen_button"):
		var window = get_tree().get_root()
		match window.get_mode():
			Window.MODE_WINDOWED:
				window.set_mode(Window.MODE_MAXIMIZED)
			Window.MODE_MAXIMIZED:
				window.set_mode(Window.MODE_WINDOWED)
			_:
				window.set_mode(Window.MODE_MAXIMIZED)
