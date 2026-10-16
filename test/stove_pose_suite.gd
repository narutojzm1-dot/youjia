extends "res://test/stove_director_suite.gd"
## Real production director and sprite transforms in a guarded isolated save.
func capture(label: String) -> void:
	var output := OS.get_environment("YOUJIA_DIRECTOR_CAPTURE")
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_jpg(output+"/"+label+".jpg",0.9) == OK,"GPU capture "+label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	store = root.get_node("SaveStore")
	await reset(2,6)
	var observations := []
	for index in 3:
		check(begin(3.0),"real stove stage begins")
		reach("working")
		var feet: Vector2 = world.get_player().position
		for i in 30: world.tick(1.0/30,Vector2.ZERO)
		var walker = world.get_player()._sequence_walker
		var expected_pose: StringName = [&"stove_low",&"stove_high",&"stove_top"][index]
		check(walker.animation == expected_pose and walker.frame == 4,"actual masonry contact pose")
		var contact: Vector2 = View.WORK_POINT + Vector2(0,[18,0,-20][index])
		var hand: Vector2 = world.to_local(world.get_player().grass_hand_global_position())
		var distance := hand.distance_to(contact)
		check(distance < 8,"hand reaches real work surface")
		check(world.pond_growth.material.global_position.distance_to(world.get_player().grass_hand_global_position()) < 0.01,"held stone stays in actual palm")
		await capture("stove-contact-%d"%index)
		var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
		var captured := false
		for item: Dictionary in photo.get("items",[]):
			if item.get("texture",{}).get("atlas","").contains("resident_stove_actions_v1"): captured = true
		check(captured,"photo freezes actual production atlas pose")
		for i in 45: world.tick(1.0/30,Vector2.ZERO)
		check(world.get_player().position == feet and not world.pond_growth.material.visible,"body stays planted and stone set down")
		root.get_node("TuningStore").set_value("ui.reduced_motion",true)
		world.tick(0.1,Vector2.ZERO)
		check(walker.animation == expected_pose and walker.frame == 4,"reduced motion keeps a still work contact")
		root.get_node("TuningStore").set_value("ui.reduced_motion",false)
		observations.append({"stage":index,"feet":[feet.x,feet.y],"hand":[hand.x,hand.y],"contact_error":distance,"pose":String(expected_pose)})
		finish_work()
		check(await store.flush_pending(),"real atomic completion")
		check(store.get_yard_stove().revision == index+1,"only durable stage credited")
	world.queue_free()
	await process_frame
	store._load()
	check(store.get_yard_stove().revision == 3,"normal native reload preserves three stages")
	print("STOVE_POSE_OBSERVATIONS "+JSON.stringify({"checks":checks,"failures":failures,"observations":observations}))
	print("STOVE_POSE checks=%d failures=%d"%[checks,failures.size()])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
