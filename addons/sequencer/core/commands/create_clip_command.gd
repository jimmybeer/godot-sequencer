extends ICommand
class_name CreateClipCommand

var track:TrackData	
var clip:ClipData
var start:float
var duration:float
var name:String
var index_when_added: int = -1

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
	
	#Append to model
	index_when_added = track.clips.size()
	track.clips.append(clip)
	# Once the model is updated, Sequence Dock auto refreshes the Track View -> Clip View appears

func undo() -> void:
	if clip == null:
		return
	
	track.clips.erase(clip)
