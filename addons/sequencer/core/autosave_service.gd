extends Node
class_name AutosaveService

@export var interval_sec := 60.0
@export var autosave_path := "user://sequencer_autosave.json"

var clock:Node
var elapsed := 0.0

func _init() -> void:
	pass

func _process(delta) -> void:
	elapsed += delta
	if elapsed >= interval_sec:
		elapsed = 0.0
		save()

func save() -> void:
	if not clock: return
	var f = FileAccess.open(autosave_path, FileAccess.WRITE)
	
	if f:
		var data = clock.to_dict()
		f.store_string(JSON.stringify(data, " "))
		f.close()
		print("[Autosave] Saved to ", autosave_path)

func load_autosave() -> bool:
	if not FileAccess.file_exists(autosave_path):
		return false
	
	var f = FileAccess.open(autosave_path, FileAccess.READ)
	if not f: return false
	
	var text = f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		clock.from_dict(data)
		print("[Autosave] Loaded from ", autosave_path)
		return true
	return false
