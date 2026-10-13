extends SceneTree
const View := preload("res://scripts/game/yard_mill_view.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func mill_item(photo: Dictionary) -> Dictionary:
	for item: Dictionary in photo.get("items",[]):
		if item.get("texture",{}).get("path","") == View.ART.resource_path: return item
	return {}

func mill_lines(photo: Dictionary) -> Array:
	return photo.get("items",[]).filter(func(item: Dictionary): return item.kind == "line" and item.depth == roundi(View.ANCHOR.y) and item.subject == "")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	var store = root.get_node("SaveStore")
	var world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	world.tick(0.0,Vector2.ZERO)
	world.simulation_active = false
	var view = world.mill_view
	var saved: Dictionary = store._data.duplicate(true)
	var body_before: Transform2D = view.art.transform
	check(view != null and view.is_visible_in_tree(),"birth world contains authored mill without unlock or inventory mutation")
	check(not view.flour.visible and not view.is_processing(),"idle view has no autonomous animation clock")
	var player = world.get_player()
	var radius: Vector2 = player.body_radius * YardGround.depth_at(View.APPROACH.y)
	var path := YardBodies.route(player.position,View.APPROACH,radius,world.physical_obstacles("player"),world.player_ground())
	check(not path.is_empty() and path[-1].is_equal_approx(View.APPROACH),"populated birth yard has a real route to the mill station")
	var landed := YardBodies.move_inside(View.APPROACH,View.ANCHOR-View.APPROACH,radius,world.physical_obstacles("player"),world.player_ground(),true)
	check(landed.distance_to(View.ANCHOR) > 10.0,"the real mill footprint prevents walking through its body")
	var idle := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not mill_item(idle).is_empty() and mill_lines(idle).size() == 2,"existing photo schema captures authored mill and contact lines")
	view.sync_work(true,0.31,false)
	check(view.flour.visible,"real production signal shows the flour cue")
	var work := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	var frozen := JSON.stringify(work)
	check(mill_lines(work).size() == 3,"working photo records the in-flight flour cue")
	var position_before: Vector2 = view.flour.position
	var alpha_before: float = view.flour.modulate.a
	for i in 3: await process_frame
	check(view.flour.position == position_before and view.flour.modulate.a == alpha_before,"paused director progress cannot animate in independent render frames")
	view.sync_work(true,0.31,false)
	check(view.flour.position == position_before,"same supplied progress does not accumulate presentation time")
	view.sync_work(true,0.71,false)
	check(view.flour.position != position_before,"progress advance moves only the flour cue")
	view.sync_work(true,0.23,true)
	position_before = view.flour.position
	alpha_before = view.flour.modulate.a
	view.sync_work(true,0.93,true)
	check(view.flour.position == position_before and view.flour.modulate.a == alpha_before,"reduced motion retains a stationary work indicator")
	view.sync_work(false,0.0)
	check(not view.flour.visible and mill_lines(PhotoMoment.capture(world,{"id":"fish_first_catch"})).size() == 2,"cancellation removes transient flour without a credited pile")
	view.sync_work(true,NAN)
	check(not view.flour.visible,"invalid progress cannot paint fabricated production")
	view.sync_environment(1.0)
	check(view.art.modulate == View.OVERCAST_TINT,"overcast grades source art without changing its bitmap")
	view.sync_environment(NAN)
	check(view.art.modulate == View.OVERCAST_TINT,"invalid weather cannot corrupt the last valid tint")
	var rain_photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(mill_item(rain_photo).modulate != mill_item(idle).modulate,"photo freezes effective weather color")
	check(JSON.stringify(work) == frozen,"later weather and cancellation do not rewrite a captured moment")
	var roundtrip := PhotoMoment.sanitize(JSON.parse_string(frozen))
	check(not mill_item(roundtrip).is_empty() and mill_lines(roundtrip).size() == 3,"serialized photo retains source art and working line data")
	var photo := PhotoMoment.new()
	root.add_child(photo)
	photo.setup(roundtrip)
	check(photo._snapshot == roundtrip,"inert photo replay accepts the unchanged schema")
	check(view.art.transform == body_before,"production and weather never stretch, rock or translate the authored mill")
	check(store._data == saved,"presentation and photograph operations do not alter materials, AP or save state")
	photo.queue_free()
	world.queue_free()
	await process_frame
	for failure: String in failures: push_error(failure)
	print("YARD_MILL_VIEW checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
