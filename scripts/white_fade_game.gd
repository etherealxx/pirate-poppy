extends ColorRect

#signal initial_fade
signal fade_finished
signal ramp_up_finished

var fading_out := false
var ramping_up := false
var tween : Tween

#func _ready() -> void:
	#show()
	#tween = create_tween()
	#tween.tween_property(self,
	#"position:x",
	#160,
	#1.0).from_current()
	#tween.tween_callback(func(): initial_fade.emit())

func ramp_up():
	$RampUpTimer.start()

func do_fade_out():
	if !fading_out:
		show()
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

func _on_ramp_up_timer_timeout() -> void:
	if color.a < 1.0:
		color.a = min(color.a + 0.15, 1.0)
	else:
		ramp_up_finished.emit()
