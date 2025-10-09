@tool
extends EditorPlugin

var dock
var bottom_tab_button: Button

var control_panel_plugin: SequenceControlsPlugin
var control_panel:SequenceControls = null

var sequencer_hub:SequencerHub

func _enter_tree() -> void:
	dock = preload("res://addons/sequencer/editor/SequencerDock.tscn").instantiate()

	var sub_plugin_script = preload("res://addons/sequencer/sequencer_control_panel_plugin.gd")
	control_panel_plugin = sub_plugin_script.new()
	
	sequencer_hub = preload("res://addons/sequencer/core/utils/sequencer_hub.gd").new()
	add_child(sequencer_hub)
		
	bottom_tab_button = add_control_to_bottom_panel(dock, "Sequencer")
	add_child(control_panel_plugin)
	await get_tree().process_frame
	#control_panel = control_panel_plugin.control_panel
	
	#dock.control_panel = control_panel
	# Pass hub reference to both docks
	dock.set_hub(sequencer_hub)
	control_panel_plugin.control_panel.set_hub(sequencer_hub)

func _exit_tree() -> void:
	if control_panel_plugin:
		control_panel_plugin.queue_free()
		control_panel_plugin = null
		control_panel = null
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.free()
