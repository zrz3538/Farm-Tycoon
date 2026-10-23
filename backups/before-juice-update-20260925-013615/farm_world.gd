extends Node2D
const PASTURE_POINT := Vector2(790, 370)
const BARN_POINT := Vector2(198, 695)
const TANK_POINT := Vector2(628, 635)
const MARKET_POINT := Vector2(1090, 662)
const TRUCK_POINT := Vector2(1015, 352)
const BACKGROUND := preload("res://assets/farm.svg")
var solid_rects := [Rect2(40, 76, 724, 310), Rect2(80, 541, 227, 130), Rect2(555, 519, 163, 97), Rect2(974, 547, 245, 89), Rect2(886, 219, 332, 110)]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var markers := Node2D.new()
	markers.set_script(preload("res://interaction_markers.gd"))
	markers.z_index = 8
	add_child(markers)
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
	var font := ThemeDB.fallback_font
	for item in [[Vector2(923, 194), "奶牛商人 · 50 金币"], [Vector2(160, 530), "谷仓"], [Vector2(591, 507), "奶罐"], [Vector2(1047, 530), "市场"]]:
		draw_string(font, item[0], item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f3e4bb"))
