@tool
extends Control

@export var track_name: String = "Track"

var clips: Array = []   # will hold ClipView instances
@onready var clips_layer = %ClipsLayer
	
func set_clips(new_clips: Array):
	# Remove old
	for c in clips:
		c.queue_free()
	clips.clear()

	# Add new
	for clip in new_clips:
		var cv = preload("res://addons/sequencer/editor/ClipView.tscn").instantiate()
		clips_layer.add_child(cv)
		cv.init_from_clip(clip, 100.0, 0.0)
		clips.append(cv)

func update_view(pxps: float, scroll: float):
	for cv in clips:
		cv.update_geometry(pxps, scroll)
