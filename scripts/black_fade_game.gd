extends ColorRect

signal initial_fade
signal fade_finished

var fading_out := false
var tween : Tween

func _ready() -> void:
	show()
	tween = create_tween()
	tween.tween_property(self,
	"position:x",
	160,
	1.0).from_current()
	tween.tween_callback(func(): initial_fade.emit())

func do_fade_out():
	if !fading_out:
		fading_out = true
		#tween.stop()
		position.x = -160
		tween.kill()
		tween = create_tween()
		tween.tween_property(self,
		"position:x",
		0,
		1.0).from(-160)
		tween.tween_callback(func(): fade_finished.emit())
