@tool
extends EditorPlugin

var dock
var bottom_tab_button: Button

var control_panel_plugin: SequenceControlsPlugin
var control_panel:SequenceControls = null


func _enter_tree() -> void:
	dock = preload("res://addons/sequencer/editor/SequencerDock.tscn").instantiate()
	bottom_tab_button = add_control_to_bottom_panel(dock, "Sequencer")

	var sub_plugin_script = preload("res://addons/sequencer/sequencer_control_panel_plugin.gd")
	control_panel_plugin = sub_plugin_script.new()
	add_child(control_panel_plugin)
	
	await get_tree().process_frame
	control_panel = control_panel_plugin.control_panel
	
	dock.control_panel = control_panel

func _exit_tree() -> void:
	print("_exit_tree a")
	if control_panel_plugin:
		print("_exit_tree b")
		print("_exit_tree c")
		control_panel_plugin.queue_free()
		print("_exit_tree d")
		control_panel_plugin = null
		control_panel = null
		print("_exit_tree e")
	if dock:
		print("_exit_tree f")
		remove_control_from_bottom_panel(dock)
		print("_exit_tree g")
		dock.free()
		print("_exit_tree h")
