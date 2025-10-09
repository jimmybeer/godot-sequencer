@tool
extends Control
class_name SequenceControls

@onready var clip_name_label: Label = %ClipNameLbl
@onready var clip_start_label: Label = %ClipStartLbl
@onready var clip_duration_label: Label = %ClipDurationLbl
@onready var clip_color_picker: ColorPickerButton = %ClipColorPicker

var current_clip: ClipData = null

func _ready() -> void:
	print("READY")
	clip_color_picker.connect("color_changed", Callable(self, "_on_color_changed"))
	update_clip_info(null)

func update_clip_info(clip: ClipData) -> void:
	current_clip = clip
	if(clip != null):print ("clips = " + str(clip.name))
	if clip == null:
		print("A clip_name_label = " + str(clip_name_label) + " = " + str(clip_name_label.text))
		clip_name_label.text = "- (none selected) -"
		print("B clip_name_label = " + str(clip_name_label) + " = " + str(clip_name_label.text))
		clip_start_label.text = ""
		clip_duration_label.text = ""
		#clip_color_picker.editable = false
	else:
		print("Rename")
		print("C clip_name_label = " + str(clip_name_label) + " = " + str(clip_name_label.text))
		clip_name_label.text = "Name: %s" % clip.name
		print("D clip_name_label = " + str(clip_name_label) + " = " + str(clip_name_label.text))
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
