extends Node
class_name AutosaveService

signal autosaved(path:String)
signal autoloaded(path:String)

@export var enabled := true
@export var interval_sec := 300.0
@export var autosave_path := "user://sequencer_autosave.json"

var sequence: Sequence
var _timer := 0.0
var _dirty := false

func _ready() -> void:
	set_process(true)

func mark_dirty() -> void:
	_dirty = true

func _process(delta: float) -> void:
	if not enabled or sequence == null:
		return

	_timer += delta
	if _timer >= interval_sec and _dirty:
		save()
		_timer = 0.0

func save() -> bool:
	if not sequence: return false
	
	var payload := {
		"version": 1,
		"sequence": sequence.to_dict()
	}
	
	var f = FileAccess.open(autosave_path, FileAccess.WRITE)
	if f == null:
		push_error("Autosave: cannot open for write: %s" % autosave_path)
		return false
		
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	emit_signal("autosaved", autosave_path)
	return true

func load_autosave() -> bool:
	if not FileAccess.file_exists(autosave_path):
		return false
	var f = FileAccess.open(autosave_path, FileAccess.READ)
	if not f: return false
	var txt = f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY or not data.has("sequence"):
		push_error("Autosave: Load found invalid file format")
		return false
		
	sequence.from_dict(data["sequence"])
	emit_signal("autoloaded", autosave_path)
	return true
