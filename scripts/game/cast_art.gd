class_name CastArt
extends RefCounted

const DIRECTORY := "res://assets/holiday/characters/cast_v2/"
const TARGET_HEIGHT := {"llama":100.0,"cow":100.0,"horse":110.0,"sheep":70.0,"goose":70.0,"duck":34.0}
const LEGACY_SCALE := {"llama":0.36,"cow":0.36,"horse":0.36,"sheep":0.36,"goose":0.38,"duck":0.32}
const LEG_START := {"llama":0.76,"cow":0.70,"horse":0.70,"sheep":0.76,"goose":0.79,"duck":0.77}
static var _manifest: Dictionary={}

static func stem_for(config: Dictionary) -> String:
	var id:=str(config.id)
	if id=="sheep_a": return "sheep_clingy"
	if id=="sheep_b": return "sheep_dull"
	if id=="llama": return "llama_smirk"
	return str(config.species)

static func manifest() -> Dictionary:
	if _manifest.is_empty() and FileAccess.file_exists(DIRECTORY+"manifest.json"):
		var value=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"manifest.json"))
		if value is Dictionary:
			_manifest=value
	return _manifest

static func configure(original: Dictionary) -> Dictionary:
	var config:=original.duplicate(true)
	var stem:=stem_for(config)
	if stem=="llama_idle" and not manifest().has(stem):
		stem="llama_smirk"
	var data: Dictionary=manifest().get(stem,{})
	if data.is_empty():
		return config
	var species:=str(config.species)
	var bounds: Array=data.alpha_bbox
	var anchor: Array=data.ground_anchor
	var ratio: float=float(TARGET_HEIGHT[species])/maxf(float(bounds[3]),1.0)/float(LEGACY_SCALE[species])
	config.scale=float(config.scale)*ratio
	config.source_scale_ratio=ratio
	config.native_facing=float(data.native_facing)
	config.ground_anchor=Vector2(float(anchor[0]),float(anchor[1]))
	config.art_bounds=Rect2(float(bounds[0]),float(bounds[1]),float(bounds[2]),float(bounds[3]))
	config.particle_art_scale=1.0/ratio
	if data.has("mouth_anchor"):
		var mouth: Array=data.mouth_anchor
		config.spit_origin=(Vector2(float(mouth[0]),float(mouth[1]))-config.ground_anchor)*Vector2(config.native_facing,1.0)
	config.leg_start=(float(bounds[1])+float(bounds[3])*float(LEG_START[species]))/float(data.height)
	config.textures={"idle":DIRECTORY+stem+".png"}
	if species=="goose":
		# A posture is a different whole painted cel, not a scaled/deformed angry goose.
		config.textures["calm"]=DIRECTORY+"goose_calm.png"
		config.textures["rest"]=DIRECTORY+"goose_rest.png"
		config.textures["riding_up"]=DIRECTORY+"goose_riding_up.png"
		config.textures["riding_down"]=DIRECTORY+"goose_riding_down.png"
		config.posture_metadata={
			"calm": manifest().get("goose_calm",{}),
			"rest": manifest().get("goose_rest",{}),
			"riding_up": manifest().get("goose_riding_up",{}),
			"riding_down": manifest().get("goose_riding_down",{}),
		}
	if species=="llama":
		config.base_texture=DIRECTORY+"llama_smirk.png"
		config.face_region=Rect2(805,225,225,160)
		for expression: String in ["idle","annoyed","happy","smirk"]:
			config.textures[expression]=texture_path("llama",expression)
	# Extra whole-body cels. They do not replace the idle painting.
	if species=="duck" and ResourceLoader.exists(DIRECTORY+"duck_preen.png"):
		config.textures["preen"]=DIRECTORY+"duck_preen.png"
		config.posture_metadata={"preen": manifest().get("duck_preen",{})}
	if species=="duck" and ResourceLoader.exists(DIRECTORY+"duck_attend.png"):
		config.textures["attend"]=DIRECTORY+"duck_attend.png"
		config.posture_metadata=config.get("posture_metadata",{})
		config.posture_metadata["attend"]=manifest().get("duck_attend",{})
	# #180: keep the horse on its standing cel while resting until a same-size
	# tail painting is approved. The current tail body visibly shrinks; do not
	# compensate by distorting actor scale or changing encounter camera framing.
	elif species=="cow" and ResourceLoader.exists(DIRECTORY+"cow_chew.png"):
		config.textures["chew"]=DIRECTORY+"cow_chew.png"
		config.posture_metadata={"chew": manifest().get("cow_chew",{})}
		var grazing := preload("res://scripts/game/cow_ground_art.gd")
		config.textures["graze"] = grazing.TEXTURE
		config.posture_metadata["graze"] = grazing.METADATA
		if ResourceLoader.exists(DIRECTORY+"cow_glance.png"):
			config.textures["glance"]=DIRECTORY+"cow_glance.png"
			config.posture_metadata["glance"]=manifest().get("cow_glance",{})
	elif species=="sheep" and ResourceLoader.exists(DIRECTORY+"sheep_shake.png"):
		config.textures["shake"]=DIRECTORY+"sheep_shake.png"
		config.posture_metadata={"shake": manifest().get("sheep_shake",{})}
	if species=="sheep":
		var grazing := preload("res://scripts/game/sheep_ground_art.gd")
		if grazing.CELLS.has(str(config.id)):
			config.textures["graze"] = grazing.CELLS[str(config.id)].texture
			config.posture_metadata = config.get("posture_metadata", {})
			config.posture_metadata["graze"] = grazing.CELLS[str(config.id)].metadata
		var response := "sheep_clingy_attend_v2" if str(config.id)=="sheep_a" else "sheep_dull_glance_v3"
		if str(config.id) in ["sheep_a", "sheep_b"] and ResourceLoader.exists(DIRECTORY+response+".png"):
			config.textures["attend"]=DIRECTORY+response+".png"
			config.posture_metadata=config.get("posture_metadata",{})
			config.posture_metadata["attend"]=manifest().get(response,{})
	return config

static func texture_path(species: String,expression: String="idle") -> String:
	var stem: String="llama_"+expression if species=="llama" else species
	var path:=DIRECTORY+stem+".png"
	if ResourceLoader.exists(path):
		return path
	if species=="llama" and ResourceLoader.exists(DIRECTORY+"llama_smirk.png"):
		return DIRECTORY+"llama_smirk.png"
	return "res://assets/holiday/characters/"+("llama_"+expression if species=="llama" and expression!="idle" else species)+".png"
