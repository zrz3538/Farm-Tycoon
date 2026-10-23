extends Node2D

const PASTURE_POINT := Vector2(790, 360)
const BARN_POINT := Vector2(330, 610)
const TANK_POINT := Vector2(650, 575)
const MARKET_POINT := Vector2(1050, 575)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Layered grass tiles: hand-placed pixels keep the field from feeling flat.
	draw_rect(Rect2(0, 0, 1280, 720), Color("#78b657"))
	for y in range(16, 720, 32):
		for x in range(12, 1280, 40):
			var shift := 9 if floori(y / 32.0) % 2 else 0
			draw_rect(Rect2(x + shift, y, 3, 8), Color("#639d49"))
			draw_rect(Rect2(x + shift + 4, y + 3, 3, 5), Color("#91ca68"))

	# Dirt paths connecting all interaction points.
	draw_rect(Rect2(0, 430, 1280, 112), Color("#c99b5d"))
	draw_rect(Rect2(600, 330, 105, 390), Color("#c99b5d"))
	for x in range(8, 1280, 36):
		draw_rect(Rect2(x, 448 + (x % 3) * 12, 7, 4), Color("#ae7d48"))
	for y in range(350, 710, 30):
		draw_rect(Rect2(620 + (y % 4) * 9, y, 8, 5), Color("#ae7d48"))

	# Pasture fence and sign.
	draw_rect(Rect2(32, 44, 760, 14), Color("#704628"))
	draw_rect(Rect2(32, 374, 760, 14), Color("#704628"))
	for x in range(40, 793, 58):
		draw_rect(Rect2(x, 34, 12, 35), Color("#98613a"))
		draw_rect(Rect2(x, 363, 12, 37), Color("#98613a"))
	draw_rect(Rect2(752, 337, 77, 41), Color("#e2bd70"))
	draw_rect(Rect2(760, 346, 61, 25), Color("#6f482d"))
	draw_string(ThemeDB.fallback_font, Vector2(766, 364), "牧场", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff2c4"))

	_draw_barn(Vector2(70, 505))
	_draw_tank(Vector2(570, 490))
	_draw_market(Vector2(955, 475))
	_draw_marker(PASTURE_POINT, Color("#9ae8ff"), "靠近后拖动奶牛")
	_draw_marker(BARN_POINT, Color("#ffe069"), "E 升级奶罐")
	_draw_marker(TANK_POINT, Color("#d9f4ff"), "E/F 取奶")
	_draw_marker(MARKET_POINT, Color("#ffdc77"), "E/F 卖奶")

func _draw_barn(p: Vector2) -> void:
	draw_rect(Rect2(p.x, p.y + 42, 235, 145), Color("#833b2f"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-15, 48), p + Vector2(117, -18), p + Vector2(250, 48)]), Color("#542b2a"))
	draw_rect(Rect2(p.x + 18, p.y + 62, 42, 38), Color("#ead59b"))
	draw_rect(Rect2(p.x + 174, p.y + 62, 42, 38), Color("#ead59b"))
	draw_rect(Rect2(p.x + 83, p.y + 92, 70, 95), Color("#4f2a25"))
	draw_rect(Rect2(p.x + 113, p.y + 92, 9, 95), Color("#a85a3e"))
	draw_string(ThemeDB.fallback_font, p + Vector2(73, 73), "谷 仓", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#fff0c1"))

func _draw_tank(p: Vector2) -> void:
	draw_rect(Rect2(p.x + 5, p.y + 12, 145, 105), Color("#8ba5ad"))
	draw_rect(Rect2(p.x + 14, p.y + 18, 127, 91), Color("#d9e5e5"))
	draw_rect(Rect2(p.x + 24, p.y + 25, 16, 75), Color("#f6ffff"))
	draw_rect(Rect2(p.x + 2, p.y + 112, 155, 12), Color("#526970"))
	draw_rect(Rect2(p.x + 67, p.y - 4, 28, 18), Color("#526970"))
	draw_rect(Rect2(p.x + 148, p.y + 72, 26, 13), Color("#526970"))
	draw_rect(Rect2(p.x + 167, p.y + 79, 9, 20), Color("#526970"))
	draw_string(ThemeDB.fallback_font, p + Vector2(45, 73), "牛奶罐", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#40545a"))

func _draw_market(p: Vector2) -> void:
	draw_rect(Rect2(p.x, p.y + 35, 250, 145), Color("#f3d390"))
	draw_rect(Rect2(p.x - 12, p.y + 20, 274, 32), Color("#b4473b"))
	for x in range(0, 274, 46):
		draw_rect(Rect2(p.x - 12 + x, p.y + 20, 23, 32), Color("#fff0d0"))
	draw_rect(Rect2(p.x + 22, p.y + 75, 205, 65), Color("#74442c"))
	draw_rect(Rect2(p.x + 38, p.y + 90, 45, 35), Color("#89b65f"))
	draw_rect(Rect2(p.x + 100, p.y + 87, 38, 38), Color("#df774d"))
	draw_rect(Rect2(p.x + 158, p.y + 92, 48, 33), Color("#e7c64e"))
	draw_string(ThemeDB.fallback_font, p + Vector2(82, 70), "农 场 市 场", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#6c342b"))

func _draw_marker(pos: Vector2, color: Color, text: String) -> void:
	draw_circle(pos, 24, Color(color, 0.24))
	draw_arc(pos, 24, 0, TAU, 20, color, 3.0)
	draw_rect(Rect2(pos.x - 4, pos.y - 9, 8, 18), color)
	draw_rect(Rect2(pos.x - 4, pos.y + 13, 8, 5), color)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-62, 43), text, HORIZONTAL_ALIGNMENT_CENTER, 124, 14, Color("#263b24"))
