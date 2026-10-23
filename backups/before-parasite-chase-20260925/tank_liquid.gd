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
	var max_height := 62.0
	var height := maxf(2.0, floor(max_height * ratio))
	var top := 598.0 - height
	var milk := Color("#e9f5e8", 0.86)
	var shade := Color("#bbd8d4", 0.9)
	draw_rect(Rect2(578, top, 96, height), milk)
	draw_rect(Rect2(578, top, 96, 4), Color("#ffffff", 0.9))
	draw_rect(Rect2(578, 594, 96, 4), shade)
	draw_rect(Rect2(584, top + 5, 7, maxf(0, height - 9)), Color("#ffffff", 0.36))
	for i in 4:
		var bubble_y := 588.0 - fmod(wave_time * (7.0 + i) + i * 13.0, maxf(5.0, height - 4.0))
		if bubble_y > top + 4:
			draw_rect(Rect2(608 + i * 16, bubble_y, 4, 4), Color("#ffffff", 0.65))
	var infestation: int = int(game._parasite_count()) + int(game._skeleton_count())
	if infestation > 0:
		for i in mini(10, infestation + 3):
			var angle := wave_time * (0.8 + i * 0.07) + i * 0.85
			var center := Vector2(626,570) + Vector2(cos(angle)*68.0,sin(angle)*45.0)
			var bend := center + Vector2(cos(angle+1.4)*12.0,sin(angle+1.4)*8.0)
			draw_line(center,bend,Color("#74283b"),4)
			draw_circle(bend,3,Color("#bd4450"))
