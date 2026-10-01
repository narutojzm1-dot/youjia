class_name GrassArt
extends RefCounted

# One painterly atlas keeps the rooted, clipped and gathered blades related.
# Atlas regions sample the generated pixels unchanged, with uniform scaling.
const ATLAS := preload("res://assets/holiday/fx/grass_states_v2.png")
const ROOTED := Rect2(64, 40, 474, 918)
const STUBBLE := Rect2(562, 660, 328, 298)
const LOOSE := Rect2(938, 566, 558, 380)
const LOOSE_GRIP := Vector2(62, 245)
const HELD_WIDTH := 31.0
const HELD_ROTATION := -0.32

static func texture_for(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = region
	texture.filter_clip = true
	return texture

static func rooted_sprite(region: Rect2, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture_for(region)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	sprite.offset = Vector2(-region.size.x * 0.5, -region.size.y + 9.0)
	sprite.scale = Vector2.ONE * width / region.size.x
	return sprite

static func configure_bundle(sprite: Sprite2D) -> void:
	sprite.texture = texture_for(LOOSE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	# The cut stems sit inside the hand; the loose leaf tips point outward.
	sprite.offset = -LOOSE_GRIP
