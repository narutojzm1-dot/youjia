extends SceneTree
const View := preload("res://scripts/game/original_plant_view.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var stage := Node2D.new()
	root.add_child(stage)
	var backdrop := Sprite2D.new()
	backdrop.centered = false
	backdrop.texture = preload("res://assets/holiday/environment/yard_sunny.png")
	backdrop.scale = Vector2(1280,720) / backdrop.texture.get_size()
	backdrop.z_index = -1
	stage.add_child(backdrop)
	var cloudy := Sprite2D.new()
	cloudy.centered = false
	cloudy.texture = preload("res://assets/holiday/environment/yard_overcast_aligned.png")
	cloudy.scale = Vector2(1280,720) / cloudy.texture.get_size()
	cloudy.z_index = -1
	stage.add_child(cloudy)
	var view := View.new()
	stage.add_child(view)
	var output := OS.get_environment("TEMP").path_join("youjia-flower642-gpu-preview")
	DirAccess.make_dir_recursive_absolute(output)
	for weather: float in [0.0,0.5,1.0]:
		cloudy.modulate.a = float(weather)
		for bits in 8:
			if weather == 0.5 and bits != 7: continue
			var removed: Array = []
			for i in 3:
				if bits & (1 << i): removed.append(View.Model.AREAS[i])
			view.sync({"schema":1,"revision":0,"removed":removed},float(weather),Color.WHITE,Color.WHITE)
			await process_frame
			await RenderingServer.frame_post_draw
			var label := "sun" if weather == 0.0 else ("mix" if weather == 0.5 else "overcast")
			var file := output.path_join("%s-%d.png" % [label,bits])
			var result := root.get_texture().get_image().save_png(file)
			print("FLOWER_PREVIEW %s result=%d" % [file,result])
	quit()
