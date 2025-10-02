extends Resource
class_name TrackData

@export var name:String = "New Track"
@export var clips:Array[ClipData] = []

func to_dict() -> Dictionary:
	var clips_arr:Array = []
	
	for c in clips:
		clips_arr.append(c.to_dict())
	
	return {
		"name": name,
		"clips": clips_arr
	}

func from_dict(data:Dictionary) -> TrackData:
	name = data.get("name", name)
	clips.clear()
	
	if data.has("clips"):
		for cdict in data["clips"]:
			var clip = ClipData.new().from_dict(cdict)
			clips.append(clip)
	
	return self
