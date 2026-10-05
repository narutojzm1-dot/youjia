extends SceneTree
const Lic = preload("res://scripts/manus/open_source_licenses.gd")
func _initialize():
 call_deferred("run")
func snap(tag, dialog):
 var data = {"tag":tag,"root_size":str(root.size),"embed":root.gui_embed_subwindows,"dialog_size":str(dialog.size),"dialog_position":str(dialog.position),"text_min":str(dialog.get_child(0).custom_minimum_size),"ok_rect":str(dialog.get_ok_button().get_global_rect()),"visible":dialog.visible}
 print(JSON.stringify(data))
 var f=FileAccess.open("/workspace/pr402-review/stage",FileAccess.WRITE)
 f.store_string(tag)
func run():
 root.position=Vector2i(30,30)
 root.size=Vector2i(390,844)
 await create_timer(1).timeout
 Lic.open(root)
 await create_timer(1).timeout
 var d=root.get_node("OpenSourceLicensesDialog")
 snap("portrait",d)
 await create_timer(8).timeout
 # Actual focused default OK keyboard activation, through native input event.
 print("NATIVE_CLICK_EXPECTED")
 await create_timer(1).timeout
 print("CONFIRM_CLOSED=", not is_instance_valid(d))
 if is_instance_valid(d):
  d.queue_free()
  await process_frame
 root.size=Vector2i(1280,720)
 await create_timer(1).timeout
 Lic.open(root)
 await create_timer(1).timeout
 d=root.get_node("OpenSourceLicensesDialog")
 snap("wide",d)
 await create_timer(5).timeout
 root.size=Vector2i(390,844)
 await create_timer(1).timeout
 snap("live-resize-portrait",d)
 await create_timer(8).timeout
 quit()
