extends Control

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var c := Vector2(230,95)
	# Large pixel skull with broken jaw and parasite emerging through the eye.
	draw_rect(Rect2(c-Vector2(64,58),Vector2(128,92)),Color("#dacfae"))
	draw_rect(Rect2(c-Vector2(76,38),Vector2(152,50)),Color("#dacfae"))
	draw_rect(Rect2(c-Vector2(49,-28),Vector2(98,44)),Color("#c2b694"))
	draw_rect(Rect2(c-Vector2(48,25),Vector2(35,31)),Color("#292426"))
	draw_rect(Rect2(c+Vector2(13,-25),Vector2(35,31)),Color("#292426"))
	draw_rect(Rect2(c-Vector2(8,2),Vector2(16,26)),Color("#766a59"))
	for x in range(-39,40,16): draw_rect(Rect2(c+Vector2(x,36),Vector2(9,22)),Color("#f0e5c4"))
	var worm := PackedVector2Array([c+Vector2(30,-10),c+Vector2(68,-28),c+Vector2(92,-4),c+Vector2(118,-35),c+Vector2(145,-12)])
	draw_polyline(worm,Color("#58152d"),13)
	draw_polyline(worm,Color("#9f2944"),6)
	draw_circle(worm[worm.size()-1],10,Color("#bd3850"))
	draw_circle(worm[worm.size()-1]+Vector2(3,-2),3,Color("#f1d460"))
