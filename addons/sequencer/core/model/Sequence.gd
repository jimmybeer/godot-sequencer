extends Resource
class_name Sequence

@export var name:String = "New Sequence"
@export var fps:int = 30
@export var duration:float = 10.0
@export var tracks:Array[TrackData] = [] # array order == visual order

func to_dict() -> Dictionary:
	var tracks_arr:Array = []
	
	for t in tracks:
		tracks_arr.append(t.to_dict())
	
	return {
		"name": name,
		"fps": fps,
		"duration": duration,
		"tracks": tracks_arr,
	}

func from_dict(data:Dictionary) -> Sequence:
	name = data.get("name", name)
	fps = data.get("fps", fps)
	duration = data.get("duration", duration)
	
	tracks.clear()
	if data.has("tracks"):
		for tdict in data["tracks"]:
			var track = TrackData.new().from_dict(tdict)
			tracks.append(track)
	
	return self
