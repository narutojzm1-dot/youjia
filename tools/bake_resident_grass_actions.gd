extends SceneTree

# Full-frame bake from the same approved rigid painted layers as the walk.
# Feet stay at their rest contacts; only authored joint angles change.
const FOLDER := "res://assets/holiday/characters/resident_grass_actions_v1"
const SIZE := Vector2i(384, 448)
const ANCHOR := Vector2(192, 420)
const COUNT := 9

func _initialize() -> void:
	call_deferred("_bake")

func _bake() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor := ResidentWalker.new()
	viewport.add_child(actor)
	actor.position = ANCHOR
	actor.scale = Vector2.ONE * 4.0
	await process_frame
	var atlas := Image.create(SIZE.x * COUNT, SIZE.y * 2, false, Image.FORMAT_RGBA8)
	var hands := {}
	for row: int in 2:
		var action := "pickup" if row == 0 else "feed"
		hands[action] = []
		for index: int in COUNT:
			# Explicit anticipation / reach / return keys, eased between keys.
			var weights := [0.0, 0.18, 0.55, 0.90, 1.0, 0.88, 0.55, 0.18, 0.0]
			var weight: float = weights[index]
			actor.reset_motion()
			actor.pelvis.position = PaintedWalker.REST_PELVIS + Vector2(0, 12.0 * weight if row == 0 else 0.0)
			actor.torso.rotation = (0.28 if row == 0 else 0.04) * weight
			if row == 0 and weight > 0.0:
				for side: int in 2:
					var hip := actor.pelvis.position + actor.thighs[side].position
					var reach := actor.rest_feet[side] - hip
					var a: float = actor.thighs[side].length
					var b: float = actor.shins[side].length
					var distance := clampf(reach.length(), 0.1, a + b - 0.005)
					var bend := acos(clampf((a*a + distance*distance - b*b)/(2*a*distance), -1, 1))
					var knee := hip + reach.normalized().rotated(-bend) * a
					var upper := (knee - hip).angle() - PI*0.5
					var lower := (actor.rest_feet[side] - knee).angle() - PI*0.5
					# Solve fixed foot contacts without interpolating joint angles.
					actor.thighs[side].rotation = upper
					actor.shins[side].rotation = lower - upper
					actor.feet[side].rotation = -actor.thighs[side].rotation - actor.shins[side].rotation
			actor.shoulders[1].rotation = (-0.12 if row == 0 else -0.90) * weight
			actor.elbows[1].rotation = (0.08 if row == 0 else -0.30) * weight
			actor.shoulders[0].rotation = 0.12 * weight
			await process_frame
			await RenderingServer.frame_post_draw
			var picture := viewport.get_texture().get_image()
			atlas.blit_rect(picture, Rect2i(Vector2i.ZERO, SIZE), Vector2i(index*SIZE.x, row*SIZE.y))
			var hand := actor.elbows[1].to_global(Vector2(1.7, 11))
			hands[action].append([snappedf(hand.x, 0.01), snappedf(hand.y, 0.01)])
		atlas.save_png(FOLDER.path_join("actions.png"))
	var manifest := {
		"method": "Nine authored rigid-layer poses per action, baked full frames; no runtime deformation",
		"canvas": [384, 448], "anchor": [192, 420], "frames": COUNT,
		"hands": hands,
		"source_sha256": FileAccess.get_sha256("res://assets/holiday/characters/approved_resident_upper_v1.png"),
		"baker_sha256": FileAccess.get_sha256("res://tools/bake_resident_grass_actions.gd"),
	}
	FileAccess.open(FOLDER.path_join("manifest.json"), FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t"))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
