extends ICommand
class_name SetFPSCommand

var clock:Node
var before:int
var after:int
var widget:SpinBox

func _init(_clock, _before, _after, _widget) -> void:
	clock = _clock
	before = _before
	after = _after
	widget = _widget

func execute() -> void:
	clock.fps = after
	widget.set_block_signals(true)
	widget.value = after
	widget.set_block_signals(false)

func undo() -> void:
	clock.fps = before
	widget.set_block_signals(true)
	widget.value = before
	widget.set_block_signals(false)

func describe() -> String:
	return "Change FPS from %d to %d" % [before, after]
