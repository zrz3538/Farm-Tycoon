extends Node2D

var last_amount := -1
var last_capacity := -1
var wave_time := 0.0

func _process(delta: float) -> void:
	var game := get_parent().get_parent()
	if not game.playing:
		visible = false
		return
	visible = true
	wave_time += delta
	if last_amount != game.stored_milk or last_capacity != game._tank_capacity():
		last_amount = game.stored_milk
		last_capacity = game._tank_capacity()
	queue_redraw()

func _draw() -> void:
	if last_capacity <= 0:
		return
	var game := get_parent().get_parent()
	var ratio := clampf(float(last_amount) / float(last_capacity), 0.0, 1.0)
	var max_height := 78.0
	var height := maxf(2.0, floor(max_height * ratio))
	var top := 584.0 - height
	var milk := Color("#e9f5e8", 0.86)
	var shade := Color("#bbd8d4", 0.9)
	draw_rect(Rect2(712, top, 106, height), milk)
	draw_rect(Rect2(712, top, 106, 4), Color("#ffffff", 0.9))
	draw_rect(Rect2(712, 580, 106, 4), shade)
	draw_rect(Rect2(718, top + 5, 8, maxf(0, height - 9)), Color("#ffffff", 0.36))
	for i in 4:
		var bubble_y := 576.0 - fmod(wave_time * (7.0 + i) + i * 13.0, maxf(5.0, height - 4.0))
		if bubble_y > top + 4:
			draw_rect(Rect2(742 + i * 17, bubble_y, 4, 4), Color("#ffffff", 0.65))
	if game.milk_contaminated:
		var anchors := [Vector2(710,550),Vector2(730,525),Vector2(765,520),Vector2(820,548),Vector2(802,585),Vector2(724,586)]
		for i in anchors.size():
			var points := PackedVector2Array()
			for segment in 6:
				var crawl := fmod(wave_time*(5.0+i*0.35)+i*17.0,24.0)
				var p: Vector2 = anchors[i] + Vector2(segment*4.0-10.0+crawl, sin(wave_time*5.0+segment*1.7+i)*5.0)
				points.append(p)
			draw_polyline(points,Color("#5b1428"),5.0)
			draw_circle(points[points.size()-1],4,Color("#b62d43"))
			draw_circle(points[points.size()-1]+Vector2(1,-1),1,Color("#eed45d"))
