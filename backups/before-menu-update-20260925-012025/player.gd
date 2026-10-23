extends CharacterBody2D

const SPEED := 205.0
const ACCELERATION := 1150.0
const DECELERATION := 1450.0
var facing := Vector2.DOWN
var carrying := 0
var walk_time := 0.0

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	if input != Vector2.ZERO:
		facing = input
		velocity = velocity.move_toward(input * SPEED, ACCELERATION * delta)
		walk_time += delta * 10.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
	move_and_slide()
	position.x = clampf(position.x, 24, 1256)
	position.y = clampf(position.y, 70, 696)
	queue_redraw()

func faces_point(point: Vector2, max_distance := 100.0) -> bool:
	var offset := point - global_position
	return offset.length() <= max_distance and (offset.length() < 12 or facing.dot(offset.normalized()) > 0.15)

func _draw() -> void:
	var bob := roundi(sin(walk_time) * 2.0) if velocity.length() > 8 else 0
	# Shadow and boots.
	draw_rect(Rect2(-15, 21, 31, 7), Color("#32412d", 0.35))
	draw_rect(Rect2(-12, 13 + bob, 9, 12), Color("#3a2a24"))
	draw_rect(Rect2(4, 13 - bob, 9, 12), Color("#3a2a24"))
	# Jeans, shirt, belt.
	draw_rect(Rect2(-13, -2, 26, 19), Color("#3d6688"))
	draw_rect(Rect2(-15, -20, 30, 21), Color("#c85e42"))
	draw_rect(Rect2(-15, -2, 30, 5), Color("#513724"))
	draw_rect(Rect2(-3, -2, 6, 5), Color("#e1bb45"))
	# Face, hair and detailed cowboy hat.
	draw_rect(Rect2(-11, -34, 22, 16), Color("#e6a978"))
	draw_rect(Rect2(-13, -36, 26, 6), Color("#6d3f28"))
	draw_rect(Rect2(-18, -42, 36, 7), Color("#9b6138"))
	draw_rect(Rect2(-11, -50, 22, 10), Color("#9b6138"))
	draw_rect(Rect2(-7, -47, 14, 3), Color("#c88950"))
	# Direction marker and milk pail when carrying.
	draw_line(Vector2.ZERO, facing * 30, Color("#fff4b0", 0.45), 2)
	if carrying > 0:
		draw_rect(Rect2(16, -3, 13, 17), Color("#dce8e9"))
		draw_rect(Rect2(18, 0, 9, 3), Color("#ffffff"))
		draw_arc(Vector2(22, -3), 7, PI, TAU, 8, Color("#586c73"), 2)
