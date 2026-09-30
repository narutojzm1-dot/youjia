extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var resource:=load("res://scenes/experimental/resident_walk_authored_v1.tres") as SpriteFrames
	assert(resource!=null and resource.get_frame_count("walk")==16)
	assert(resource.get_animation_loop("walk"))
	assert(is_equal_approx(resource.get_animation_speed("walk"),12.0))
	var hashes: Dictionary={}
	for index: int in 16:
		var texture:=resource.get_frame_texture("walk",index)
		assert(texture.get_size()==Vector2(384,448))
		var path:="res://assets/holiday/characters/resident_walk_authored_v1/%02d.png"%index
		var hash:=FileAccess.get_sha256(path)
		assert(not hashes.has(hash))
		hashes[hash]=true
		var used:=texture.get_image().get_used_rect()
		assert(used.position.x>0 and used.position.y>0)
		assert(used.end.x<384 and used.end.y<448)
	var scene:=load("res://scenes/experimental/resident_walk_authored_v1.tscn") as PackedScene
	var actor:=scene.instantiate() as AnimatedSprite2D
	assert(actor.offset==Vector2(-192,-420) and actor.scale==Vector2(0.25,0.25))
	actor.free()
	print("[authored-sequence-tests] PASS: 16 distinct complete frames, uniform canvas and anchor, loop metadata")
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
