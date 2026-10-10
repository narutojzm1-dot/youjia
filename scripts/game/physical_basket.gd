class_name PhysicalBasket
extends Sprite2D
## One world entrance to the existing basket; no inventory or save state here.
const ANCHOR := Vector2(335, 485)
const APPROACH := Vector2(335, 522)
const ART := preload("res://assets/holiday/objects/yard_back_basket.png")
const HEIGHT := 70.0

func _init() -> void:
	name = "PhysicalBasket"
	texture = ART
	position = ANCHOR
	offset = Vector2(0, -ART.get_height() * 0.5)
	scale = Vector2.ONE * HEIGHT / ART.get_height()
	z_index = roundi(ANCHOR.y)
