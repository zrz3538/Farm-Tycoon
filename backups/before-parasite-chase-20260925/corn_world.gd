extends Node2D

const HOUSE_POINT := Vector2(1035, 500)
var elapsed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(825,105,375,320),Rect2(50,80,680,340)]:
		_add_solid(rect)
	queue_redraw()

func _process(delta: float) -> void:
	if visible:
		elapsed += delta
		queue_redraw()

func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#879f5a"))
	draw_rect(Rect2(0,430,1280,95),Color("#c79658"))
	draw_rect(Rect2(730,310,90,410),Color("#c79658"))
	# Large corn field with alternating rows and visible ears.
	draw_rect(Rect2(50,80,680,355),Color("#765738"))
	for row in range(5):
		for col in range(14):
			var x := 75.0 + col * 46 + (row % 2) * 12
			var y := 112.0 + row * 62
			draw_rect(Rect2(x,y,5,38),Color("#3f713e"))
			draw_rect(Rect2(x-8,y+10,12,5),Color("#5f8b45"))
			draw_rect(Rect2(x+4,y+18,12,5),Color("#6f984b"))
			draw_rect(Rect2(x-3,y+2,11,18),Color("#e0b844"))
			draw_rect(Rect2(x,y+4,4,14),Color("#f2d061"))
	for x in range(48,735,45):
		draw_rect(Rect2(x,70,7,375),Color("#765037"))
	for y in [74,423]: draw_rect(Rect2(48,y,687,8),Color("#9f7046"))
	# Cowboy house.
	draw_rect(Rect2(825,250,375,175),Color("#a75e43"))
	draw_colored_polygon(PackedVector2Array([Vector2(790,250),Vector2(1015,105),Vector2(1235,250)]),Color("#59343a"))
	for y in range(136,245,16): draw_rect(Rect2(835+y%7,y,355-y%13,6),Color("#74434a"))
	for x in range(842,1185,24): draw_rect(Rect2(x,265,5,145),Color("#c47b54"))
	for x in [872,1120]:
		draw_rect(Rect2(x,285,58,65),Color("#ead492")); draw_rect(Rect2(x+7,292,44,51),Color("#75a0a2")); draw_rect(Rect2(x+27,292,4,51),Color("#e7d293")); draw_rect(Rect2(x+7,315,44,4),Color("#e7d293"))
	draw_rect(Rect2(990,325,90,100),Color("#5c392e")); draw_rect(Rect2(1000,335,70,90),Color("#724736")); draw_rect(Rect2(1055,372,7,7),Color("#e1b84d"))
	# Chimney, foundation, flower boxes and porch depth.
	draw_rect(Rect2(1130,120,42,92),Color("#694438")); draw_rect(Rect2(1124,115,54,14),Color("#4b3431"))
	for y in range(132,202,16): draw_rect(Rect2(1134,y,34,4),Color("#8d5c48"))
	draw_rect(Rect2(815,417,395,18),Color("#5c493b"))
	for x in [870,1118]:
		draw_rect(Rect2(x,351,64,14),Color("#754a35"))
		for fx in range(x+6,x+58,12):
			draw_rect(Rect2(fx,342,4,11),Color("#4f7b43")); draw_rect(Rect2(fx-3,340,9,5),Color("#e7c35c"))
	# Porch and yard details.
	draw_rect(Rect2(925,425,215,18),Color("#75523a")); draw_rect(Rect2(945,443,175,12),Color("#a77749"))
	for x in [850,1165]:
		draw_rect(Rect2(x,470,8,46),Color("#604934")); draw_rect(Rect2(x-18,466,44,8),Color("#7b5d3e"))
	var game := get_parent()
	if is_instance_valid(game) and game._skeleton_count() >= 5:
		_draw_house_parasites(game._skeleton_count())
	_draw_marker(HOUSE_POINT, 0)

func _draw_house_parasites(count: int) -> void:
	for i in range(12 + mini(10,count)):
		var angle := elapsed * (0.35 + (i%4)*0.08) + i * 0.51
		var center := Vector2(1015,300)
		var start := center + Vector2(cos(angle)*245.0,sin(angle)*190.0)
		var middle := center + Vector2(cos(angle+0.45)*185.0,sin(angle+0.45)*145.0)
		var finish := center + Vector2(cos(angle+0.9)*135.0,sin(angle+0.9)*105.0)
		draw_polyline(PackedVector2Array([start,middle,finish]),Color("#4b182c"),10.0)
		draw_circle(start,8,Color("#8d2940"))
		draw_circle(start+Vector2(3,-2),2,Color("#efd267"))

func _draw_marker(point: Vector2, index: int) -> void:
	var game := get_parent()
	if not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var bob := roundf(sin(elapsed*3.0+index))*2.0
	var p := point + Vector2(-14,-48+bob)
	var ink := Color("#ffe4a0") if active else Color("#ccad70")
	draw_rect(Rect2(p,Vector2(28,32)),Color("#303b31")); draw_rect(Rect2(p+Vector2(4,4),Vector2(20,24)),Color("#61513b")); draw_rect(Rect2(p+Vector2(11,7),Vector2(6,11)),ink); draw_rect(Rect2(p+Vector2(11,22),Vector2(6,4)),ink)
