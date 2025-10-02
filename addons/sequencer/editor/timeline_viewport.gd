extends Node
class_name TimelineViewport

signal viewport_changed(px_per_second:float, scroll_x:float)

# pixels per second (zoom level)
var px_per_second:float = 100.0:
	set(value):
		px_per_second = clamp(value, 10.0, 4000.0)
		emit_signal("viewport_changed", px_per_second, scroll_x)
	get:
		return px_per_second

# horizontal pan offset in pixels
var scroll_x := 0.0:
	set(value):
		scroll_x = max(0.0, value)
		emit_signal("viewport_changed", px_per_second, scroll_x)
	get:
		return scroll_x

# Reserve space for label on the left
var left_margin:float = 100.0
