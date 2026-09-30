class_name LayeredHero
extends Node2D

# Region-based use of an imagegen-authored transparent atlas. No destructive
# cuts or raster edits: each complete limb is a rigid sprite with overlap caps.
const ORIGINAL := preload("res://assets/holiday/characters/player.png")
const ATLAS := preload("res://assets/holiday/characters/player_rig_atlas_v1.png")
const PARTS := {
	"rear_thigh": [Rect2(703,462,184,377),Vector2(799,489),Vector2(781,804)],
	"front_thigh": [Rect2(1017,459,187,385),Vector2(1107,487),Vector2(1118,811)],
	"rear_shin": [Rect2(84,845,171,373),Vector2(182,879),Vector2(166,1181)],
	"front_shin": [Rect2(414,846,169,375),Vector2(481,878),Vector2(499,1187)],
	"rear_shoe": [Rect2(19,193,29,27),Vector2(30,195),Vector2(34,215)],
	"front_shoe": [Rect2(49,190,40,30),Vector2(61,194),Vector2(69,211)],
}
var _nodes: Dictionary = {}

func setup() -> void:
	# Far limb first; complete near limb is then free to cross it cleanly.
	for part: String in ["rear_thigh","rear_shin","rear_shoe","front_thigh","front_shin","front_shoe"]:
		var pivot := Node2D.new()
		var sprite := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas=ORIGINAL if part.ends_with("shoe") else ATLAS
		atlas.region=PARTS[part][0]
		atlas.filter_clip=true
		sprite.texture=atlas
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered=false
		pivot.add_child(sprite)
		add_child(pivot)
		_nodes[part]=pivot

func shoe_offset(limb: int) -> Vector2:
	var data: Array=PARTS["rear_shoe" if limb==0 else "front_shoe"]
	return data[1]-data[2]

func pose_limb(limb: int, hip: Vector2, knee: Vector2, ankle: Vector2, sole: Vector2) -> void:
	var prefix := "rear_" if limb==0 else "front_"
	_bone(prefix+"thigh",hip,knee)
	_bone(prefix+"shin",knee,ankle)
	var data: Array=PARTS[prefix+"shoe"]
	var node: Node2D=_nodes[prefix+"shoe"]
	var sprite: Sprite2D=node.get_child(0)
	node.position=sole
	node.rotation=0.0
	node.scale=Vector2.ONE
	sprite.position=-(data[2]-data[0].position)

func _bone(part: String, start: Vector2, finish: Vector2) -> void:
	var data: Array=PARTS[part]
	var node: Node2D=_nodes[part]
	var sprite: Sprite2D=node.get_child(0)
	var width_scale := Vector2(1.45 if part.ends_with("thigh") else 1.35,1.0)
	var source_axis: Vector2=(data[2]-data[1])*width_scale
	var target_axis:=finish-start
	node.position=start
	node.rotation=target_axis.angle()-source_axis.angle()
	node.scale=Vector2.ONE*(target_axis.length()/source_axis.length())
	sprite.scale=width_scale
	sprite.position=-(data[1]-data[0].position)*width_scale
