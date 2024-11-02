extends Node2D

@export var auto_full_screen := false
@export var player : CharacterBody2D

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
