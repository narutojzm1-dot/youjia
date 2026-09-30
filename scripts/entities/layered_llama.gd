class_name LayeredLlama
extends Node2D

# Four complete unoccluded leg paintings, articulated independently. Original
# neutral body/head stay above these hip-overlap caps in PlantedGait.
const ATLAS := preload("res://assets/holiday/characters/llama_legs_atlas_v1.png")
const DATA := [
	[Rect2(250,10,310,610),Vector2(400,150),Vector2(384,363),Vector2(413,548),Vector2(420,601),62.0],
	[Rect2(710,24,310,594),Vector2(859,163),Vector2(855,382),Vector2(910,546),Vector2(917,598),52.0],
	[Rect2(276,635,288,590),Vector2(410,761),Vector2(430,946),Vector2(471,1157),Vector2(478,1208),70.0],
	[Rect2(724,635,284,584),Vector2(853,760),Vector2(869,968),Vector2(928,1152),Vector2(936,1206),61.0],
]
var _meshes: Array[Polygon2D] = []
var _sources: Array[PackedVector2Array] = []
var sole_world_positions: Array[Vector2] = []

func setup() -> void:
	for index: int in DATA.size():
		var data: Array=DATA[index]
		var rect: Rect2=data[0]
		var source := PackedVector2Array()
		var ys: Array[float]=[rect.position.y,data[1].y,lerpf(data[1].y,data[2].y,0.5),data[2].y-20,data[2].y,data[2].y+20,lerpf(data[2].y,data[3].y,0.6),data[3].y,data[4].y,rect.end.y]
		var xs: Array[float]=[rect.position.x,lerpf(rect.position.x,rect.end.x,0.25),data[4].x,lerpf(rect.position.x,rect.end.x,0.75),rect.end.x]
		xs.sort()
		for y: float in ys:
			for x: float in xs:
				source.append(Vector2(x,y))
		var cells: Array[PackedInt32Array]=[]
		for row: int in ys.size()-1:
			for col: int in 4:
				var i:=row*5+col
				cells.append(PackedInt32Array([i,i+1,i+6,i+5]))
		var mesh:=Polygon2D.new()
		mesh.texture=ATLAS
		mesh.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		mesh.uv=source
		mesh.polygon=source
		mesh.polygons=cells
		# Far legs behind their near partners.
		mesh.z_index=0 if index in [1,3] else 1
		add_child(mesh)
		_meshes.append(mesh)
		_sources.append(source)
		sole_world_positions.append(Vector2.ZERO)

func shoe_offset(index: int) -> Vector2:
	var data: Array=DATA[index]
	return (data[3]-data[4])*(data[5]/(data[4].y-data[1].y))

func pose_limb(index: int, hip: Vector2, knee: Vector2, ankle: Vector2, sole: Vector2) -> void:
	var data: Array=DATA[index]
	var source_hip: Vector2=data[1]
	var source_knee: Vector2=data[2]
	var source_ankle: Vector2=data[3]
	var source_sole: Vector2=data[4]
	var upper_angle: float=(knee-hip).angle()-(source_knee-source_hip).angle()
	var lower_angle: float=(ankle-knee).angle()-(source_ankle-source_knee).angle()
	var upper_scale: float=hip.distance_to(knee)/source_hip.distance_to(source_knee)
	var lower_scale: float=knee.distance_to(ankle)/source_knee.distance_to(source_ankle)
	var hoof_scale: float=data[5]/(source_sole.y-source_hip.y)
	var vertices:=PackedVector2Array()
	for point: Vector2 in _sources[index]:
		var upper:=hip+(point-source_hip).rotated(upper_angle)*upper_scale
		var lower:=knee+(point-source_knee).rotated(lower_angle)*lower_scale
		var posed:=upper.lerp(lower,smoothstep(source_knee.y-20,source_knee.y+20,point.y))
		posed=posed.lerp(sole+(point-source_sole)*hoof_scale,smoothstep(source_ankle.y-20,source_ankle.y,point.y))
		vertices.append(posed)
	_meshes[index].polygon=vertices
	sole_world_positions[index]=to_global(sole)
