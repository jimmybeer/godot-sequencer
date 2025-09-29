extends ICommand
class_name SetPlatRangeCommand

var clock: Node
var before_in: float
var before_out: float
var after_in: float
var after_out: float
var widget_in:LineEdit
var widget_out:LineEdit

func _init(_clock, _before_in, _before_out, _after_in, _after_out, _widget_in, _widget_out):
	clock = _clock
	before_in = _before_in
	before_out = _before_out
	after_in = _after_in
	after_out = _after_out
	widget_in = _widget_in
	widget_out = _widget_out

func execute():
	clock.set_range(after_in, after_out)
	widget_in.set_block_signals(true)
	widget_out.set_block_signals(true)
	widget_in.text = str(after_in)
	widget_out.text = str(after_out)
	widget_in.set_block_signals(false)
	widget_out.set_block_signals(false)

func undo():
	clock.set_range(before_in, before_out)
	widget_in.set_block_signals(true)
	widget_out.set_block_signals(true)
	widget_in.text = str(before_in)
	widget_out.text = str(before_out)
	widget_in.set_block_signals(false)
	widget_out.set_block_signals(false)

func describe() -> String:
	return "Set play range from [%s–%s] to [%s–%s]" % [before_in, before_out, after_in, after_out]
