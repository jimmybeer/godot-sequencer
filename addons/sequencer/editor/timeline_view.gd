@tool
extends Control

var vp:TimelineViewport
@export var fps := 30                # for frame-aware labels if you want
var time := 0.0

const EPS := 1e-7

func set_viewport(viewport:TimelineViewport) -> void:
	vp = viewport
	queue_redraw()

func set_time(s: float) -> void:
	time = max(0.0, s)
	queue_redraw()

func seconds_to_x(s: float) -> float:
	return s * vp.px_per_second - vp.scroll_x

func _draw() -> void:
	if vp == null:
		return
		
	var w := size.x
	var h := size.y
	
	#Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.12, 0.12))
	
	# Visible time range
	var start_s := max(0.0, vp.scroll_x / vp.px_per_second)
	var end_s := (vp.scroll_x + w) / vp.px_per_second
	
	# --- Dynamic tick interval ---
	# Base: try to keep ~80px between labeled ticks
	var min_px := 80.0
	var raw_step := min_px / vp.px_per_second
	var step := _choose_step(raw_step)
	
	# integer index range for majors
	var k_start := int(floor((start_s - EPS) / step))
	var k_end   := int(ceil((end_s + EPS) / step))
	
	# Draw major ticks + labels
	var last_x := -INF
	
	# MAJOR TICKS + LABELS
	for k in range(k_start, k_end + 1):
		var s := float(k) * step                       # exact tick time = k * step
		if s < 0.0: continue
		var x := seconds_to_x(s)          # compute x directly from (k * step)
		if x < -2.0 or x > w + 2.0:                     # outside with small tolerance
			continue
			
		# avoid drawing if it's on the same pixel column as previous major
		if abs(x - last_x) <= 1.0:
			continue
		
		# draw major line
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0.35, 0.35, 0.35), 1.0)
	
		# label (use decimals when step < 1s, optional timecode/framing)
		var label := _format_label(s, step, fps)
		var font := get_theme_default_font()
		var fs := get_theme_default_font_size()
		draw_string(font, Vector2(x + 3, fs + 2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)

		last_x = x
		#last_label = label
		
	# MINOR TICKS (no labels)
	var minors_per_major := 4
	var minor_step := step / float(minors_per_major)
	var m_start := int(floor((start_s - EPS) / minor_step))
	var m_end   := int(ceil((end_s + EPS) / minor_step))
	for j in range(m_start, m_end + 1):
		var sm := float(j) * minor_step
		# skip if this minor aligns with a major (within epsilon)
		if abs(fmod(sm, step)) < (minor_step * 0.5):
			continue
		var xm := seconds_to_x(sm)
		if xm >= 0.0 and xm <= w:
			draw_line(Vector2(xm, 0), Vector2(xm, h * 0.3), Color(0.25, 0.25, 0.25), 1.0)
	
	#Playhead
	var xp := seconds_to_x(time)
	if xp >= 0:
		draw_line(Vector2(xp, 0), Vector2(xp, h), Color(1.0, 0.2, 0.2), 2.0)

func _gui_input(event: InputEvent) -> void:
	if vp == null:
		return
	
	# Middle drag to pan
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		vp.scroll_x -= event.relative.x
		vp.scroll_x = max(0.0, vp.scroll_x)
		accept_event()
		
	# Wheel zoom, anchored at mouse
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position.x, 1.1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position.x, 1.0 / 1.1)
			accept_event()

func _zoom_at(mouse_x: float, factor:float) -> void:
	var pxps_old := vp.px_per_second
	var scroll_old := vp.scroll_x
	var local_x := clamp(mouse_x - vp.left_margin, 0.0, max(0.0, size.x - vp.left_margin))
	var t_under_mouse:float = (local_x + scroll_old) / pxps_old
	
	var pxps_new := clamp(pxps_old * factor, 10.0, 3800)
	var scroll_new:float = t_under_mouse * pxps_new - local_x
	
	vp.px_per_second = pxps_new
	vp.scroll_x = max(0.0, scroll_new)

# Pick a pleasant step from a nice set (prevents cramped labels)
func _choose_step(raw_step: float) -> float:
	var candidates = [0.01, 0.02, 0.05,
					  0.1, 0.25, 0.5,
					  1.0, 2.0, 5.0, 10.0, 15.0, 30.0,
					  60.0, 120.0, 300.0, 600.0]
	
	for c in candidates:
		if c + EPS >= raw_step:
			return c
	return candidates.back()

# Format labels with sensible precision so zoomed-in ticks don't repeat text
func _format_label(seconds: float, step: float, fps: int) -> String:
	# If you're very zoomed in, align labels to frames (feels "NLE-like")
	var frame_step:float = 1.0 / max(1, fps)
	if step <= frame_step + EPS:
		var total_frames := int(round(seconds * fps))
		var ss := int(total_frames / fps)
		var ff := int(total_frames % fps)
		return str(ss) + ":" + str(ff).pad_zeros(2)     # e.g., 12:07 (12s + 7 frames)
		
	# Otherwise show seconds with decimals based on step granularity
	var decimals := max(0, int(ceil(-log(step) / log(10.0))))  # number of decimal places implied by step
	decimals = clamp(decimals, 0, 3)                           # cap to 3dp for readability
	var snapped_seconds:float = round(seconds / step) * step        # align to the grid
	return str(snapped(snapped_seconds, pow(10.0, -decimals))) + "s"
