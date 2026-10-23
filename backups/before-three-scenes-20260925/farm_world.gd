extends Node2D
const BARN_POINT := Vector2(198, 695)
const TANK_POINT := Vector2(628, 635)
const MARKET_POINT := Vector2(1090, 662)
const TRUCK_POINT := Vector2(1015, 352)
const LOTTERY_POINT := Vector2(430, 670)
const TASK_POINT := Vector2(835, 665)
const BACKGROUND := preload("res://assets/farm.svg")
var solid_rects := [Rect2(40, 76, 724, 310), Rect2(80, 541, 227, 130), Rect2(555, 519, 163, 97), Rect2(974, 547, 245, 89), Rect2(886, 219, 332, 110), Rect2(355, 548, 150, 91), Rect2(776, 548, 118, 80)]

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
	for rect in solid_rects:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.position = rect.get_center()
		body.add_child(collision)
		add_child(body)

func _draw() -> void:
	draw_texture(BACKGROUND, Vector2.ZERO)
