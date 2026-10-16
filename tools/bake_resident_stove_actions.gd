extends SceneTree
## Authored joint keys on the existing editable rigid painted rig.
## No source raster is changed, stretched or generated. Feet remain planted.
const FOLDER := "res://assets/holiday/characters/resident_stove_actions_v1"
const SIZE := Vector2i(384,448)
const ANCHOR := Vector2(192,420)
const COUNT := 9

func _initialize() -> void:
	call_deferred("bake")

func arm(actor: ResidentWalker, side: int, palm: Vector2) -> void:
	var shoulder: Bone2D = actor.shoulders[side]
	var elbow: Bone2D = actor.elbows[side]
	var hand := Vector2(1.7 if side == 1 else -1.7,11)
	var target: Vector2 = shoulder.get_parent().to_local(actor.to_global(palm))
	var reach: Vector2 = target - shoulder.position
	var a := elbow.position.length()
	var b := hand.length()
	var distance := clampf(reach.length(),0.1,a+b-0.005)
	var bend := acos(clampf((a*a+distance*distance-b*b)/(2*a*distance),-1,1))
	var joint: Vector2 = shoulder.position + reach.normalized().rotated(-bend)*a
	shoulder.rotation = (joint-shoulder.position).angle()-elbow.position.angle()
	elbow.rotation = (target-joint).angle()-hand.angle()-shoulder.rotation

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor := ResidentWalker.new()
	viewport.add_child(actor)
	actor.position = ANCHOR
	actor.scale = Vector2.ONE*4
	await process_frame
	var atlas := Image.create(SIZE.x*COUNT,SIZE.y*3,false,Image.FORMAT_RGBA8)
	var hands := {}
	var feet := {}
	var max_error := 0.0
	for row in 3:
		var kind: String = ["stove_low","stove_high","stove_top"][row]
		hands[kind] = []
		feet[kind] = []
		for index in COUNT:
			actor.reset_motion()
			var weight: float = [0.0,0.16,0.5,0.86,1.0,1.0,0.86,0.5,0.16][index]
			# The first course is laid near the ground; later courses are pressed
			# at the raised work surface. Last key anticipates the next cycle.
			var press: float = 0.7 if index == 5 else 0.0
			actor.pelvis.position = PaintedWalker.REST_PELVIS + Vector2(0,[30.0,18.0,8.0][row]*weight)
			actor.torso.rotation = 0.10*weight
			for side in 2:
				var hip := actor.pelvis.position + actor.thighs[side].position
				var reach := actor.rest_feet[side]-hip
				var a: float = actor.thighs[side].length
				var b: float = actor.shins[side].length
				var distance := clampf(reach.length(),0.1,a+b)
				var bend := acos(clampf((a*a+distance*distance-b*b)/(2*a*distance),-1,1))
				var knee := hip + reach.normalized().rotated(-bend)*a
				var upper := (knee-hip).angle()-PI*0.5
				var lower := (actor.rest_feet[side]-knee).angle()-PI*0.5
				actor.thighs[side].rotation = upper
				actor.shins[side].rotation = lower-upper
				actor.feet[side].rotation = -lower
				var contact := Vector2(14.0 if side == 1 else 10.0,[-11.0,-24.0,-44.0][row]+press)
				var rest := actor.to_local(actor.elbows[side].to_global(Vector2(1.7 if side == 1 else -1.7,11)))
				arm(actor,side,rest.lerp(contact,weight))
				max_error = maxf(max_error,actor.to_local(actor.feet[side].global_position).distance_to(actor.rest_feet[side]))
			await process_frame
			await RenderingServer.frame_post_draw
			atlas.blit_rect(viewport.get_texture().get_image(),Rect2i(Vector2i.ZERO,SIZE),Vector2i(index*SIZE.x,row*SIZE.y))
			var palm := actor.elbows[1].to_global(Vector2(1.7,11))
			hands[kind].append([snappedf(palm.x,0.01),snappedf(palm.y,0.01)])
			feet[kind].append([actor.to_local(actor.feet[0].global_position),actor.to_local(actor.feet[1].global_position)])
	atlas.save_png(FOLDER.path_join("actions.png"))
	var manifest := {"canvas":[384,448],"anchor":[192,420],"frames":COUNT,"hands":hands,
		"max_foot_error_native":max_error,"method":"Authored two-hand masonry poses baked from unchanged rigid painted layers",
		"source_sha256":FileAccess.get_sha256("res://assets/holiday/characters/approved_resident_upper_v1.png"),
		"baker_sha256":FileAccess.get_sha256("res://tools/bake_resident_stove_actions.gd")}
	FileAccess.open(FOLDER.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("STOVE_BAKE max_foot_error=",max_error)
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if max_error < 0.001 else 1)
