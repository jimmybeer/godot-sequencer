extends ICommand
class_name BatchCommand

var commands:Array[ICommand]
var label:String

func _init(_commands:Array[ICommand], _label:String = "Batch") -> void:
	commands = _commands
	label = _label

func execute() -> void:
	for c in commands:
		c.execute()

func undo() -> void:
	for i in range(commands.size() - 1, -1, -1):
		commands[i].undo()

func describe() -> String:
	return label
