@tool
extends EditorPlugin
class_name SequenceControlsPlugin


var control_panel: SequenceControls

func _enter_tree() -> void:
	if control_panel == null:
		control_panel = preload("res://addons/sequencer/editor/sequencer_control_panel.tscn").instantiate()
		add_control_to_dock(DOCK_SLOT_RIGHT_UL, control_panel)
		control_panel.name = "Sequencer Control Panel"

func _exit_tree() -> void:
	if control_panel == null:
		return
	remove_control_from_docks(control_panel)
	control_panel.free()
	control_panel = null

func get_name() -> StringName:
	return "Sequencer Control Panel"
