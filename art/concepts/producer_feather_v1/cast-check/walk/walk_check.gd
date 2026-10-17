extends Node2D
const L = preload("res://scripts/exploration/near_path_layout.gd")
const Resident = preload("res://scripts/entities/sequence_resident.gd")
var walker
var camera: Camera2D
var elapsed := 0.0
var previous := Vector2.ZERO
var capture_index := 0
var pending := false

func _ready() -> void:
	var painting := Sprite2D.new()
	painting.texture = load("res://near_path.png")
	painting.centered = false
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(painting)
	walker = Resident.new()
	add_child(walker)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	previous = L.point("lane",L.arm_length("lane"))
	get_window().size = Vector2i(844,390)
	DirAccess.make_dir_recursive_absolute("res://walk-evidence")

func _process(delta: float) -> void:
	if pending:
		return
	elapsed += delta
	var length: float = L.arm_length("lane")
	var d: float = maxf(0.0,length-elapsed*L.WALK_SPEED)
	var point: Vector2 = L.point("lane",d)
	var moved := point-previous
	walker.position = point
	walker.advance(delta,moved,L.depth(point.y),-1.0,false)
	previous = point
	var framing: Dictionary = L.frame(point,Vector2(844,390))
	camera.zoom = Vector2.ONE*float(framing.zoom)
	camera.position = framing.camera
	if elapsed >= float(capture_index)*0.5 or d <= 0.0:
		pending = true
		await RenderingServer.frame_post_draw
		var file := "res://walk-evidence/step_%02d_d%03d.png" % [capture_index,int(d)]
		assert(get_viewport().get_texture().get_image().save_png(file)==OK)
		capture_index += 1
		pending = false
	if d <= 0.0:
		get_tree().quit()
