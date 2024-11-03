extends Node2D

var tickpassed := 0
var secondpassed := 0
var happened_event = Array()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@onready var barrel_boy: AnimatedSprite2D = %BarrelBoy

func check_event(second):
	var value = ((secondpassed == second) and (second in happened_event))
	if value:
		happened_event.append(second)
	return value

func _physics_process(delta: float) -> void:
	tickpassed += 1
	if $DebugSeconds.visible: $DebugSeconds.text = str(tickpassed)
	if check_event(1):
		pass

func _on_second_timer_timeout() -> void:
	secondpassed += 1
