extends Node
var checks := 0
var failures: Array[String] = []
var viewport: SubViewport
var overlay: Node2D
var samples: Array[Image] = []
func _ready() -> void: call_deferred("run")
func picture(kind: String, phase: float, reduced: bool) -> Image:
 get_node("/root/TuningStore").set_value("ui.reduced_motion", reduced, false)
 overlay.pet_pos = Vector2(128,170) if kind == "target" else Vector2.INF
 overlay.pet_alpha = 1.0
 overlay.pet_lift = 64.0
 overlay.pet_day_t = phase
 overlay.fish_ring_pos = Vector2(128,128)
 overlay.fish_ring_type = "medium"
 overlay.fish_ring_time = 3.2 * (1.0-phase) if kind == "catch" else 0.0
 overlay.queue_redraw()
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 return viewport.get_texture().get_image()
func check(ok: bool, label: String) -> void:
 checks+=1
 if not ok: failures.append(label);push_error(label)
func run() -> void:
 viewport=SubViewport.new();viewport.size=Vector2i(256,256)
 viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 overlay=load("res://scripts/game/world_effects_overlay.gd").new();viewport.add_child(overlay)
 for kind: String in ["target","catch"]:
  for reduced: bool in [false,true]:
   var a:=await picture(kind,0.2,reduced)
   var b:=await picture(kind,0.8,reduced)
   check(a.get_data()==b.get_data() if reduced else a.get_data()!=b.get_data(),kind+" static/ordinary actual pixels")
   check(a.get_used_rect().size.x>20 and a.get_used_rect().size.y>20,kind+" remains visible")
   samples.append(a)
 var paper:=ColorRect.new();paper.size=Vector2(1280,720);paper.color=Color("fff6e8");add_child(paper)
 for i: int in samples.size():
  var photo:=TextureRect.new();photo.texture=ImageTexture.create_from_image(samples[i]);photo.position=Vector2(60+i*300,220);photo.size=Vector2(256,256);add_child(photo)
  var label:=Label.new();label.text=["Target ordinary","Target reduced","Catch ordinary","Catch reduced"][i];label.position=Vector2(60+i*300,160);label.add_theme_color_override("font_color",Color("5b4637"));add_child(label)
 print("[still-catch-render] ",checks," checks, failures=",failures)
 if OS.has_feature("web"):
  JavaScriptBridge.eval("window.stillCatchResult="+JSON.stringify({"checks":checks,"failures":failures})+";window.dispatchEvent(new Event('youjia:first-frame'));",true)
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("YOUJIA_CAPTURE_PATH")
 if not output.is_empty():get_viewport().get_texture().get_image().save_png(output)
 if "--quit-after-test" in OS.get_cmdline_user_args():
  get_node("/root/AudioDirector").call("release_streams")
  get_tree().quit(0 if failures.is_empty() else 1)
