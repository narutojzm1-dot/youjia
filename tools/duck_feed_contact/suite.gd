extends SceneTree
const Model = preload("res://tools/duck_feed_contact/contact_model.gd")
var count := 0
var failures: Array[String] = []
func check(ok: bool, why: String):
	count += 1
	if not ok: failures.append(why); push_error(why)
func _initialize(): call_deferred("run")
func run():
	var parent := Node2D.new()
	root.add_child(parent)
	parent.position = Vector2(70,30)
	parent.rotation = 0.3
	parent.scale = Vector2(1.2,0.8)
	var sprite := Sprite2D.new()
	parent.add_child(sprite)
	var image := Image.create(1254,1254,false,Image.FORMAT_RGBA8)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.offset = Vector2(627,627)-Vector2(590,1177)
	sprite.position = Vector2(10,20)
	for face in [-1,1]:
		for depth in [0.02,0.04]:
			sprite.scale = Vector2(face*depth,depth)
			var foot: Vector2 = Model.pixel_world(sprite,Vector2(590,1177))
			var mouth: Vector2 = Model.pixel_world(sprite,Vector2(1110,807))
			check(foot.distance_to(sprite.global_position)<0.0001,"foot anchored under arbitrary parent transform")
			check(sprite.to_local(mouth).distance_to(Vector2(520,-370))<0.002,"mouth reverses to actual pixel offset under mirror/depth")
	sprite.flip_h=true; sprite.flip_v=true
	check(sprite.to_local(Model.pixel_world(sprite,Vector2(1110,807))).distance_to(Vector2(-446,-730))<0.002,"Sprite flip flags also mirror image pixels")
	sprite.flip_h=false; sprite.flip_v=false
	sprite.centered=false; sprite.offset=Vector2(-590,-1177)
	check(sprite.to_local(Model.pixel_world(sprite,Vector2(1110,807))).distance_to(Vector2(520,-370))<0.002,"uncentered offset convention supported")
	parent.free()
	var m = Model.new()
	check(m.begin(Vector2.ZERO,Vector2(-40,0),Vector2(10,-9)),"start")
	check(not m.sample().visible,"settling no phantom fish")
	m.advance(0.2,Vector2.ZERO)
	check(m.sample().point.distance_to(Vector2(-40,0))<0.0001,"flight begins at source")
	m.advance(0.3,Vector2.ZERO)
	check(m.sample().point.distance_to(Vector2(10,-9))<0.0001,"contact endpoint exact")
	check(not m.begin(Vector2.ZERO,Vector2.ONE,Vector2.ONE),"second success cannot restart visual")
	check(is_equal_approx(m.elapsed,0.5),"repeat never extends elapsed")
	m.advance(0.2,Vector2.ZERO)
	check(not m.sample().visible,"fish removed at contact end")
	m.advance(1.5,Vector2.ZERO)
	check(not m.active,"2.2s ends")
	check(not m.begin(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO),"cooldown survives end")
	m.advance(2.8,Vector2.ZERO)
	check(m.begin(Vector2.ZERO,Vector2.ZERO,Vector2(5,-2),true),"5s permits later response")
	m.advance(0.2,Vector2.ZERO)
	check(m.sample().phase=="contact" and m.sample().point==Vector2(5,-2),"low motion static contact with no flight")
	for reason in ["move","pose","exit"]:
		m = Model.new(); m.begin(Vector2.ZERO,Vector2.ZERO,Vector2.ONE)
		m.advance(0.1,Vector2.ONE if reason=="move" else Vector2.ZERO,reason=="pose",reason!="exit")
		check(not m.active and not m.sample().visible,"cancel "+reason)
		check(not m.begin(Vector2.ZERO,Vector2.ZERO,Vector2.ONE),"cancel does not bypass interval "+reason)
	m = Model.new(); m.begin(Vector2.ZERO,Vector2.ZERO,Vector2.ONE)
	m.advance(-1,Vector2.ZERO); m.advance(NAN,Vector2.ZERO)
	check(m.elapsed==0 and m.cooldown==5,"invalid deltas do not corrupt time")
	m.advance(20,Vector2.ZERO)
	check(not m.active and m.cooldown==0,"large frame cannot leave persistent visual")
	print("DUCK CONTACT ","PASS" if failures.is_empty() else "FAIL"," ",count)
	quit(0 if failures.is_empty() else 1)
