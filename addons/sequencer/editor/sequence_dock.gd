@tool
extends Control
class_name SequenceDock

const MIN_DOCK_HEIGHT := 200  # or whatever feels comfortable
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			call_deferred("_ensure_min_dock_height")
			
func _ensure_min_dock_height() -> void:
	custom_minimum_size.y = max(custom_minimum_size.y, MIN_DOCK_HEIGHT)
			
# ------------------------------
# UI references
# ------------------------------
@onready var play_btn:Button = %PlayBtn
@onready var pause_btn:Button = %PauseBtn
@onready var stop_btn:Button = %StopBtn
@onready var time_label:Label = %TimeLabel
@onready var loop_check:CheckBox = %LoopCheck
@onready var fps_spin:SpinBox = %FpsSpin
@onready var in_field:LineEdit = %InField
@onready var out_field:LineEdit = %OutField

@onready var undo_btn:Button = %UndoBtn
@onready var redo_btn:Button = %RedoBtn
@onready var save_check := %SaveCheck
@onready var save_btn:Button = %SaveBtn
@onready var load_btn:Button = %LoadBtn

@onready var timeline:Control = %TimeLineView
@onready var tracks_vbox: VBoxContainer = %TracksVBox
@onready var labels_vbox: VBoxContainer = %TrackLabelsVBox

@onready var add_clip_btn:Button = %AddClipBtn
@onready var del_clip_btn:Button = %DelClipBtn

@onready var clip_bar:ClipPropertiesBar = %ClipPropertiesBar

# ------------------------------
# Core objects
# ------------------------------
@onready var command_bus := CommandBus.new()
@onready var autosave := AutosaveService.new(null)
var clock:Node
var viewport:TimelineViewport

var sequence:Sequence
# Maps between model and views
var track_view_by_model:Dictionary = {}
var label_by_model:Dictionary = {}

var last_selected_cv:ClipView = null

func _ready() -> void:
	sequence = load("res://addons/sequencer/core/model/Sequence.gd").new()
	
	clock = load("res://addons/sequencer/core/utils/timeline_clock.gd").new()
	add_child(clock)
	#add_child(autosave)
	#autosave.clock = clock
	clock.connect("time_changed", Callable(self, "_on_time_changed"))
	
	viewport = preload("res://addons/sequencer/editor/timeline_viewport.gd").new()
	add_child(viewport)
	
	if timeline.has_method("set_viewport"):
		timeline.set_viewport(viewport)
	viewport.viewport_changed.connect(_on_viewport_changed)
	
	load_mock_tracks()
	
	_on_viewport_changed(viewport.px_per_second, viewport.scroll_x)
	
	add_child(command_bus)
	command_bus.stack_changed.connect(func() :
		refresh_all_views_from_model()
		update_undo_redo_buttons()
		_update_clip_bar()
		)
	update_undo_redo_buttons()
	
	#UI wiring
	play_btn.pressed.connect(func(): clock.play())
	pause_btn.pressed.connect(func(): clock.pause())
	
	stop_btn.pressed.connect(func():
		var cmd := SetTimeCommand.new(clock, clock.t, max(0.0, float(in_field.text)), true)
		command_bus.push(cmd)
	)
	
	loop_check.toggled.connect(func(v): clock.loop = v)
	
	fps_spin.value_changed.connect(func(v):
		var cmd = SetFPSCommand.new(clock, clock.fps, int(v), fps_spin)
		command_bus.push(cmd)
	)
	
	in_field.text = str(clock.in_point)
	in_field.text_submitted.connect(func(txt):
		var cmd = SetPlatRangeCommand.new(clock,
			clock.in_point, clock.out_point, float(txt), clock.out_point, in_field, out_field)
		command_bus.push(cmd)
	)
	
	out_field.text = str(clock.out_point)
	out_field.text_submitted.connect(func(txt):
		var cmd = SetPlatRangeCommand.new(clock,
			clock.in_point, clock.out_point, clock.in_point, float(txt), in_field, out_field)
		command_bus.push(cmd)
	)
	
	add_clip_btn.pressed.connect(_on_add_clip_pressed)
	del_clip_btn.pressed.connect(_on_del_clip_pressed)
	
	undo_btn.pressed.connect(func(): command_bus.undo())
	redo_btn.pressed.connect(func(): command_bus.redo())
	
	save_check.button_pressed = true
	save_check.toggled.connect(func(v): autosave.enabled = v)
	
	save_btn.pressed.connect(func():
		autosave.save()
		)
	
	load_btn.pressed.connect(func():
		var ok = autosave.load_autosave()
		if ok:
			# Update GUI
			fps_spin.set_block_signals(true)
			in_field.set_block_signals(true)
			out_field.set_block_signals(true)
			fps_spin.value = clock.fps
			in_field.text = str(clock.in_point)
			out_field.text = str(clock.out_point)
			loop_check.button_pressed = clock.loop
			time_label.text = str(snapped(clock.t, 0.01)) + "s"
			fps_spin.set_block_signals(false)
			in_field.set_block_signals(false)
			out_field.set_block_signals(false)
			)
	
	clip_bar.clip_updated.connect(_on_clip_updated)

func _process(delta:float) -> void:
	if clock == null:
		return
	#Drive the clock and refresh the timeline
	clock._process(delta)
	#Cast to out TimelineView script and push time across
	if "set_time" in timeline:
		timeline.set_time(clock.t)

func _on_time_changed(t:float) -> void:
	time_label.text = str(snapped(t, 0.01)) + "s"

func _on_viewport_changed(pxps:float, scroll:float) -> void:
	for tv in track_view_by_model.values():
		tv.update_view(pxps, scroll)
	if timeline:
		timeline.queue_redraw()

func load_mock_tracks():
	# Example: make 2 tracks with dummy clips
	var clip_res = preload("res://addons/sequencer/core/model/clip_data.gd")
	var track_res = preload("res://addons/sequencer/core/model/track_data.gd")

	for i in 2:
		var track = track_res.new()
		track.name = "Track %d" % i

		var c1 = clip_res.new()
		c1.name = "Clip A"
		c1.start = 1.0+i
		c1.duration = 3.0
		c1.track = track

		var c2 = clip_res.new()
		c2.name = "Clip B"
		c2.start = 5.0+(i*3)
		c2.duration = 2.0
		c2.track = track

		track.clips.append(c1)
		track.clips.append(c2)

		sequence.tracks.append(track)
		_create_track_row_for(track)
		
func _create_track_row_for(track:TrackData) -> void:
	# Left header
	var label_row := Label.new()
	label_row.text = track.name
	label_row.custom_minimum_size = Vector2(100, 25)
	labels_vbox.add_child(label_row)
	label_by_model[track] = label_row
	
	# Right lane
	var tv:TrackView = preload("res://addons/sequencer/editor/TrackView.tscn").instantiate()
	tv.custom_minimum_size = Vector2(0, 25)
	tracks_vbox.add_child(tv)
	tv.bind_to_model(track)    
	tv.clip_clicked.connect(_on_tv_clip_clicked) 
	tv.clip_drag_preview.connect(_on_clip_drag_preview)
	tv.clip_drag_finished.connect(_on_clip_drag_finished)
	tv.clip_resize_preview.connect(_on_tv_clip_resize_preview)
	tv.clip_resize_finished.connect(_on_tv_clip_resize_finished)
	track_view_by_model[track] = tv
	tv.update_view(viewport.px_per_second, viewport.scroll_x)
	
func refresh_all_views_from_model() -> void:
	# Reuse existing rows when possible; create missing; remove extra
	var wanted:Array[TrackData] = sequence.tracks

	# Remove views for tracks no longer present
	for t in track_view_by_model.keys():
		if not wanted.has(t):
			track_view_by_model[t].queue_free()
			label_by_model[t].queue_free()
			track_view_by_model.erase(t)
			label_by_model.erase(t)

	# Ensure a row for each track and refresh it
	for t in wanted:
		if not track_view_by_model.has(t):
			_create_track_row_for(t)
		track_view_by_model[t].refresh_from_model()
		
func clear_all_selection() -> void:
	for tv in track_view_by_model.values():
		tv.clear_selection()
	last_selected_cv = null
	_update_clip_bar()  # hide it
	
func select_clip(cv: ClipView, additive: bool) -> void:
	if not additive:
		clear_all_selection()
		cv.selected = true
	else:
		# SHIFT toggles
		cv.selected = !cv.selected
		# if it was turned off and it was last_selected_view, clear reference
		if not cv.selected and last_selected_cv == cv:
			last_selected_cv = null

	# If selected now, mark as last
	if cv.selected:
		last_selected_cv = cv

	_update_clip_bar()
	
func _on_add_clip_pressed() -> void:
	if sequence.tracks.is_empty():
		return

	var track:TrackData = sequence.tracks[0] # later current/selected track
	var CreateCmd = preload("res://addons/sequencer/core/commands/create_clip_command.gd")
	var cmd = CreateCmd.new(track, 2.0, 1.5, "New Clip")
	command_bus.push(cmd)
	
func _on_del_clip_pressed() -> void:
	var cmds: Array[ICommand] = []
	
	for t in sequence.tracks:
		var tv:TrackView = track_view_by_model.get(t, null)
		if tv == null: continue
		for cv in tv.get_selected_clips():
			var DeleteCmd = preload("res://addons/sequencer/core/commands/delete_clip_command.gd")
			cmds.append(DeleteCmd.new(t, cv.clip_data))
	if cmds.is_empty(): return
	var BatchCmd = preload("res://addons/sequencer/core/commands/batch_command.gd")
	command_bus.push(BatchCmd.new(cmds, "Delete %d clip(s)" % cmds.size()))

func update_undo_redo_buttons() -> void:
	undo_btn.disabled = command_bus.undo_stack.is_empty()
	redo_btn.disabled = command_bus.redo_stack.is_empty()

func _on_clip_drag_preview(cv: ClipView, new_start:float) -> void:
	if last_selected_cv == cv and is_instance_valid(last_selected_cv):
		# Update bar live with temporary value
		clip_bar.start_field.text = str(snapped(new_start, 0.01))

func _on_clip_drag_finished(cv: ClipView, old_start: float, new_start: float) -> void:
	if cv.clip_data == null:
		return
	var cmd = MoveClipCommand.new(cv.clip_data, old_start, new_start)
	command_bus.push(cmd)
	
func _on_tv_clip_resize_preview(cv: ClipView, edge: String, new_start: float, new_dur: float) -> void:
	var td := cv.clip_data.track
	if td:
		var res := td.find_legal_resize(cv.clip_data, new_start, new_dur)
		var legal_start:float = res["start"]
		var legal_dur:float = res["duration"]
			
		cv.update_geometry(viewport.px_per_second, viewport.scroll_x, legal_start, legal_dur)
	
		if last_selected_cv == cv and is_instance_valid(last_selected_cv):
			# Update bar live with temporary value
			clip_bar.duration_field.text = str(snapped(legal_dur, 0.01))
			clip_bar.start_field.text = str(snapped(legal_start, 0.01))
			
func _on_tv_clip_resize_finished(cv: ClipView, edge: String, old_start: float, old_dur: float, new_start: float, new_dur: float) -> void:
	var td := cv.clip_data.track
	if not td: return
	
	var res := td.find_legal_resize(cv.clip_data, new_start, new_dur)
	var final_start:float = res["start"]
	var final_dur:float = res["duration"]
	
	if abs(final_dur - old_dur) > 0.0001 or abs(final_start - old_start) > 0.0001:
		var ResizeCmd := preload("res://addons/sequencer/core/commands/resize_clip_command.gd")
		command_bus.push(ResizeCmd.new(cv.clip_data, old_start, old_dur, final_start, final_dur))

func _on_tv_clip_clicked(cv: ClipView, shift: bool) -> void:
	select_clip(cv, shift)

func _on_tv_empty_clicked() -> void:
	clear_all_selection()

func _update_clip_bar() -> void:
	if last_selected_cv == null or not is_instance_valid(last_selected_cv):
		clip_bar.hide_bar()
		return
		
	if not last_selected_cv.selected:
		clip_bar.hide_bar()
		last_selected_cv = null
		return
	
	clip_bar.show_for_clip(last_selected_cv.clip_data)

func _on_tracks_vbox_gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		clear_all_selection()

func _on_clip_updated(clip: ClipData, field: String, value: float):
	if field == "start":
		var MoveCmd = preload("res://addons/sequencer/core/commands/move_clip_command.gd")
		command_bus.push(MoveCmd.new(clip, clip.start, value))

	elif field == "duration":
		var ResizeCmd = preload("res://addons/sequencer/core/commands/resize_clip_command.gd")
		command_bus.push(ResizeCmd.new(clip, clip.start, clip.duration, clip.start, value))
