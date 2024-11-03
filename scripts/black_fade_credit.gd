extends ColorRect

signal fade_finished

@export var fade_out := false

var fading_out := false
var tween : Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()
	#var tween = create_tween()
	#tween.tween_property(self,
	#"color:a",
	#0.0, # transparent
	#0.5)
	tween = create_tween()
	tween.tween_property(self,
	"position:x",
	160,
	1.5).from_current()
	tween.tween_callback(func(): position.x = -160).set_delay(2.0)
	tween.tween_property(self,
	"position:x",
	0,
	1.0).from(-160)
	tween.tween_callback(func(): fade_finished.emit())
