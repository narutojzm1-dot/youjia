extends SceneTree
var m
func _initialize(): call_deferred("run")
func record(label):
 print(JSON.stringify({"label":label,"pause":m._pause_screen.visible,"confirm":m._confirm_screen.visible,"music":m._music_slider.value,"tree_paused":paused,"resume_visible":m._resume_button.is_visible_in_tree(),"restart_visible":m._restart_button.is_visible_in_tree(),"music_visible":m._music_slider.is_visible_in_tree()}))
func run():
 m=load("res://scenes/main.tscn").instantiate();root.add_child(m)
 await process_frame
 await process_frame
 await root.get_node("SaveStore").flush_pending()
 m._screen="game"
 root.size=Vector2i(390,844);m.size=Vector2(390,844);m._layout()
 await process_frame
 await process_frame
 m._toggle_pause()
 await process_frame
 await process_frame
 m._music_slider.set_value_no_signal(100)
 m._request_destructive_action("title")
 await process_frame
 await process_frame
 print("RECTS ",m._confirm_cancel_button.get_global_rect()," music ",m._music_slider.get_global_rect())
 m._confirm_cancel_button.pressed.connect(func(): print("SIGNAL cancel"))
 m._resume_button.pressed.connect(func(): print("SIGNAL resume"))
 m._music_slider.value_changed.connect(func(v): print("SIGNAL music ",v))
 m._confirm_cancel_button.gui_input.connect(func(v): print("GUI cancel ",v.as_text()))
 m._music_slider.gui_input.connect(func(v): print("GUI slider ",v.as_text()))
 m._resume_button.gui_input.connect(func(v): print("GUI resume ",v.as_text()))
 record("before")
 var e=InputEventScreenTouch.new();e.index=0;e.position=Vector2(195,490);e.pressed=true
 Input.parse_input_event(e);await process_frame;record("cancel_press")
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("cancel_release")
 await process_frame
 await process_frame
 record("cancel_settled")
 e.position=m._resume_button.get_global_rect().get_center();e.pressed=true;Input.parse_input_event(e);await process_frame;record("resume_press")
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("resume_release")
 await process_frame
 await process_frame
 record("resume_settled")
 quit()
