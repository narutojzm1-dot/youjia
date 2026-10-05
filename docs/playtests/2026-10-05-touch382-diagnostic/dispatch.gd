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
 record("before")
 var e=InputEventScreenTouch.new();e.index=0;e.position=Vector2(195,490);e.pressed=true
 Input.parse_input_event(e);await process_frame;record("direct_press")
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("direct_release")
 m._cancel_destructive_action();m._music_slider.set_value_no_signal(100)
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("release_on_pause")
 m._music_slider.set_value_no_signal(100)
 m._request_destructive_action("title")
 var pos=m._confirm_cancel_button.get_global_rect().get_center()
 e.position=pos;e.pressed=true;Input.parse_input_event(e);await process_frame;record("cancel_center_press")
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("cancel_center_release")
 e.position=m._resume_button.get_global_rect().get_center();e.pressed=true;Input.parse_input_event(e);await process_frame;record("resume_press")
 e.pressed=false;Input.parse_input_event(e);await process_frame;record("resume_release")
 quit()
