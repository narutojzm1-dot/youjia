extends SceneTree
# Explicit controlled clock/weather fixtures, never ordinary-player elapsed time.
var folder := ""
func _initialize() -> void: call_deferred("run")
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
 main._world.set_process(false)
 for weather in ["sun","overcast","rain"]:
  main._world.set_weather(weather)
  for i in 180: main._world._tick_weather_transition(1.0/60.0)
  for hour in ([6.0,12.0,19.0,21.0,1.0] if weather=="sun" else [6.0,19.0,1.0]):
   var fraction=fposmod(hour-6.0,24.0)/24.0
   main._world._day_elapsed=fraction*main._world.DAY_DURATION_SECONDS
   for i in 180: main._world.house.tick(1.0/60.0)
   main._process(0.0)
   main._update_tod_tint(fraction)
   for i in 6: await process_frame
   await RenderingServer.frame_post_draw
   var label="%s-%02d" % [weather,int(hour)]
   assert(root.get_texture().get_image().save_jpg(folder.path_join(label+".jpg"),0.88)==OK)
   print("SOLAR640_CAPTURE ",label)
 main.queue_free()
 await process_frame
 root.get_node("AudioDirector").release_streams()
 quit(0)
