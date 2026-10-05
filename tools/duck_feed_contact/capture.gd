## Controlled native study, not normal gameplay or production art integration.
extends SceneTree
const Model = preload("res://tools/duck_feed_contact/contact_model.gd")
class Marks extends Node2D:
	var mouth := Vector2.ZERO
	var foot := Vector2.ZERO
	var start := Vector2.ZERO
	func _draw():
		draw_line(foot-Vector2(8,0),foot+Vector2(8,0),Color.RED,1)
		draw_line(mouth-Vector2(3,0),mouth+Vector2(3,0),Color.CYAN,1)
		draw_line(mouth-Vector2(0,3),mouth+Vector2(0,3),Color.CYAN,1)
		var m = Model.new()
		m.begin(foot,start,mouth)
		var points := PackedVector2Array()
		for i in 31:
			m.elapsed = 0.2+0.3*i/30.0
			points.append(m.sample().point)
		draw_polyline(points,Color(0.8,0.35,0.1,0.7),0.7)
		draw_circle(mouth,1,Color.YELLOW)
func _initialize(): call_deferred("run")
func vec(v: Vector2): return [v.x,v.y]
func run():
	var out := OS.get_environment("CONTACT_OUT")
	var path := OS.get_environment("CONTACT_PNG")
	if out.is_empty() or path.is_empty(): push_error("CONTACT_OUT and CONTACT_PNG required"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	if FileAccess.get_sha256(path) != "baae49e482836604cd656e6057ed93a14ad6fce858f27e101d89f4f82ac5e556":
		push_error("Wrong candidate bytes: use PR369 ecfd exact original"); quit(1); return
	var image := Image.load_from_file(path)
	if image == null: quit(1); return
	var texture := ImageTexture.create_from_image(image)
	var records := []
	for size in [Vector2i(1280,720),Vector2i(390,844)]:
		for face in [-1,1]:
			var vp := SubViewport.new()
			vp.size=size
			vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
			root.add_child(vp)
			var world = load("res://scripts/game/yard_world.gd").new()
			vp.add_child(world); world.setup()
			# Keep authored positions; initialize normal depth transform once.
			world.tick(0.0,Vector2.ZERO)
			world.simulation_active=false; world.input_enabled=false
			var duck = world.actor_named("duck_a")
			var sprite: Sprite2D = duck._sprite
			var original_position: Vector2 = duck.position
			var original_scale: Vector2 = duck.scale
			duck.scale.x=absf(duck.scale.x)*face
			var before := Model.pixel_world(sprite,duck._ground_anchor)
			# Isolated view only: candidate texture/anchor, same actual actor transform.
			sprite.texture=texture
			sprite.offset=texture.get_size()*0.5-Vector2(590,1177)
			var foot := Model.pixel_world(sprite,Vector2(590,1177))
			var mouth := Model.pixel_world(sprite,Vector2(1110,807))
			var start: Vector2 = mouth+Vector2(face*32,-3)
			# Engineering source, NOT a claim about a production hand anchor.
			var markers := Marks.new()
			world.add_child(markers); markers.z_index=4095
			markers.foot=foot; markers.mouth=mouth; markers.start=start
			# Calibration camera fits the full authored yard into the output. Not Main's mobile camera.
			var fit := minf(float(size.x)/1280.0,float(size.y)/720.0)
			var offset := (Vector2(size)-Vector2(1280,720)*fit)*0.5
			vp.canvas_transform=Transform2D(Vector2(fit,0),Vector2(0,fit),offset)
			var label := Label.new()
			var layer := CanvasLayer.new()
			vp.add_child(layer); layer.add_child(label)
			label.text="CONTROLLED CONTACT STUDY\ncyan=mouth yellow=contact red=foot\nengineering path; NOT production fish\n%s / face %s"%[size,face]
			label.position=Vector2(8,8)
			label.add_theme_color_override("font_color",Color.BLACK)
			label.add_theme_font_size_override("font_size",14)
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			var name := "%dx%d-face%d"%[size.x,size.y,face]
			var err := vp.get_texture().get_image().save_png(out+"/"+name+".png")
			assert(err==OK)
			if size.x==1280:
				var crop := vp.get_texture().get_image().get_region(Rect2i(620,540,120,70))
				assert(crop.save_png(out+"/"+name+"-detail.png")==OK)
			assert(foot.distance_to(before)<0.001 and duck.position==original_position)
			records.append({"frame":name,"viewport":vec(Vector2(size)),"face":face,"actor_position":vec(duck.position),"original_scale":vec(original_scale),"actual_scale":vec(duck.scale),"foot_before":vec(before),"foot_after":vec(foot),"foot_delta":foot.distance_to(before),"mouth_world":vec(mouth),"mouth_screen":vec(vp.canvas_transform*mouth),"foot_screen":vec(vp.canvas_transform*foot),"engineering_source":vec(start),"fit":fit,"offset":vec(offset),"sprite_global_transform":[vec(sprite.global_transform.x),vec(sprite.global_transform.y),vec(sprite.global_transform.origin)]})
			vp.free()
	var f := FileAccess.open(out+"/geometry.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(records,"  ")); f.close()
	print("CONTACT CAPTURE PASS 4 controlled native frames")
	quit(0)
