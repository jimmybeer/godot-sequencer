extends ICommand
class_name CreateClipCommand

var track:TrackData	
var clip:ClipData
var start:float
var duration:float
var name:String

func _init(_track:TrackData, _start:float, _duration:float, _name:String = "New Clip") -> void:
	track = _track
	start = _start
	duration = _duration
	name = _name

func execute():
	# Create the clip the first time we run
	if clip == null:
		clip = preload("res://addons/sequencer/core/model/clip_data.gd").new()
		clip.name = name
		clip.start = start
		clip.duration = duration
		clip.track = track
	
	#Append to model
	track.add_clip(clip)
	# Once the model is updated, Sequence Dock auto refreshes the Track View -> Clip View appears

func undo() -> void:
	if clip == null:
		return
	
	track.clips.erase(clip)
