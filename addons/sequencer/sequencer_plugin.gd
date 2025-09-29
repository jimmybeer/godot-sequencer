@tool
extends EditorPlugin

var dock
var bottom_tab_button: Button

func _enter_tree() -> void:
	dock = preload("res://addons/sequencer/editor/SequencerDock.tscn").instantiate()
	bottom_tab_button = add_control_to_bottom_panel(dock, "Sequencer")

func _exit_tree() -> void:
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.free()
