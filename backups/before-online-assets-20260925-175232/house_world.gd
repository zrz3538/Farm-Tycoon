extends Node2D

const EXIT_POINT := Vector2(640, 650)
const BED_POINT := Vector2(220, 335)
const WAKE_POINT := Vector2(385, 335)
const ARMORY_POINT := Vector2(1045, 585)
var elapsed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(0,54,1280,42),Rect2(0,54,38,666),Rect2(1242,54,38,666),Rect2(0,690,565,30),Rect2(715,690,565,30),Rect2(90,135,260,170),Rect2(930,120,250,175),Rect2(480,255,315,115)]:
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
	# Walls and plank floor.
	draw_rect(Rect2(0,54,1280,666),Color("#d7bd84"))
	draw_rect(Rect2(38,96,1204,594),Color("#a86f48"))
	for y in range(100,690,26):
		draw_rect(Rect2(38,y,1204,4),Color("#805038"))
	for x in range(60,1240,95): draw_rect(Rect2(x,96,3,594),Color("#b98359",0.7))
	# Back wall panels and windows.
	draw_rect(Rect2(38,96,1204,125),Color("#ead8a5"))
	for x in [410,790]:
		draw_rect(Rect2(x,120,100,75),Color("#684739")); draw_rect(Rect2(x+8,128,84,59),Color("#8eb5b4")); draw_rect(Rect2(x+48,128,6,59),Color("#f1dfac")); draw_rect(Rect2(x+8,156,84,6),Color("#f1dfac"))
	# Bed and side table.
	draw_rect(Rect2(90,170,260,135),Color("#583c32")); draw_rect(Rect2(105,182,230,105),Color("#e7d59f")); draw_rect(Rect2(105,230,230,57),Color("#7f9e73")); draw_rect(Rect2(120,192,75,34),Color("#fff0c5"))
	draw_rect(Rect2(365,245,72,60),Color("#704b34")); draw_rect(Rect2(373,253,56,42),Color("#9b6a42")); draw_rect(Rect2(393,236,16,17),Color("#e5c65a"))
	# Kitchen counter, stove and shelves.
	draw_rect(Rect2(930,165,250,130),Color("#77503a")); draw_rect(Rect2(945,180,220,98),Color("#c79a62")); draw_rect(Rect2(952,188,70,80),Color("#6e7f78")); draw_rect(Rect2(966,200,42,28),Color("#2f3b3b")); draw_rect(Rect2(1040,195,105,16),Color("#eee0b4"))
	for x in [1050,1090,1130]: draw_rect(Rect2(x,222,24,36),Color("#84a09b"))
	# Dining table and rug.
	draw_rect(Rect2(445,400,390,190),Color("#85525b")); draw_rect(Rect2(470,425,340,140),Color("#bf775e")); draw_rect(Rect2(500,455,280,80),Color("#d79a69"))
	draw_rect(Rect2(480,280,315,90),Color("#714b35")); draw_rect(Rect2(465,265,345,35),Color("#b47a4d")); draw_rect(Rect2(500,298,18,72),Color("#694630")); draw_rect(Rect2(757,298,18,72),Color("#694630"))
	# Fireplace.
	draw_rect(Rect2(90,360,180,180),Color("#795040")); draw_rect(Rect2(110,395,140,125),Color("#49322e")); draw_rect(Rect2(132,438,96,70),Color("#2d2928")); draw_colored_polygon(PackedVector2Array([Vector2(155,495),Vector2(176,443),Vector2(192,482),Vector2(208,452),Vector2(220,498)]),Color("#e96b35")); draw_rect(Rect2(80,350,200,22),Color("#553d35"))
	# Exit door and mat.
	draw_rect(Rect2(575,590,130,100),Color("#4f342b")); draw_rect(Rect2(588,602,104,88),Color("#714634")); draw_rect(Rect2(675,642,8,8),Color("#e4bd58")); draw_rect(Rect2(550,665,180,25),Color("#655146"))
	# Reinforced indoor armory room and detailed weapon racks.
	draw_rect(Rect2(875,385,325,250),Color("#4b4b48")); draw_rect(Rect2(892,405,291,210),Color("#303638")); draw_rect(Rect2(900,414,275,12),Color("#767269"))
	for y in [455,515]:
		draw_rect(Rect2(920,y,225,8),Color("#76614a"))
		for x in range(935,1135,50):
			draw_rect(Rect2(x,y-18,38,5),Color("#aeb5ae")); draw_rect(Rect2(x+8,y-14,7,12),Color("#5d4937")); draw_rect(Rect2(x+28,y-20,28,3),Color("#525d60"))
	draw_rect(Rect2(985,550,120,65),Color("#56514a")); draw_rect(Rect2(995,560,100,45),Color("#777065")); draw_rect(Rect2(1038,570,13,22),Color("#d1a957"))
	_draw_marker(EXIT_POINT,0)
	_draw_marker(BED_POINT,1)
	_draw_marker(ARMORY_POINT,2)
	var game := get_parent()
	if is_instance_valid(game) and game._skeleton_count() >= 5:
		for i in 8:
			var y := 130.0+i*66.0
			var length := 90.0+sin(elapsed*2.0+i)*28.0
			draw_line(Vector2(38,y),Vector2(38+length,y+18),Color("#4b182c"),9)
			draw_circle(Vector2(38+length,y+18),7,Color("#8d2940"))

func _draw_marker(point: Vector2, index: int) -> void:
	var game := get_parent()
	if not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var p := point + Vector2(-14,-52+roundf(sin(elapsed*3.0+index))*2.0)
	var ink := Color("#ffe4a0") if active else Color("#ccad70")
	draw_rect(Rect2(p,Vector2(28,32)),Color("#303b31")); draw_rect(Rect2(p+Vector2(4,4),Vector2(20,24)),Color("#61513b")); draw_rect(Rect2(p+Vector2(11,7),Vector2(6,11)),ink); draw_rect(Rect2(p+Vector2(11,22),Vector2(6,4)),ink)
