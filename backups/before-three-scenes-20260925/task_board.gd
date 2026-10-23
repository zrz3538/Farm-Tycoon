extends Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(783, 620, 104, 10), Color("#4a382d"))
	draw_rect(Rect2(790, 622, 9, 49), Color("#67452f"))
	draw_rect(Rect2(871, 622, 9, 49), Color("#67452f"))
	draw_rect(Rect2(776, 548, 118, 80), Color("#49352c"))
	draw_rect(Rect2(781, 553, 108, 70), Color("#986543"))
	draw_rect(Rect2(788, 560, 94, 55), Color("#d5aa68"))
	draw_rect(Rect2(794, 566, 25, 35), Color("#f1e3b2"))
	draw_rect(Rect2(825, 570, 22, 39), Color("#f5d6a0"))
	draw_rect(Rect2(852, 564, 24, 34), Color("#e9edc6"))
	for pin in [Vector2(801, 568), Vector2(833, 572), Vector2(860, 566)]:
		draw_rect(Rect2(pin, Vector2(5, 5)), Color("#b84e42"))
	for y in [577, 585, 593]:
		draw_rect(Rect2(800, y, 13, 3), Color("#8d7053"))
	for y in [580, 588, 596]:
		draw_rect(Rect2(831, y, 10, 3), Color("#9b7350"))
	draw_colored_polygon(PackedVector2Array([Vector2(864,576),Vector2(867,582),Vector2(874,583),Vector2(869,588),Vector2(871,595),Vector2(864,591),Vector2(858,595),Vector2(859,588),Vector2(854,583),Vector2(861,582)]), Color("#f0bf46"))
