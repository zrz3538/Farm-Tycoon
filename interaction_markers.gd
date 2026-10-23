extends Node2D

const MARKER_SHEET:=preload("res://assets/ui/interaction_marker_4x1.png")

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
		var frame:int=2 if active else int([0,1,3,1][int(elapsed*3.0+i)%4])
		var cell:=Vector2(MARKER_SHEET.get_width()/4.0,MARKER_SHEET.get_height())
		var bob:=roundf(sin(elapsed*3.0+i*0.8))*3.0
		draw_texture_rect_region(MARKER_SHEET,Rect2(point+Vector2(-22,-66+bob),Vector2(44,58)),Rect2(Vector2(frame,0)*cell,cell))
