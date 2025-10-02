@tool
extends Control
class_name TrackView

signal clip_clicked(clip_view: ClipView, shift: bool)
signal clip_drag_preview(cv: ClipView, new_start: float)
signal clip_drag_finished(cv: ClipView, old_start: float, new_start: float)

@onready var clips_layer:Control = %ClipsLayer

@export var track_name: String = "Track"

var track_data:TrackData
var clip_view_by_model: Dictionary = {}
var px_per_second: float = 100.0
var scroll_x: float = 0.0

func bind_to_model(track:TrackData) -> void:
	track_data = track
	refresh_from_model()

func refresh_from_model() -> void:
	# Remove ClipViews whose ClipData is gone
	for clip in clip_view_by_model.keys():
		if not track_data.clips.has(clip):
			var cv: ClipView = clip_view_by_model[clip]
			if is_instance_valid(cv):
				cv.queue_free()
			clip_view_by_model.erase(clip)

	# Ensure every ClipData has a ClipView
	for clip in track_data.clips:
		if not clip_view_by_model.has(clip):
			var cv: ClipView = preload("res://addons/sequencer/editor/ClipView.tscn").instantiate()
			clips_layer.add_child(cv)
			cv.bind_to_model(clip, px_per_second, scroll_x)
			cv.clip_clicked.connect(_on_clip_clicked)
			cv.clip_drag_preview.connect(_on_clip_drag_preview)
			cv.clip_drag_finished.connect(_on_clip_drag_finished)
			clip_view_by_model[clip] = cv
		else:
			clip_view_by_model[clip].update_geometry(px_per_second, scroll_x)

func update_view(pxps: float, scroll: float):
	px_per_second = pxps
	scroll_x = scroll
	for cv in clip_view_by_model.values():
		cv.update_geometry(px_per_second, scroll)

func get_all_clips() -> Array:
	return clip_view_by_model.values()

func clear_selection() -> void:
	for cv in clip_view_by_model.values():
		cv.selected = false
		
func get_selected_clips() -> Array[ClipView]:
	var out:Array[ClipView] = []
	for cv in clip_view_by_model.values():
		if cv.selected:
			out.append(cv)
	return out

func _on_clip_clicked(cv:ClipView, shift:bool) -> void:
	emit_signal("clip_clicked", cv, shift)

func _on_clip_drag_preview(cv: ClipView, new_start: float):
	# Just preview visually (don't mutate model!)
	cv.clip_data.start = new_start
	cv.update_geometry(px_per_second, scroll_x)
	emit_signal("clip_drag_preview", cv, new_start)

func _on_clip_drag_finished(cv: ClipView, old_start: float, new_start: float):
	emit_signal("clip_drag_finished", cv, old_start, new_start)
