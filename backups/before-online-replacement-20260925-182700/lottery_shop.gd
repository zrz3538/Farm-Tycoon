extends Node2D

func _draw() -> void:
	var x := 355.0
	var y := 548.0
	draw_rect(Rect2(x - 8, y + 84, 166, 13), Color("#40503d", 0.45))
	draw_rect(Rect2(x, y + 21, 150, 70), Color("#59453c"))
	draw_rect(Rect2(x + 5, y + 25, 140, 61), Color("#98704f"))
	for px in range(362, 500, 14):
		draw_rect(Rect2(px, y + 25, 2, 61), Color("#6b4f42"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 10, y + 23), Vector2(x + 28, y - 9),
		Vector2(x + 122, y - 9), Vector2(x + 160, y + 23)
	]), Color("#493652"))
	for px in range(367, 493, 15):
		draw_rect(Rect2(px, y + 4 + int(px) % 3, 11, 5), Color("#74547d"))
		draw_rect(Rect2(px + 4, y + 10 + int(px) % 2, 12, 5), Color("#65456e"))
	draw_rect(Rect2(x - 9, y + 21, 168, 5), Color("#322c39"))
	draw_rect(Rect2(x + 58, y - 28, 35, 26), Color("#382f43"))
	draw_rect(Rect2(x + 61, y - 25, 29, 20), Color("#d6ae4e"))
	var star := PackedVector2Array([
		Vector2(x + 75, y - 23), Vector2(x + 79, y - 16),
		Vector2(x + 87, y - 15), Vector2(x + 81, y - 10),
		Vector2(x + 83, y - 4), Vector2(x + 75, y - 8),
		Vector2(x + 67, y - 4), Vector2(x + 69, y - 11),
		Vector2(x + 63, y - 15), Vector2(x + 71, y - 16)
	])
	draw_colored_polygon(star, Color("#fff0a0"))
	for offset in [12, 88]:
		draw_rect(Rect2(x + offset, y + 36, 49, 38), Color("#3a3440"))
		draw_rect(Rect2(x + offset + 4, y + 40, 41, 25), Color("#b9d2c0"))
		for i in 5:
			var colors := [Color("#d76764"), Color("#e4bd55"), Color("#668ac0"), Color("#8c69a7")]
			draw_rect(Rect2(x + offset + 7 + i * 7, y + 54 - (i % 2) * 5, 6, 6), colors[(i + offset) % 4])
		draw_rect(Rect2(x + offset + 20, y + 77, 10, 5), Color("#d5b567"))
	draw_rect(Rect2(x + 68, y + 40, 14, 45), Color("#43353b"))
	draw_rect(Rect2(x + 72, y + 45, 6, 6), Color("#f2c85f"))
