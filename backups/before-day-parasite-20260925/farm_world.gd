extends Node2D

const BARN_POINT := Vector2(175, 650)
const TANK_POINT := Vector2(628, 650)
const MARKET_POINT := Vector2(1090, 650)
const TRUCK_POINT := Vector2(1040, 350)
const LOTTERY_POINT := Vector2(430, 650)
const TASK_POINT := Vector2(835, 205)

var solid_rects := [Rect2(35,55,735,350),Rect2(55,525,240,145),Rect2(555,530,165,100),Rect2(970,530,250,130),Rect2(900,240,330,105),Rect2(795,85,120,85),Rect2(350,540,160,100)]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var markers := Node2D.new()
	markers.set_script(preload("res://interaction_markers.gd"))
	markers.z_index = 8
	add_child(markers)
	var liquid := Node2D.new()
	liquid.name = "TankLiquid"
	liquid.set_script(preload("res://tank_liquid.gd"))
	liquid.z_index = 2
	add_child(liquid)
	var lottery := Node2D.new()
	lottery.set_script(preload("res://lottery_shop.gd"))
	lottery.z_index = 1
	add_child(lottery)
	var board := Node2D.new()
	board.name = "TaskBoard"
	board.set_script(preload("res://task_board.gd"))
	board.z_index = 1
	add_child(board)
	for rect in solid_rects: _add_solid(rect)
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
	draw_rect(Rect2(0,0,1280,720),Color("#789b59"))
	draw_rect(Rect2(35,55,735,350),Color("#91ad68"))
	draw_rect(Rect2(0,415,1280,95),Color("#c99a5e"))
	draw_rect(Rect2(610,405,70,315),Color("#c99a5e"))
	for x in range(14,1270,53):
		for y in range(72,705,67):
			if y < 410 or y > 512: draw_rect(Rect2(x+(y%17),y,3,9),Color("#5f8649"))
	for x in range(38,771,47):
		draw_rect(Rect2(x,51,7,365),Color("#80583a")); draw_rect(Rect2(x+2,51,2,365),Color("#b38250"))
	for y in [62,94,383]:
		draw_rect(Rect2(35,y,735,7),Color("#795238")); draw_rect(Rect2(35,y,735,2),Color("#c09159"))
	# Barn.
	draw_rect(Rect2(55,552,240,118),Color("#7f3d31"))
	draw_colored_polygon(PackedVector2Array([Vector2(42,552),Vector2(175,490),Vector2(308,552)]),Color("#572d2d"))
	for x in range(67,286,19): draw_rect(Rect2(x,560,4,103),Color("#a95a43"))
	draw_rect(Rect2(139,590,73,80),Color("#58372c"))
	for y in [604,630]: draw_rect(Rect2(149,y,53,4),Color("#b0714f"))
	for x in [82,238]:
		draw_rect(Rect2(x,576,38,42),Color("#e5c982")); draw_rect(Rect2(x+6,582,26,30),Color("#7da0a1"))
	# Market.
	draw_rect(Rect2(970,555,250,105),Color("#e4bc72")); draw_rect(Rect2(985,585,220,62),Color("#704336"))
	for x in range(970,1220,42):
		draw_rect(Rect2(x,532,25,32),Color("#f4e4bd")); draw_rect(Rect2(x+25,532,17,32),Color("#b94e43"))
	draw_rect(Rect2(1000,601,70,28),Color("#90a85f")); draw_rect(Rect2(1105,601,70,28),Color("#e2bf45"))
	# Truck.
	draw_rect(Rect2(900,252,225,75),Color("#a9895b"))
	for x in range(910,1120,42): draw_rect(Rect2(x,258,7,58),Color("#694c36"))
	draw_rect(Rect2(1125,245,80,82),Color("#3f696a")); draw_rect(Rect2(1136,254,38,31),Color("#8bb0b5")); draw_rect(Rect2(1178,294,43,33),Color("#537a75"))
	for x in [925,1080,1170]:
		draw_circle(Vector2(x,331),15,Color("#30383a")); draw_circle(Vector2(x,331),7,Color("#87918e"))
	# Milk tank centered between the shops.
	draw_rect(Rect2(552,604,174,18),Color("#465b58",0.45))
	draw_rect(Rect2(558,538,160,74),Color("#6f8583"))
	draw_rect(Rect2(568,548,140,54),Color("#c9d8d2"))
	draw_rect(Rect2(578,553,96,45),Color("#aabfbd"))
	draw_rect(Rect2(604,525,55,13),Color("#4d6260"))
	draw_rect(Rect2(704,570,28,11),Color("#506c66"))
