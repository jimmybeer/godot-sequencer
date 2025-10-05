extends Resource
class_name ClipData

@export var name:String = "New Clip"
@export var start:float = 0.0 # in seconds
@export var duration:float = 1.0 # in seconds
@export var color:Color = Color(0.25, 0.6, 0.9, 0.9) # default blue tone

var track:TrackData = null
var clip_view:ClipView = null

func to_dict() -> Dictionary:
	return {
		"name": name,
		"start": start,
		"duration": duration,
		"color": [color.r, color.g, color.b, color.a],
	}

func from_dict(data:Dictionary) -> ClipData:
	name = data.get("name", name)
	start = data.get("start", start)
	duration = data.get("duration", duration)
	if data.has("color"):
		var arr = data["color"]
		if typeof(arr) == TYPE_ARRAY and arr.size() >= 3:
			color = Color(arr[0], arr[1], arr[2], arr[3] if arr.size() > 3 else 1.0)
	validate()
	return self

func validate() -> void:
	if duration < 0.0:
		duration = 1.0
	if start < 0.0:
		start = 0.0
