extends Node2D

var elapsed := 0.0

func _process(delta: float) -> void:
	var game := get_parent().get_parent()
	visible = game.playing and not game.suspended
	if visible:
		elapsed += delta
		queue_redraw()

func _draw() -> void:
	var game := get_parent().get_parent()
	if not is_instance_valid(game.player):
		return
	var world := get_parent()
	var points := [world.TRUCK_POINT, world.TANK_POINT, world.BARN_POINT, world.MARKET_POINT]
	var ranges := [100.0, 105.0, 105.0, 110.0]
	for i in points.size():
		var point: Vector2 = points[i]
		var active: bool = game.player.faces_point(point, ranges[i])
		var ink := Color("#ffe4a0") if active else Color("#ccad70")
		var fill := Color("#697f48") if active else Color("#594d39")
		var bob := roundf(sin(elapsed * 3.0 + i * 0.8)) * 2.0
		var p := point + Vector2(-10, -35 + bob)
		# Stepped speech badge; integer pixels and no font dependency.
		draw_rect(Rect2(p + Vector2(2, 0), Vector2(16, 25)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(0, 2), Vector2(20, 21)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(2, 3), Vector2(16, 19)), ink)
		draw_rect(Rect2(p + Vector2(4, 5), Vector2(12, 15)), fill)
		draw_rect(Rect2(p + Vector2(8, 7), Vector2(4, 7)), ink)
		draw_rect(Rect2(p + Vector2(8, 16), Vector2(4, 3)), ink)
		draw_rect(Rect2(p + Vector2(7, 24), Vector2(6, 3)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(9, 26), Vector2(2, 2)), ink)
		if active:
			for offset in [Vector2(-15, 0), Vector2(11, 0)]:
				draw_rect(Rect2(point + offset, Vector2(4, 2)), ink)
