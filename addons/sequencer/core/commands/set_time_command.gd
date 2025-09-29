extends ICommand
class_name SetTimeCommand

var clock: Node
var before:float
var after:float
var stop:bool

func _init(_clock, _before, _after, _stop=false) -> void:
	clock = _clock
	before = _before
	after = _after
	stop = _stop

func execute() -> void:
	clock.seek(after)
	if stop:
		clock.playing = false

func undo() -> void:
	clock.seek(before)

func describe() -> String:
	return "Seek time from %s to %s" % [before, after]
