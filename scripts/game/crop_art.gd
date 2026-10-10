extends RefCounted
## Atlas sampling only; generated alpha and painted pixels are unchanged.
const WHEAT := preload("res://assets/holiday/objects/wheat-crop-atlas.png")
const CORN := preload("res://assets/holiday/objects/corn-crop-atlas.png")

static func texture(kind: String, stage: String = "grain") -> Texture2D:
	if kind == "grass":
		var art := preload("res://scripts/entities/grass_art.gd")
		return art.texture_for(art.LOOSE if stage == "grain" else art.ROOTED)
	var atlas := AtlasTexture.new()
	atlas.atlas = WHEAT if kind == "wheat" else CORN
	# Roots belong below the soil: sample only the above-ground seedling.
	atlas.region = (Rect2(0,110,450,680) if kind == "wheat" else Rect2(0,250,510,500)) if stage == "seedling" else (Rect2(450,0,610,1024) if kind == "wheat" else Rect2(510,0,550,1024)) if stage == "mature" else (Rect2(1090,520,430,415) if kind == "wheat" else Rect2(1060,310,476,540))
	atlas.filter_clip = true
	return atlas
