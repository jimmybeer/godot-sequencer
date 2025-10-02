extends ICommand
class_name DeleteClipCommand

var track:TrackData
var clip:ClipData
var index:int

func _init(_track:TrackData, _clip:ClipData) -> void:
	track = _track
	clip = _clip
	index = track.clips.find(clip)

func execute() -> void:
	if clip in track.clips:
		track.clips.erase(clip)

func undo() -> void:
	if clip == null:
		return
		
	# Put it back at its old position
	if index < 0 or index > track.clips.size():
		track.clips.append(clip)
	else:
		track.clips.insert(index, clip)
		
