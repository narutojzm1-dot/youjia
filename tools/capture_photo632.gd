extends SceneTree
# Controlled scene fixture: actual saved encounter and album renderer, not ordinary play.
var folder := ""
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
 for i in 6: await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_jpg(folder.path_join(label+".jpg"), 0.88) == OK)
 print("PHOTO632_CAPTURE ",label)
func run() -> void:
 folder=OS.get_environment("YOUJIA_CAPTURE_DIR")
 var isolated=OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
 if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
  quit(2)
  return
 DirAccess.make_dir_recursive_absolute(folder)
 root.size=Vector2i(1280,720)
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 for i in 3: await process_frame
 await main._start_holiday()
 main.set_process(false)
 var store=root.get_node("SaveStore")
 assert(await preload("res://test/fixtures/ground_llama_photo.gd").feed(main,store))
 var id="llama_fed_gentle"
 var moment=store.get_photo_moment(id)
 assert(not moment.is_empty() and moment.has("caption_variant"))
 main._show_album()
 await shot("new-sunny-album")
 main._hide_album()
 var legacy:Dictionary=moment.duplicate(true)
 legacy.erase("caption_variant")
 assert(not PhotoMoment.sanitize(legacy).is_empty() and legacy.weather==moment.weather)
 var moments=store.get_photo_moments().duplicate(true)
 moments[id]=legacy
 assert(not store.request_album(PackedStringArray(store.get_album()),moments).is_empty())
 assert(await store.flush_pending())
 store._load()
 assert(store.get_photo_moment(id).weather == legacy.weather and not store.get_photo_moment(id).has("caption_variant"))
 main._show_album()
 await shot("valid-dated-legacy-album")
 root.get_node("I18n").set_locale("en")
 main._render_album_pages()
 await shot("valid-dated-legacy-english")
 main.queue_free()
 await process_frame
 root.get_node("AudioDirector").release_streams()
 quit(0)
