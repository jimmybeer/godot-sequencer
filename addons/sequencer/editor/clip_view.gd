@tool
extends Control
class_name ClipView

signal clip_clicked(cv: ClipView, shift: bool)
signal clip_drag_preview(cv: ClipView, new_start: float)
signal clip_drag_finished(cv: ClipView, old_start: float, new_start: float)
signal clip_resize_preview(cv: ClipView, edge: String, new_start: float, new_duration: float)
signal clip_resize_finished(cv: ClipView, edge: String,old_start: float, old_duration: float,new_start: float, new_duration: float)

var clip_data:ClipData

var selected:bool = false:
	set(v):
		selected = v
		queue_redraw()
	get:
		return selected

var px_per_second: float = 100.0
var scroll_x:float = 0.0

var dragging:bool = false
var resizing_left := false
var resizing_right := false

var drag_origin_start:float = 0.0
var drag_origin_mouse_x:float = 0.0

var resize_origin_mouse_x := 0.0
var resize_origin_start := 0.0
var resize_origin_duration := 0.0

const MOVE_HANDLE_W:float = 8.0
const RESIZE_HANDLE_W:float = 6.0

func bind_to_model(clip: ClipData, _px: float, _scroll: float):
	clip_data = clip
	update_geometry(_px, _scroll)

func update_geometry(_px_per_second: float, _scroll_x: float, start_override: float = -INF, dur_override: float = -INF):
	if clip_data == null:
		return
		
	var start_val := start_override if (start_override != -INF) else clip_data.start
	var dur_val := dur_override if (dur_override != -INF) else clip_data.duration

	px_per_second = _px_per_second
	scroll_x = _scroll_x
	
	var x = start_val * px_per_second - scroll_x
	var w = dur_val * px_per_second

	# Use deferred call so anchors don't override immediately
	set_deferred("position", Vector2(x, 0))
	set_deferred("size", Vector2(w, get_parent().size.y))
	
	queue_redraw()

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	# Fill color depends on selection
	var fill = Color(0.4, 0.7, 1.0, 0.9) if selected else Color(0.25, 0.6, 0.9, 0.9)

	# Filled rectangle
	draw_rect(rect, fill)

	# Border
	draw_rect(rect, Color.BLACK, false, 2)

	# Clip label text
	var font = get_theme_default_font()
	var fs = get_theme_default_font_size()
	draw_string(
		font,
		Vector2(6, size.y/2 + fs/2 - 2),   # vertically centered
		clip_data.name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		Color.WHITE
	)
	
	#Draw handle if selected
	if selected:
		var resize_col := Color(1, 1, 1, 0.4)
		var move_col := Color(1, 1, 1, 0.2)
		var mw = MOVE_HANDLE_W
		var rw := RESIZE_HANDLE_W
		var h = size.y
		
		# Left resize handle
		draw_rect(Rect2(Vector2(0, 0), Vector2(rw, h)), resize_col)
		draw_line(Vector2(rw, 0), Vector2(rw, h), Color(1, 1, 1, 0.5))
		
		# Right resize handle
		draw_rect(Rect2(Vector2(size.x - rw, 0), Vector2(rw, h)), resize_col)
		draw_line(Vector2(size.x - rw, 0), Vector2(size.x - rw, h), Color(1, 1, 1, 0.5))
		
		#draw_rect(Rect2(Vector2(handle_x, 0), Vector2(handle_w, handle_h)), Color(1, 0.3, 0.3, 0.7))
		# Move (centre) handle
		var mx:float = size.x / 2 - mw / 2
		draw_rect(Rect2(Vector2(mx, 0), Vector2(mw, h)), move_col)

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not selected:
				emit_signal("clip_clicked", self, event.shift_pressed)
			else:
				var hit := _get_hit_handle(event.position)
				
				if hit == "move":
					dragging = true
					drag_origin_mouse_x = event.global_position.x
					drag_origin_start = clip_data.start
					accept_event()
					return

				if hit == "left" or hit == "right":
					resize_origin_mouse_x = event.global_position.x
					resize_origin_start = clip_data.start
					resize_origin_duration = clip_data.duration
					resizing_left = hit == "left"
					resizing_right = hit == "right"
					accept_event()
					return
		else:
			# Mouse released
			if dragging:
				dragging = false
				var dx = event.global_position.x - drag_origin_mouse_x
				var new_start = max(0.0, drag_origin_start + dx / px_per_second)
				emit_signal("clip_drag_finished", self, drag_origin_start, new_start)

			elif resizing_left or resizing_right:
				var edge := ( "left" if resizing_left else "right")
				var dx:float = event.global_position.x - resize_origin_mouse_x
				var new_start := resize_origin_start
				var new_dur := resize_origin_duration

				if resizing_left:
					new_start = resize_origin_start + dx / px_per_second
					new_dur = resize_origin_duration - dx / px_per_second
				elif resizing_right:
					new_dur = resize_origin_duration + dx / px_per_second
					
				resizing_left = false
				resizing_right = false
				emit_signal("clip_resize_finished", self, edge, resize_origin_start, resize_origin_duration, new_start, new_dur)
				accept_event()
				
	elif event is InputEventMouseMotion:
		if dragging:
			var dx = event.global_position.x - drag_origin_mouse_x
			var new_start = max(0.0, drag_origin_start + (dx / px_per_second))
			emit_signal("clip_drag_preview", self, new_start)

		# --- Resize preview ---
		elif resizing_left or resizing_right:
			var dx:float = event.global_position.x - resize_origin_mouse_x
			var new_start := resize_origin_start
			var new_dur := resize_origin_duration

			if resizing_left:
				new_start = resize_origin_start + dx / px_per_second
				new_dur = resize_origin_duration - dx / px_per_second
				new_dur = max(0.01, new_dur)

			elif resizing_right:
				new_dur = resize_origin_duration + dx / px_per_second
				new_dur = max(0.01, new_dur)

			emit_signal("clip_resize_preview", self, "left" if resizing_left else "right", new_start, new_dur)
			accept_event()
			

func _get_hit_handle(local_pos: Vector2) -> String:
	# returns "left", "right", "move", or ""
	var left_rect  := Rect2(Vector2(0, 0), Vector2(RESIZE_HANDLE_W, size.y))
	var right_rect := Rect2(Vector2(size.x - RESIZE_HANDLE_W, 0), Vector2(RESIZE_HANDLE_W, size.y))
	var move_rect  := Rect2(Vector2(size.x/2 - MOVE_HANDLE_W/2, 0), Vector2(MOVE_HANDLE_W, size.y))

	if left_rect.has_point(local_pos):
		return "left"
	elif right_rect.has_point(local_pos):
		return "right"
	elif move_rect.has_point(local_pos):
		return "move"
	return ""
