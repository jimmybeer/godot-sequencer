@tool
extends EditorPlugin
class_name SequenceControlsPlugin


var control_panel: SequenceControls

func _enter_tree() -> void:
	print("_ENTER_TREE")
	if control_panel == null:
		control_panel = preload("res://addons/sequencer/editor/sequencer_control_panel.tscn").instantiate()
		print("Yo1")
		add_control_to_dock(DOCK_SLOT_RIGHT_UL, control_panel)
		print("Yo2")
		control_panel.name = "Sequencer Control Panel"

func _exit_tree() -> void:
	if control_panel == null:
		return
	print("_exit_tree1")
	remove_control_from_docks(control_panel)
	print("_exit_tree2")
	control_panel.free()
	print("_exit_tree3")
	control_panel = null

func get_name() -> StringName:
	return "Sequencer Control Panel"
