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

func _ready() -> void:
	visible = false
	start_field.text_submitted.connect(_on_start_changed)
	duration_field.text_submitted.connect(_on_duration_changed)

func _on_start_changed(txt:String) -> void:
	if clip == null:
		return
	var proposed := float(txt)

	if clip.track != null:
		var res := clip.track.find_legal_start(clip, proposed)
		var final_start:float = res["start"]

		if abs(final_start - clip.start) > 0.0001:
			var MoveCmd = preload("res://addons/sequencer/core/commands/move_clip_command.gd")
			clip_updated.emit(clip, "start", final_start)  # or push command from the dock
		# Re-sync the field to what actually applies
		start_field.text = str(snapped(final_start, 0.01))
	else:
		# No track backref; fall back to non-negative clamp
		var final := max(0.0, proposed)
		start_field.text = str(snapped(final, 0.01))

func _on_duration_changed(txt:String) -> void:
	if clip == null:
		return
	var val = float(txt)
	emit_signal("clip_updated", clip, "duration", val)
