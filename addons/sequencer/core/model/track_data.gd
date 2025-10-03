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

func get_non_overlap_range(clip: ClipData) -> Vector2:
	# Returns (min_start, max_start) where the clip can legally move
	var sorted = clips.duplicate()
	sorted.sort_custom(func(a, b): return a.start < b.start)

	var idx = sorted.find(clip)
	if idx == -1:
		return Vector2(0, INF)  # not in this track

	var min_start = 0.0
	var max_start = INF

	# clip can't go past the previous clip
	if idx > 0:
		var prev = sorted[idx - 1]
		min_start = prev.start + prev.duration

	# clip can't overlap the next clip
	if idx < sorted.size() - 1:
		var nxt = sorted[idx + 1]
		max_start = nxt.start - clip.duration

	return Vector2(min_start, max_start)
