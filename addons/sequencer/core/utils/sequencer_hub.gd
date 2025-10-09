@tool
extends Node
class_name SequencerHub

## -------------------------------------------------------------------
## SequencerHub — lightweight message/event bus for the Sequencer suite
## -------------------------------------------------------------------
## • publish(topic:String, data:any)      → broadcast an event
## • subscribe(target:Object, callback:Callable, filter_prefix:String="")
##       → listen to any event, optionally filtered by prefix
## Example topics: "clip.selected", "clip.property.start.changed",
##                 "timeline.play", "track.muted", "ui.refresh"

signal message(topic: String, data)

var log_enabled := true
var event_log:Array = []
var log_limit := 200

func publish(topic:String, data = null) -> void:
	if log_enabled:
		event_log.append({"t": Time.get_unix_time_from_system(), "topic": topic, "data": str(data)})
		if event_log.size() > log_limit:
			event_log.pop_front()
	emit_signal("message", topic, data)
	
func subscribe(target:Object, callback:Callable, filter_prefix:String = "") -> void:
	var wrapper := func(topic:String, data):
		if filter_prefix == "" or topic.begins_with(filter_prefix):
			if is_instance_valid(target):
				callback.call(topic, data)
	connect("message", wrapper)

func dump_recent(count := 10) -> void:
	var slice = event_log.slice(max(0, event_log.size() - count), event_log.size())
	for e in slice:
		print("[%s] %s -> %s" % [Time.get_datetime_string_from_unix_time(e.t), e.topic, str(e.data)])

func clear_log() -> void:
	event_log.clear()
