extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _initialize(): call_deferred("run")
func run():
	var store = root.get_node("TuningStore")
	var locale = root.get_node("I18n")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world);world.setup()
	var snapshot := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	world.free()
	var arrival = load("res://scripts/ui/photo_arrival.gd").new()
	root.add_child(arrival)
	var complete := [0]
	arrival.tucked_away.connect(func():complete[0]+=1)
	store.set_value("ui.reduced_motion",false,false)
	root.size=Vector2i(1280,720)
	await process_frame
	check(arrival.play(snapshot,false),"normal starts")
	arrival._tween.pause()
	arrival._tween.custom_step(0.08)
	var original: Dictionary=arrival._snapshot.duplicate(true)
	check(is_equal_approx(arrival._tween.get_total_elapsed_time(),0.08),"real original Tween progressed into fade")
	root.size=Vector2i(320,300)
	store.set_value("ui.reduced_motion",true,false)
	arrival._tween.pause()
	await process_frame
	var paper: Rect2=arrival._card.get_global_rect()
	check(paper.position.x>=7.5 and paper.position.y>=7.5 and paper.end.x<=320-7.5 and paper.end.y<=300-7.5,"actual live paper inside 320x300")
	check(arrival._motion_static and arrival._card.modulate.a==1,"resize concurrent reduce stays static")
	root.size=Vector2i(390,844)
	store.set_value("ui.reduced_motion",false,false)
	await process_frame
	check(arrival._snapshot==original and arrival._motion_static,"reverse resize and normal preserve photo and static state")
	arrival._tween.custom_step(1.49)
	check(arrival.visible and complete[0]==0,"still visible just before original remaining deadline")
	arrival._tween.custom_step(0.02)
	await process_frame
	check(not arrival.visible,"completed at original deadline without restarting full duration")
	check(complete[0]==1,"one completion only")
	for language in ["zh-CN","en"]:
		locale.set_locale(language)
		for dims in [Vector2i(320,300),Vector2i(568,320),Vector2i(390,844)]:
			root.size=dims
			await process_frame
			for id in ExpressionCatalog.all_ids():
				var rule: Dictionary=ExpressionCatalog.find_rule(id)
				for variant in int(rule.get("caption_variants",1)):
					var photo: Dictionary=snapshot.duplicate(true)
					photo.rule_id=id;photo.day=10000;photo.caption_variant=variant
					check(arrival.play(photo,true),"real caption accepted %s %s v%d"%[language,id,variant])
					await process_frame
					await process_frame
					var caption: Label=arrival._caption
					check(caption.position.y+caption.size.y<=300.0,"actual caption does not cross paper bottom %s %s %s (%s)"%[language,id,dims,caption.size])
					check(caption.get_visible_line_count()==caption.get_line_count(),"all actual caption lines visible %s %s"%[language,id])
					var shutter: Label=arrival._shutter
					check(shutter.get_minimum_size().y<=shutter.size.y+0.5,"real shutter line height fits %s %s"%[language,dims])
					var output := OS.get_environment("PHOTO422_CAPTURE")
					if not output.is_empty() and id == "fish_first_catch" and variant == 0:
						DirAccess.make_dir_recursive_absolute(output)
						await RenderingServer.frame_post_draw
						check(root.get_texture().get_image().save_png(output+"/%s-%dx%d.png"%[language,dims.x,dims.y])==OK,"actual rendered caption saved")
					arrival.dismiss()
	locale.set_locale("zh-CN")
	arrival.free()
	print("PHOTO ARRIVAL COMBO ","PASS" if failures.is_empty() else "FAIL"," ",checks)
	quit(0 if failures.is_empty() else 1)
