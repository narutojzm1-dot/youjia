extends Node2D

func _ready() -> void:
	var capture := "--capture" in OS.get_cmdline_user_args()
	if capture:
		var background := Sprite2D.new()
		background.texture = load("res://yard.png")
		background.centered = false
		background.scale = Vector2(1280.0,720.0)/background.texture.get_size()
		add_child(background)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	var ratio := .26 * (34.0 / 1140.0 / .32) * (.82 + .36 * ((562.0 - 420.0) / 230.0))
	sprite.scale = Vector2(ratio, ratio)
	sprite.position = Vector2(688,562) - Vector2(670,1205)*ratio
	var report := {"engine": Engine.get_version_info().string, "scope": "isolated Sprite2D loading and anchor transform, not gameplay", "scale": ratio, "frames": []}
	for file in ["idle.png", "feed.png"]:
		var texture := load("res://" + file) as Texture2D
		assert(texture != null)
		assert(texture.get_size() == Vector2(1254,1254))
		sprite.texture = texture
		var anchor := Vector2(670,1205) if file == "idle.png" else Vector2(590,1177)
		sprite.position = Vector2(688,562) - anchor*ratio
		await get_tree().process_frame
		if capture:
			await RenderingServer.frame_post_draw
			var screenshot := get_viewport().get_texture().get_image()
			assert(screenshot.save_png("res://capture_" + file) == OK)
		var foot := sprite.to_global(anchor)
		assert(foot.distance_to(Vector2(688,562)) < .001)
		report.frames.append({"file":file,"loaded":true,"foot_x":foot.x,"foot_y":foot.y,"width":texture.get_width()})
	var output := FileAccess.open("res://engine-check.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print(JSON.stringify(report))
	get_tree().quit()
