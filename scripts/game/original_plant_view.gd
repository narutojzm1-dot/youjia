extends Node2D
## Three independent cutouts over the unchanged painting. State is confirmed
## SaveStore data; photos replay an inert bounded record, never the live garden.
const Model := preload("res://scripts/inventory/yard_original_plants.gd")
const CLEAR_SHADER := preload("res://shaders/original_plant_clear.gdshader")
# Photo recipe 1 is immutable once shipped: retain these asset bytes, polygons,
# registration, grades and feather when adding a later recipe/version.
const ART_VERSION := 1
const SUNNY_PATH := "res://assets/holiday/environment/original_plants_v1/clean_sunny_v1.png"
const CLOUDY_PATH := "res://assets/holiday/environment/original_plants_v1/clean_overcast_v1.png"
const POND_SUNNY_PATH := "res://assets/holiday/environment/original_plants_v1/pond_sunny_v3.png"
const POND_CLOUDY_PATH := "res://assets/holiday/environment/original_plants_v1/pond_overcast_v2.png"
# This crop occupied (435,645)-(697,845) in the 1672x941 source plate.
# The generated patch may have a different resolution; its registration does not.
const POND_SOURCE_RECT := Vector4(435.0/1672.0,645.0/941.0,262.0/1672.0,200.0/941.0)
const FULL_SOURCE_RECT := Vector4(0,0,1,1)
# Static sunny/overcast cutouts passed local review on 2026-10-13.
# Ordinary Web interaction and public release remain separately verified.
const ART_ACCEPTED := true
const WORLD_SIZE := Vector2(1280,720)
const SOURCE_SCALE := 1.5
const SOURCE_POINTS := {
	"left_cluster": [Vector2(0,594),Vector2(67,595),Vector2(140,612),Vector2(203,642),Vector2(213,665),Vector2(208,744),Vector2(223,780),Vector2(228,844),Vector2(163,908),Vector2(86,907),Vector2(0,900)],
	"door_pots": [Vector2(268,607),Vector2(310,589),Vector2(341,600),Vector2(365,629),Vector2(363,690),Vector2(303,702),Vector2(272,686),Vector2(264,650)],
	"pond_cluster": [Vector2(550,845),Vector2(588,825),Vector2(621,816),Vector2(652,790),Vector2(730,790),Vector2(742,847),Vector2(747,869),Vector2(721,905),Vector2(685,920),Vector2(648,909),Vector2(586,930),Vector2(554,900)],
}
var patches: Dictionary = {}
var record: Dictionary = {}

static func enabled() -> bool:
	return ART_ACCEPTED and _plates_available()

static func _plates_available() -> bool:
	for path: String in [SUNNY_PATH,CLOUDY_PATH,POND_SUNNY_PATH,POND_CLOUDY_PATH]:
		if not ResourceLoader.exists(path,"Texture2D"): return false
	return true

static func plate_source(area: String, cloudy: bool) -> Dictionary:
	if area == "pond_cluster":
		return {"path":POND_CLOUDY_PATH if cloudy else POND_SUNNY_PATH,"rect":POND_SOURCE_RECT}
	return {"path":CLOUDY_PATH if cloudy else SUNNY_PATH,"rect":FULL_SOURCE_RECT}

static func points(area: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in SOURCE_POINTS.get(area,[]): out.append(point / SOURCE_SCALE)
	return out

func build() -> void:
	if not patches.is_empty(): return
	if not _plates_available(): return
	for area: String in Model.AREAS:
		var sun_source := plate_source(area,false)
		var cloud_source := plate_source(area,true)
		var sunny := load(sun_source.path) as Texture2D
		var cloudy := load(cloud_source.path) as Texture2D
		var piece := Polygon2D.new()
		piece.name = area
		piece.polygon = points(area)
		piece.texture = sunny
		piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var uv := PackedVector2Array()
		for point: Vector2 in piece.polygon: uv.append(point * sunny.get_size() / WORLD_SIZE)
		piece.uv = uv
		piece.z_index = -1
		var material := ShaderMaterial.new()
		material.shader = CLEAR_SHADER
		material.set_shader_parameter("cloudy_plate",cloudy)
		material.set_shader_parameter("sun_source_rect",sun_source.rect)
		material.set_shader_parameter("cloud_source_rect",cloud_source.rect)
		if area == "pond_cluster":
			material.set_shader_parameter("sun_grade",Vector3(1.0,1.0,0.0))
			material.set_shader_parameter("cloud_grade",Vector3(0.82,0.88,0.0))
			material.set_shader_parameter("feather",5.0)
		var edges := piece.polygon.duplicate()
		edges.resize(16)
		material.set_shader_parameter("edge_points",edges)
		material.set_shader_parameter("edge_count",piece.polygon.size())
		piece.material = material
		piece.visible = false
		add_child(piece)
		patches[area] = piece

func sync(state: Dictionary, mix: float, sunny_tint: Color, cloudy_tint: Color) -> void:
	if Model.read({Model.FIELD:state}).is_empty(): return
	restore({"art_version":ART_VERSION,"removed":state.removed,"mix":mix,"sun":[sunny_tint.r,sunny_tint.g,sunny_tint.b,sunny_tint.a],"cloud":[cloudy_tint.r,cloudy_tint.g,cloudy_tint.b,cloudy_tint.a]})

func restore(raw: Variant) -> void:
	var cleaned := sanitize(raw)
	if cleaned.is_empty(): return
	build()
	record = cleaned
	for area: String in patches:
		var piece: Polygon2D = patches[area]
		piece.visible = area in record.removed
		piece.material.set_shader_parameter("weather_mix",record.mix)
		piece.material.set_shader_parameter("sun_tint",Color(record.sun[0],record.sun[1],record.sun[2],record.sun[3]))
		piece.material.set_shader_parameter("cloud_tint",Color(record.cloud[0],record.cloud[1],record.cloud[2],record.cloud[3]))

static func sanitize(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not raw.get("removed") is Array: return {}
	# The original unpublished fixtures had no version; their recipe is v1.
	var version: Variant = raw.get("art_version",ART_VERSION)
	if not (version is int or version is float) or not is_finite(float(version)) or float(version) != ART_VERSION: return {}
	if Model.read({Model.FIELD:{"schema":1,"revision":0,"removed":raw.removed}}).is_empty(): return {}
	if not _number(raw.get("mix"),1.0): return {}
	for key: String in ["sun","cloud"]:
		if not raw.get(key) is Array or raw[key].size() != 4: return {}
		for number: Variant in raw[key]:
			if not _number(number,2.0): return {}
	return {"art_version":ART_VERSION,"removed":raw.removed.duplicate(),"mix":float(raw.mix),"sun":raw.sun.duplicate(),"cloud":raw.cloud.duplicate()}

static func _number(value: Variant, upper: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= upper
