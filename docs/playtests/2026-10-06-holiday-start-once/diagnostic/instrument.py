from pathlib import Path
p=Path('/dev/shm/gate399-trace/scripts/main.gd');s=p.read_text()
s=s.replace('func _input(event: InputEvent) -> void:\n','func _input(event: InputEvent) -> void:\n\tif event is InputEventScreenTouch or event is InputEventMouseButton:\n\t\tprint("TRACE399 INPUT ", Engine.get_process_frames(), " ", event.as_text(), " screen=", _screen)\n')
s=s.replace('\t_play_button.pressed.connect(_on_play_pressed)','\t_play_button.button_down.connect(func(): print("TRACE399 PLAY_DOWN ", Engine.get_process_frames(), " screen=", _screen))\n\t_play_button.button_up.connect(func(): print("TRACE399 PLAY_UP ", Engine.get_process_frames(), " screen=", _screen))\n\t_play_button.pressed.connect(_on_play_pressed)')
s=s.replace('func _on_play_pressed() -> void:\n','func _on_play_pressed() -> void:\n\tprint("TRACE399 PLAY_PRESSED ", Engine.get_process_frames(), " screen=", _screen, " stack=", get_stack())\n')
s=s.replace('func _start_holiday(save_progress: bool = true) -> void:\n','var _trace399_id := 0\nfunc _start_holiday(save_progress: bool = true) -> void:\n\t_trace399_id += 1\n\tvar trace_id := _trace399_id\n\tprint("TRACE399 START ", trace_id, " frame=", Engine.get_process_frames(), " screen=", _screen, " stack=", get_stack())\n')
s=s.replace('\tif save_progress and _world != null: _world._save_progress()\n\tif not await SaveStore.flush_pending()', '\tif save_progress and _world != null: _world._save_progress()\n\tprint("TRACE399 FLUSH_BEFORE ", trace_id)\n\tif not await SaveStore.flush_pending()')
s=s.replace('\tTuningStore.begin_run(false)','\tprint("TRACE399 FLUSH_AFTER ", trace_id, " frame=", Engine.get_process_frames(), " screen=", _screen)\n\tTuningStore.begin_run(false)')
s=s.replace('func _on_exploration_entered() -> void:\n','func _on_exploration_entered() -> void:\n\tprint("TRACE399 EXP_ENTER ", Engine.get_process_frames())\n')
s=s.replace('func _on_exploration_returned(notice_key: String) -> void:\n','func _on_exploration_returned(notice_key: String) -> void:\n\tprint("TRACE399 EXP_RETURN ", Engine.get_process_frames(), " ", notice_key)\n')
# log all notices without changing signature
lines=s.splitlines(True)
for i,l in list(enumerate(lines))[::-1]:
 if l.startswith('func _show_notice_key('):
  arg=l.split('(')[1].split(':')[0];lines.insert(i+1,'\tprint("TRACE399 NOTICE ", Engine.get_process_frames(), " ", '+arg+')\n')
p.write_text(''.join(lines))
