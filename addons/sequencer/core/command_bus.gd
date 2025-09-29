extends Node
class_name CommandBus

signal stack_changed

var undo_stack:Array[ICommand] = []
var redo_stack:Array[ICommand] = []

var _clear_redo_stack:bool = true

func push(cmd:ICommand) -> void:
	# Excute the command and store it
	cmd.execute()
	undo_stack.append(cmd)
	if _clear_redo_stack:
		redo_stack.clear()
		_clear_redo_stack = false
	emit_signal("stack_changed")

func undo() -> void:
	if undo_stack.is_empty():
		return
	
	var cmd:ICommand = undo_stack.pop_back()
	cmd.undo()
	redo_stack.append(cmd)
	_clear_redo_stack = true
	emit_signal("stack_changed")

func redo() -> void:
	if redo_stack.is_empty():
		return
	
	var cmd:ICommand = redo_stack.pop_back()
	cmd.execute()
	undo_stack.append(cmd)
	emit_signal("stack_changed")
