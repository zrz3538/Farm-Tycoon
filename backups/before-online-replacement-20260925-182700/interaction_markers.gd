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
	var points := [world.TRUCK_POINT, world.TANK_POINT, world.BARN_POINT, world.MARKET_POINT, world.LOTTERY_POINT, world.TASK_POINT]
	var ranges := [155.0, 155.0, 155.0, 155.0, 155.0, 155.0]
	for i in points.size():
		var point: Vector2 = points[i]
		var active: bool = game.player.faces_point(point, ranges[i])
		var ink := Color("#ffe4a0") if active else Color("#ccad70")
		var fill := Color("#697f48") if active else Color("#594d39")
		var bob := roundf(sin(elapsed * 3.0 + i * 0.8)) * 2.0
		var p := point + Vector2(-14, -48 + bob)
		# Stepped speech badge; integer pixels and no font dependency.
		draw_rect(Rect2(p + Vector2(3, 0), Vector2(22, 34)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(0, 3), Vector2(28, 28)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(3, 4), Vector2(22, 26)), ink)
		draw_rect(Rect2(p + Vector2(6, 7), Vector2(16, 20)), fill)
		draw_rect(Rect2(p + Vector2(11, 9), Vector2(6, 10)), ink)
		draw_rect(Rect2(p + Vector2(11, 22), Vector2(6, 4)), ink)
		draw_rect(Rect2(p + Vector2(9, 33), Vector2(10, 4)), Color("#303b31"))
		draw_rect(Rect2(p + Vector2(12, 37), Vector2(4, 3)), ink)
		if active:
			for offset in [Vector2(-15, 0), Vector2(11, 0)]:
				draw_rect(Rect2(point + offset, Vector2(4, 2)), ink)
