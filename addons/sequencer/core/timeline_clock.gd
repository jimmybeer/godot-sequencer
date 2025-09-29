extends Node
class_name TimelineClock

signal time_changed(time: float)
signal loop_entered()

@export var fps:int = 30

var playing:bool = false
var t:float = 0.0
var loop:bool = false
var in_point := 0.0
var out_point := 10.0

func to_dict() -> Dictionary:
	return {
		"fps": fps,
		"t": t,
		"loop": loop,
		"in_point": in_point,
		"out_point": out_point
	}

func from_dict(data: Dictionary):
	fps = data.get("fps", fps)
	t = data.get("t", 0.0)
	loop = data.get("loop", false)
	in_point = data.get("in_point", 0.0)
	out_point = data.get("out_point", 10.0)

func play() -> void:
	t = min(t, in_point)
	playing = true

func pause() -> void:
	playing = false

func stop() -> void:
	playing = false
	t = max(t, in_point)
	emit_signal("time_changed", t)

func seek(seconds:float) -> void:
	t = max(0.0, seconds)
	emit_signal("time_changed", t)

func set_range(_in:float, _out:float) -> void:
	in_point = max(0.0, _in)
	out_point = max(in_point + 0.001, _out)

func _process(delta) -> void:
	if playing:
		t += delta
		
		if loop:
			if t >= out_point:
				t = in_point
				emit_signal("loop_entered")
		else:
			if t >= out_point:
				t = out_point
				playing = false
		emit_signal("time_changed", t)
