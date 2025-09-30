extends Resource
class_name Clip

@export var name:String = "New Clip"
@export var start:float = 0.0 # in seconds
@export var duration:float = 1.0 # in seconds

func to_dict() -> Dictionary:
	return {
		"name": name,
		"start": start,
		"duration": duration,
	}

func from_dict(data:Dictionary) -> Clip:
	name = data.get("name", name)
	start = data.get("start", start)
	duration = data.get("duration", duration)
	return self
