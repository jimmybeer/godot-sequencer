extends Node
class_name AutosaveService

@export var interval_sec := 60.0
@export var autosave_path := "user://sequencer_autosave.json"

var sequence: Sequence

func _init(_sequence: Sequence):
	sequence = _sequence

func save():
	if not sequence: return
	var f = FileAccess.open(autosave_path, FileAccess.WRITE)
	if f:
		var data = sequence.to_dict()
		f.store_string(JSON.stringify(data, "  "))
		f.close()
		print("[Autosave] Saved sequence to ", autosave_path)

func load_autosave():
	if not FileAccess.file_exists(autosave_path):
		return false
	var f = FileAccess.open(autosave_path, FileAccess.READ)
	if not f: return false
	var txt = f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		sequence.from_dict(data)
		print("[Autosave] Loaded sequence from ", autosave_path)
		return true
	return false
