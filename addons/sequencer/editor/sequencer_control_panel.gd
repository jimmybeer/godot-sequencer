@tool
extends Control
class_name SequenceControls

@onready var clip_name_label: Label = %ClipNameLbl
@onready var clip_start_label: Label = %ClipStartLbl
@onready var clip_duration_label: Label = %ClipDurationLbl
@onready var clip_color_picker: ColorPickerButton = %ClipColorPicker

var current_clip: ClipData = null

var hub:SequencerHub

func set_hub(h:SequencerHub) -> void:
	hub = h
	hub.subscribe(self, _on_hub_event, "clip.")
	
func _ready() -> void:
	clip_color_picker.connect("color_changed", Callable(self, "_on_color_changed"))
	show_for_clip(null)

func _on_hub_event(topic: String, data) -> void:
	match topic:
		"clip.update":
			show_for_clip(data)
		"clip.property.start.changed":
			show_for_clip(data)
			
func show_for_clip(clip: ClipData) -> void:
	current_clip = clip
	if clip == null:
		clip_name_label.text = "- (none selected) -"
		clip_start_label.text = ""
		clip_duration_label.text = ""
		#clip_color_picker.editable = false
	else:
		clip_name_label.text = "Name: %s" % clip.name
		clip_start_label.text = "Start: %.2fs" % clip.start
		clip_duration_label.text = "Duration: %.2fs" % clip.duration
		clip_color_picker.color = clip.color
		queue_redraw()
		#clip_color_picker.editable = true

func _on_color_changed(new_color: Color) -> void:
	if current_clip == null:
		return
	current_clip.color = new_color
	print("✅ Updated clip color:", new_color)
