extends ICommand
class_name SelectClipCommand

var target:ClipView
var previous:bool
var next:bool

func _init(_target:ClipView):
	target = _target
	previous = target.selected
	next = !previous

func execute() -> void:
	target.selected = next 

func undo() -> void:
	target.selected = previous
