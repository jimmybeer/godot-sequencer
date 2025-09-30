@tool
extends Control

@export var track_name: String = "Track"
@export var px_per_second := 100.0
@export var scroll_x := 0.0

var clips: Array = []   # will hold ClipView instances

@onready var clips_layer = %ClipsLayer
func _ready():
	print("TrackView ready, clips_layer = ", $ClipsLayer)
	
func set_clips(new_clips: Array):
	# Remove old
	for c in clips:
		c.queue_free()
	clips.clear()

	# Add new
	for clip in new_clips:
		var cv = preload("res://addons/sequencer/editor/ClipView.tscn").instantiate()
		cv.init_from_clip(clip, px_per_second, scroll_x)
		clips_layer.add_child(cv)
		clips.append(cv)

func update_view(px_per_sec: float, scroll: float):
	px_per_second = px_per_sec
	scroll_x = scroll
	for cv in clips:
		cv.update_geometry(px_per_second, scroll_x)
