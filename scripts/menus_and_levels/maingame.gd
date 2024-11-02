extends Node2D

@export var auto_full_screen := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if auto_full_screen:
		get_window().set_mode(Window.MODE_MAXIMIZED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
