extends ICommand
class_name ResizeClipCommand

var clip: ClipData
var old_start: float
var old_duration: float
var new_start: float
var new_duration: float

func _init(c: ClipData, o_start: float, o_dur: float, n_start: float, n_dur: float):
	clip = c
	old_start = o_start
	old_duration = o_dur
	new_start = n_start
	new_duration = n_dur

func execute():
	clip.start = new_start
	clip.duration = new_duration

func undo():
	clip.start = old_start
	clip.duration = old_duration

func describe() -> String:
	return "Resize Clip"
