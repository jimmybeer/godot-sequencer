@tool
extends HBoxContainer
class_name ClipPropertiesBar

signal clip_updated(clip:ClipData, field:String, value:float)

var clip:ClipData

@onready var name_label:Label = %NameLbl
@onready var start_field:LineEdit = %StartField
@onready var duration_field:LineEdit = %DurationField

func show_for_clip(c:ClipData) -> void:
	clip = c
	name_label.text = c.name
	start_field.text = str(snapped(c.start, 0.01))
	duration_field.text = str(snapped(c.duration, 0.01))
	visible = true

func hide_bar() -> void:
	clip = null
	visible = false

func _read() -> void:
	visible = false
	start_field.text_submitted.connect(_on_start_changed)
	duration_field.text_submitted.connect(_on_duration_changed)

func _on_start_changed(txt:String) -> void:
	if clip == null:
		return
	var val = float(txt)
	emit_signal("clip_updated", clip, "start", val)

func _on_duration_changed(txt:String) -> void:
	if clip == null:
		return
	var val = float(txt)
	emit_signal("clip_updated", clip, "duration", val)
