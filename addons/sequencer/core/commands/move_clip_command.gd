extends ICommand
class_name MoveClipCommand

var clip:ClipData
var old_start:float
var new_start:float

func _init(_clip:ClipData, _old_start:float, _new_start:float) -> void:
	clip = _clip
	old_start = _old_start
	new_start = _new_start

func execute() -> void:
	clip.start = new_start

func undo() -> void:
	clip.start = old_start
