extends Node2D

func _draw() -> void:
	var x := 795.0
	var y := 85.0
	draw_rect(Rect2(x+8,y+78,104,9),Color("#4a382d")); draw_rect(Rect2(x+15,y+80,9,52),Color("#67452f")); draw_rect(Rect2(x+96,y+80,9,52),Color("#67452f"))
	draw_rect(Rect2(x,y,120,86),Color("#49352c")); draw_rect(Rect2(x+6,y+6,108,72),Color("#986543")); draw_rect(Rect2(x+13,y+13,94,57),Color("#d5aa68"))
	for note in [Rect2(x+19,y+19,25,35),Rect2(x+50,y+23,22,39),Rect2(x+77,y+17,24,34)]: draw_rect(note,Color("#f3e1ad"))
	for pin in [Vector2(x+26,y+21),Vector2(x+58,y+25),Vector2(x+85,y+19)]: draw_rect(Rect2(pin,Vector2(5,5)),Color("#b84e42"))
	for ly in [30,38,46]: draw_rect(Rect2(x+25,y+ly,13,3),Color("#8d7053"))
	draw_colored_polygon(PackedVector2Array([Vector2(x+89,y+29),Vector2(x+93,y+36),Vector2(x+101,y+37),Vector2(x+95,y+42),Vector2(x+97,y+50),Vector2(x+89,y+46),Vector2(x+82,y+50),Vector2(x+84,y+42),Vector2(x+78,y+37),Vector2(x+86,y+36)]),Color("#f0bf46"))
