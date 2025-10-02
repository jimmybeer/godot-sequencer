@tool
extends Control
class_name ClipView

signal clip_clicked(cv: ClipView, shift: bool)
signal clip_drag_preview(cv: ClipView, new_start: float)
signal clip_drag_finished(cv: ClipView, old_start: float, new_start: float)

var clip_data:ClipData

var selected:bool = false:
	set(v):
		selected = v
		queue_redraw()
	get:
		return selected

var dragging:bool = false
var drag_origin_start:float = 0.0
var drag_origin_mouse_x:float = 0.0
var px_per_second: float = 100.0
var scroll_x:float = 0.0

const move_handle_width:float = 8.0

func bind_to_model(clip: ClipData, _px: float, _scroll: float):
	clip_data = clip
	update_geometry(_px, _scroll)

func update_geometry(_px_per_second: float, _scroll_x: float):
	if clip_data == null:
		return
		
	px_per_second = _px_per_second
	scroll_x = _scroll_x
	
	var x = clip_data.start * px_per_second - scroll_x
	var w = clip_data.duration * px_per_second

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
		var handle_w = move_handle_width
		var handle_h = size.y
		var handle_x = size.x/2 - handle_w/2
		draw_rect(Rect2(Vector2(handle_x, 0), Vector2(handle_w, handle_h)), Color(1, 0.3, 0.3, 0.7))

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not selected:
				emit_signal("clip_clicked", self, event.shift_pressed)
			else:
				#check if clicking handle
				var handle_w = move_handle_width
				var handle_x = size.x/2 - handle_w/2
				var handle_rect = Rect2(Vector2(handle_x, 0), Vector2(handle_w, size.y))
				if handle_rect.has_point(event.position):
					dragging = true
					drag_origin_start = clip_data.start
					drag_origin_mouse_x = event.global_position.x
					accept_event()
		else:
			# Mouse released
			if dragging:
				dragging = false
				var dx = event.global_position.x - drag_origin_mouse_x
				var new_start = max(0.0, drag_origin_start + dx / px_per_second)
				emit_signal("clip_drag_finished", self, drag_origin_start, new_start)
				
	elif event is InputEventMouseMotion and dragging:
		var dx = event.global_position.x - drag_origin_mouse_x
		var new_start = max(0.0, drag_origin_start + (dx / px_per_second))
		emit_signal("clip_drag_preview", self, new_start)
