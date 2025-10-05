extends Resource
class_name TrackData

@export var name:String = "New Track"
@export var clips:Array[ClipData] = []

# Ensure a proposed resize stays within legal bounds
# (no overlap, not <0, not <min_dur, and no "sliding" when hitting limits)
const MIN_DURATION := 0.1

func add_clip(c:ClipData) -> void:
	if not clips.has(c):
		clips.append(c)
		c.track = self
		
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
			clip.track = self
			clips.append(clip)
	
	return self

func get_active_clip(playhead_time:float) -> ClipData:
	var res:ClipData = null
	for c:ClipData in clips:
		if playhead_time >= c.start and playhead_time < (c.start + c.duration):
			c.clip_view.active = true
			res = c
		else:
			c.clip_view.active = false
			
	return res

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

# TrackData.gd

func _sorted_others(exclude: ClipData) -> Array[ClipData]:
	var arr: Array[ClipData] = []
	for c in clips:
		if c != exclude:
			arr.append(c)
	# Sort by start time
	arr.sort_custom(func(a, b): return a.start < b.start)
	return arr

# Returns a dict:
# { "start": <legal_start>, "ok": true|false }
# - ok=true  : proposed start fits without overlap
# - ok=false : adjusted to nearest legal boundary (no overlap)
func find_legal_start(clip: ClipData, proposed_start: float) -> Dictionary:
	var dur := max(0.0, clip.duration)
	var others := _sorted_others(clip)

	var best_start := 0.0
	var best_dist := INF
	var ok := false

	var cursor := 0.0  # left boundary of the current free region (time >= 0)
	for c in others:
		var gap_start := cursor
		var gap_end := c.start
		# does this gap fit the clip?
		if gap_end - gap_start >= dur:
			var min_s := gap_start
			var max_s:float = gap_end - dur   # inclusive
			# proposed fits inside this allowed-start interval?
			if proposed_start >= min_s and proposed_start <= max_s:
				return {"start": proposed_start, "ok": true}
			# otherwise, record nearest boundary of this allowed-start interval
			if proposed_start < min_s:
				var d := min_s - proposed_start
				if d < best_dist:
					best_dist = d
					best_start = min_s
			else:
				# proposed_start > max_s
				var d2 := proposed_start - max_s
				if d2 < best_dist:
					best_dist = d2
					best_start = max_s
		# move cursor to the end of this clip's interval
		cursor = max(cursor, c.start + c.duration)

	# Tail gap: [cursor, +INF)
	# Any start >= cursor is legal because there's nothing after
	if proposed_start >= cursor:
		return {"start": proposed_start, "ok": true}

	# If proposed is left of tail gap, nearest legal in tail is cursor
	var dist_tail := abs(cursor - proposed_start)
	if dist_tail < best_dist:
		best_start = cursor
		best_dist = dist_tail

	return {"start": best_start, "ok": false}
	
# Ensure a proposed resize stays within legal bounds (no overlap, not <0)
func find_legal_resize(clip: ClipData, proposed_start: float, proposed_duration: float) -> Dictionary:
	var others := _sorted_others(clip)
	var start := proposed_start
	var dur := proposed_duration

	# 1️⃣ Clamp minimum duration
	if dur < MIN_DURATION:
		# Don't let it shrink below min; keep the stationary edge fixed.
		if start > clip.start:
			# Left handle dragged right — fix start back, clamp duration
			start = clip.start + clip.duration - MIN_DURATION
		else:
			# Right handle dragged left — fix start, clamp duration
			start = clip.start
		dur = MIN_DURATION

	# 2️⃣ Clamp against zero
	if start < 0.0:
		dur += start  # reduce duration by the amount it would go negative
		start = 0.0
		dur = max(MIN_DURATION, dur)

	# 3️⃣ Clamp against left neighbour
	for i in range(others.size()):
		var c = others[i]
		if c.start < clip.start:
			var right_edge:float = c.start + c.duration
			if start < right_edge:
				# Move start to just after neighbour, shrink dur if needed
				var overlap:float = right_edge - start
				start = right_edge
				dur = max(MIN_DURATION, dur - overlap)
			break

	# 4️⃣ Clamp against right neighbour
	for i in range(others.size()):
		var c = others[i]
		if c.start > clip.start:
			var right_limit:float = c.start
			if start + dur > right_limit:
				dur = max(MIN_DURATION, right_limit - start)
			break

	return {
		"start": start,
		"duration": dur,
	}
