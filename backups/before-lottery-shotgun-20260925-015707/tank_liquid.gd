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
	if last_capacity <= 0 or last_amount <= 0:
		return
	var ratio := clampf(float(last_amount) / float(last_capacity), 0.0, 1.0)
	var max_height := 55.0
	var height := maxf(2.0, floor(max_height * ratio))
	var top := 594.0 - height
	var milk := Color("#e9f5e8", 0.86)
	var shade := Color("#bbd8d4", 0.9)
	draw_rect(Rect2(590, top, 72, height), milk)
	draw_rect(Rect2(590, top, 72, 3), Color("#ffffff", 0.9))
	draw_rect(Rect2(590, 590, 72, 4), shade)
	draw_rect(Rect2(594, top + 5, 5, maxf(0, height - 9)), Color("#ffffff", 0.36))
	for i in 4:
		var bubble_y := 588.0 - fmod(wave_time * (7.0 + i) + i * 13.0, maxf(5.0, height - 4.0))
		if bubble_y > top + 4:
			draw_rect(Rect2(608 + i * 12, bubble_y, 3, 3), Color("#ffffff", 0.65))
