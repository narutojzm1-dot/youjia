extends "res://test/garden_director_suite.gd"

func capture(label: String) -> void:
	var output := OS.get_environment("YOUJIA_DIRECTOR_CAPTURE")
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_jpg(output+"/"+label+".jpg",0.94)==OK,"actual GPU capture "+label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	store = root.get_node("SaveStore")
	await prepare_garden()
	check(begin(12.0),"actual garden director begins")
	reach("working")
	var player = world.get_player()
	var walker = player._sequence_walker
	var foot: Vector2 = player.position
	var photo := {}
	var serial := ""
	var previous_hand := Vector2.ZERO
	var moving_hand := false
	for progress: float in [0.0,0.08,0.24,0.32,0.40,0.60,0.72,0.84,0.94,0.999]:
		world.pond_growth.work = progress*12.0
		world.tick(0.0,Vector2.ZERO)
		var rig = walker.garden_rig
		check(walker.gardening_pose_active and rig.visible and not walker.milling_pose_active,"dedicated planting pose at %.3f"%progress)
		check(player.position == foot,"actor foot location stays fixed")
		for side in 2:
			check(rig.to_local(rig.feet[side].global_position).distance_to(rig.rest_feet[side])<0.001,"planted shoes throughout squat and rise")
		if progress >= 0.24 and progress <= 0.84:
			var hand: Vector2 = world.to_local(walker.gardening_hand_global_position())
			check(hand.distance_to(View.CONTACT_POINT)<9.0,"front palm reaches real bed")
			if not previous_hand.is_zero_approx() and hand.distance_to(previous_hand)>0.5: moving_hand=true
			previous_hand = hand
		if progress == 0.32:
			check(world.pond_growth.material.visible and world.pond_growth.material.global_position.distance_to(walker.gardening_hand_global_position(0))<0.001,"seed packet rests in rear hand")
			photo = PhotoMoment.capture(world,{"id":"fish_first_catch"})
			serial = JSON.stringify(photo)
		if progress >= 0.60: check(not world.pond_growth.material.visible,"packet put away before soil covering")
		check(store.get_yard_garden().revision==0 and store._data.keepsakes[SEEDS]==2,"pose never prematurely debits or plants")
		await capture("garden-"+str(int(progress*1000)))
		if progress in [0.32,0.72]:
			root.canvas_transform = Transform2D(Vector2(2.0,0),Vector2(0,2.0),Vector2(-240,-660))
			await capture("garden-detail-"+str(int(progress*1000)))
			root.canvas_transform = Transform2D.IDENTITY
	check(moving_hand,"front hand distributes seed and covers soil")
	check(not photo.is_empty() and photo.items.size()<=PhotoMoment.MAX_ITEMS,"bounded photo capture")
	var layers := 0
	for item: Dictionary in photo.items:
		if item.subject != "player": continue
		var path: String = item.texture.get("atlas",item.texture.get("path",""))
		if path == View.ART_PATH: continue # Already-public seed packet carried by this actor.
		layers += 1
		check(path in [ResidentWalker.RESIDENT.resource_path,PaintedWalker.PANTS.resource_path],"only existing approved photograph texture identifiers")
	check(layers>=11,"all articulated resident parts captured")
	check(JSON.parse_string(JSON.stringify(PhotoMoment.sanitize(JSON.parse_string(serial))))==JSON.parse_string(serial),"every existing photo field survives roundtrip")
	check(JSON.stringify(photo)==serial,"later pose never mutates captured photograph")
	var photo_output := OS.get_environment("YOUJIA_GARDEN_PHOTO")
	if not photo_output.is_empty(): FileAccess.open(photo_output,FileAccess.WRITE).store_string(serial)
	var paused_work: float = world.pond_growth.work
	world.simulation_active = false
	var paused_pose: Transform2D = walker.garden_rig.torso.transform
	for i in 30: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.work==paused_work and walker.garden_rig.torso.transform==paused_pose,"paused world advances neither work nor pose")
	world.simulation_active = true
	world.pond_growth.work = 5.0
	root.get_node("TuningStore").set_value("ui.reduced_motion",true)
	world.tick(0.0,Vector2.ZERO)
	var torso: Transform2D = walker.garden_rig.torso.transform
	var arm: Transform2D = walker.garden_rig.shoulders[1].transform
	for i in 20: world.tick(1.0/30,Vector2.ZERO)
	check(walker.garden_rig.torso.transform.is_equal_approx(torso) and walker.garden_rig.shoulders[1].transform.is_equal_approx(arm),"reduced motion holds a quiet soil contact")
	root.get_node("TuningStore").set_value("ui.reduced_motion",false)
	world.tick(0.0,Vector2.RIGHT)
	check(not walker.gardening_pose_active and not walker.garden_rig.visible and walker.self_modulate==Color.WHITE,"takeover restores original walking sprite")
	check(store.get_yard_garden().revision==0 and store._data.keepsakes[SEEDS]==2,"takeover cannot charge material or AP")
	await prepare_garden()
	check(begin(3.0),"new complete transaction")
	reach("working")
	finish_work()
	check(await store.flush_pending(),"composite save confirmed")
	check(store.get_yard_garden().revision==1 and store._data.keepsakes[SEEDS]==1,"only completion confirms bed and one seed")
	check(not world.get_player()._sequence_walker.gardening_pose_active,"completion restores ordinary actor")
	world.queue_free()
	await process_frame
	store._load()
	check(store.get_yard_garden().revision==1 and store._data.keepsakes[SEEDS]==1,"real file reload retains the single result")
	print("GARDEN_POSE checks=%d failures=%d"%[checks,failures.size()])
	for failure in failures: push_error(failure)
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
