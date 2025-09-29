@tool
extends Control

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
@onready var save_btn:Button = %SaveBtn
@onready var load_btn:Button = %LoadBtn

@onready var timeline:Control = %TimeLineView

@onready var command_bus := CommandBus.new()
@onready var autosave := AutosaveService.new()

var clock:Node

func _ready() -> void:
	clock = load("res://addons/sequencer/core/timeline_clock.gd").new()
	add_child(clock)
	add_child(autosave)
	autosave.clock = clock
	clock.connect("time_changed", Callable(self, "_on_time_changed"))
	
	add_child(command_bus)
	command_bus.stack_changed.connect(update_undo_redo_buttons)
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
	
	undo_btn.pressed.connect(func(): command_bus.undo())
	redo_btn.pressed.connect(func(): command_bus.redo())
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

func _process(delta:float) -> void:
	#Drive the clock and refresh the timeline
	clock._process(delta)
	#Cast to out TimelineView script and push time across
	if "set_time" in timeline:
		timeline.set_time(clock.t)

func _on_time_changed(t:float) -> void:
	time_label.text = str(snapped(t, 0.01)) + "s"

func update_undo_redo_buttons() -> void:
	undo_btn.disabled = command_bus.undo_stack.is_empty()
	redo_btn.disabled = command_bus.redo_stack.is_empty()
