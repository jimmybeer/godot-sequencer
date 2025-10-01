extends ICommand
class_name ClearSelectionCommand

var clips:Array
var previous:Array

func _init(_clips:Array, ignore:ClipView) -> void:
	clips = _clips
	previous = []
	for c in clips:
		if c.selected and c != ignore:
			previous.append(c)

func execute() -> void:
	for c in previous:
		c.selected = false

func undo() -> void:
	for c in previous:
		c.selected = true
