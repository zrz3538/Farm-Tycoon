extends Control

var weapon_id := "shotgun"

func _ready() -> void:
	size=Vector2(100,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var metal:=Color("#a9b0ab")
	var dark:=Color("#30383a")
	var wood:=Color("#875b36")
	var length:=82.0
	var body:=42.0
	if weapon_id=="m700": length=96; body=48
	elif weapon_id=="deagle": length=59; body=32
	elif weapon_id=="mp5": length=67; body=38
	elif weapon_id=="m249": length=96; body=55
	draw_rect(Rect2(7,18,body,9),wood if weapon_id in ["shotgun","m700","ak47"] else dark)
	draw_rect(Rect2(25,16,length-28,7),metal)
	draw_rect(Rect2(length-6,18,12,3),metal.lightened(0.18))
	draw_rect(Rect2(15,27,10,9),dark)
	if weapon_id in ["m4a1","ar15","ak47","mp5","scarh","m249"]:
		draw_colored_polygon(PackedVector2Array([Vector2(31,25),Vector2(43,25),Vector2(40,39),Vector2(34,39)]),dark)
	if weapon_id in ["m700","scarh"]:
		draw_rect(Rect2(34,10,28,5),Color("#202629")); draw_rect(Rect2(39,8,5,4),metal)
	if weapon_id=="shotgun":
		draw_rect(Rect2(36,13,55,3),Color("#596568")); draw_rect(Rect2(36,22,55,3),Color("#596568"))
	if weapon_id=="m249":
		draw_rect(Rect2(38,26,26,13),Color("#69705d")); draw_line(Vector2(74,24),Vector2(86,40),dark,4)
