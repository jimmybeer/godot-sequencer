extends Resource
class_name ClipData

@export var name:String = "New Clip"
@export var start:float = 0.0 # in seconds
@export var duration:float = 1.0 # in seconds

var track:TrackData = null

func to_dict() -> Dictionary:
	return {
		"name": name,
		"start": start,
		"duration": duration,
	}

func from_dict(data:Dictionary) -> ClipData:
	name = data.get("name", name)
	start = data.get("start", start)
	duration = data.get("duration", duration)
	validate()
	return self

func validate() -> void:
	if duration < 0.0:
		duration = 0.0
	if start < 0.0:
		start = 0.0
