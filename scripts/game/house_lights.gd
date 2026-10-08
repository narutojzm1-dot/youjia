extends Node2D
var lights := 0.0

func _draw() -> void:
	if lights <= 0.0: return
	# Separate panes preserve the painted frames and flower boxes.
	for pane: Rect2 in [Rect2(98,351,13,35),Rect2(116,351,13,35),Rect2(335,359,11,26),Rect2(350,359,10,26),Rect2(268,231,11,19),Rect2(284,231,11,19)]:
		draw_rect(pane,Color(1.0,0.68,0.22,lights * 0.6))
		draw_rect(pane.grow(2.0),Color(1.0,0.62,0.2,lights * 0.08))
