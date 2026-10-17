extends "res://test/milling_director_suite.gd"
const Mill := preload("res://scripts/game/yard_mill_view.gd")

func capture(label: String) -> void:
	var output := OS.get_environment("YOUJIA_DIRECTOR_CAPTURE")
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_jpg(output+"/"+label+".jpg",0.92) == OK,"actual GPU capture")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	store = root.get_node("SaveStore")
	await reset(6,0)
	check(begin(6.0),"real milling starts")
	reach("working")
	var player = world.get_player()
	var foot: Vector2 = player.position
	for i in 60: world.tick(1.0/30,Vector2.ZERO)
	var walker = player._sequence_walker
	check(walker.milling_pose_active and walker.mill_rig.visible,"dedicated rigid layers replace feed pose")
	var hand: Vector2 = world.to_local(player.grass_hand_global_position())
	var error := hand.distance_to(Mill.HANDLE_POINT)
	check(error < 3.0,"actual palm grips real wooden handle")
	var rig = walker.mill_rig
	for side in 2:
		check(rig.to_local(rig.feet[side].global_position).distance_to(rig.rest_feet[side]) < 0.001,"native planted shoe")
		check(world.to_local(rig.elbows[side].to_global(Vector2(1.7 if side == 1 else -1.7,11))).distance_to(Mill.HANDLE_POINT)<4.0,"both hands touch grip")
	check(player.position == foot and not world.pond_growth.material.visible,"no foot slide or lingering grain")
	await capture("mill-grip")
	var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not photo.is_empty() and photo.items.size() <= PhotoMoment.MAX_ITEMS,"existing bounded photograph stays valid")
	var layer_count := 0
	for item: Dictionary in photo.get("items",[]):
		if item.subject != "player": continue
		layer_count += 1
		var path: String = item.texture.get("atlas",item.texture.get("path",""))
		check(path in [ResidentWalker.RESIDENT.resource_path,PaintedWalker.PANTS.resource_path],"frozen player uses only old approved texture identifiers")
	check(layer_count >= 11,"photo freezes every articulated painted part")
	var serial := JSON.stringify(photo)
	check(JSON.parse_string(JSON.stringify(PhotoMoment.sanitize(JSON.parse_string(serial)))) == JSON.parse_string(serial),"full existing snapshot roundtrip")
	var output := OS.get_environment("YOUJIA_MILL_PHOTO")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(serial)
	var torso_before: float = rig.torso.rotation
	for i in 20: world.tick(1.0/30,Vector2.ZERO)
	check(absf(rig.torso.rotation-torso_before)>0.001,"pressure changes the body while hands remain on handle")
	check(world.to_local(player.grass_hand_global_position()).distance_to(Mill.HANDLE_POINT)<3.0,"moving body does not detach palm")
	check(JSON.stringify(photo) == serial,"later work cannot rewrite frozen photo")
	root.get_node("TuningStore").set_value("ui.reduced_motion",true)
	world.tick(0.0,Vector2.ZERO)
	var still: Transform2D = rig.torso.transform
	for i in 20: world.tick(1.0/30,Vector2.ZERO)
	check(rig.torso.transform.is_equal_approx(still),"reduced motion holds one contact pose")
	root.get_node("TuningStore").set_value("ui.reduced_motion",false)
	world.tick(0.0,Vector2.RIGHT)
	check(not walker.milling_pose_active and not rig.visible and walker.self_modulate == Color.WHITE,"manual takeover restores ordinary resident")
	check(store.get_growth_production().revision == 0,"interrupted pose cannot credit flour")
	await reset(6,0)
	check(begin(3.0),"new real transaction begins")
	reach("working")
	finish_work()
	check(await store.flush_pending(),"actual atomic completion")
	check(store.get_growth_production().revision==1 and store.get_yard_inventory().flour==1,"one confirmed flour result")
	check(not world.get_player()._sequence_walker.milling_pose_active,"completion restores ordinary resident")
	world.queue_free()
	await process_frame
	store._load()
	check(store.get_yard_inventory().flour==1,"native reopen preserves output")
	print("MILL_POSE_OBSERVATIONS "+JSON.stringify({"checks":checks,"failures":failures,"hand_error":error,"photo_items":photo.get("items",[]).size(),"player_layers":layer_count}))
	print("MILL_POSE checks=%d failures=%d"%[checks,failures.size()])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
