@tool
extends Control
class_name ClipView

signal clip_clicked(clip_view: Node, shift: bool)

var clip_data:ClipData

var selected:bool = false:
	set(v):
		selected = v
		queue_redraw()
	get:
		return selected

func bind_to_model(clip: ClipData, _px: float, _scroll: float):
	clip_data = clip
	update_geometry(_px, _scroll)

func update_geometry(px_per_second: float, scroll_x: float):
	if clip_data == null:
		return

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

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clip_clicked", self, event.shift_pressed)
