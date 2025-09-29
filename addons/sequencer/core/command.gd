extends RefCounted
class_name ICommand

func execute() -> void:
	pass

func undo() -> void:
	pass

func describe() -> String:
	return "Base Command"
