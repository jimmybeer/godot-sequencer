@tool
extends Control

var clip_data
var px_per_second := 100.0
var scroll_x := 0.0

func init_from_clip(clip: Resource, _px: float, _scroll: float):
	clip_data = clip
	px_per_second = _px
	scroll_x = _scroll

func _ready() -> void:
	update_geometry(px_per_second, scroll_x)

func update_geometry(_px: float, _scroll: float):
	px_per_second = _px
	scroll_x = _scroll

	var x = clip_data.start * px_per_second - scroll_x
	var w = clip_data.duration * px_per_second

	# Use deferred call so anchors don't override immediately
	set_deferred("position", Vector2(x, 0))
	set_deferred("size", Vector2(w, get_parent().size.y))
	
	queue_redraw()

func _draw():
	var rect = Rect2(Vector2.ZERO, size)

	# Filled rectangle
	draw_rect(rect, Color(0.25, 0.6, 0.9, 0.9))

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
