extends CharacterBody2D

const SPEED := 205.0
const ACCELERATION := 1150.0
const DECELERATION := 1450.0
var facing := Vector2.DOWN
var carrying := 0
var walk_time := 0.0
var shotgun_equipped := false
var shot_time := 0.0

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 12)
	collision.position = Vector2(0, 17)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	shot_time = maxf(0.0, shot_time - delta)
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
		if shotgun_equipped:
			var aim := get_global_mouse_position() - global_position
			if aim.length() > 8:
				facing = aim.normalized()
	move_and_slide()
	position.x = clampf(position.x, 24, 1256)
	position.y = clampf(position.y, 70, 696)
	queue_redraw()

func set_shotgun(value: bool) -> void:
	shotgun_equipped = value
	shot_time = 0.0
	queue_redraw()

func fire_toward(target: Vector2) -> void:
	var aim := target - global_position
	if aim.length() > 1:
		facing = aim.normalized()
	shot_time = 0.22
	velocity -= facing * 45.0
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
	draw_rect(Rect2(-11, -40, 22, 3), Color("#584331"))
	draw_rect(Rect2(-12, -19, 4, 18), Color("#edb581"))
	draw_rect(Rect2(10, -19, 4, 18), Color("#edb581"))
	draw_rect(Rect2(-7, -17, 5, 9), Color("#9d493b"))
	draw_rect(Rect2(0, -16, 2, 14), Color("#e7a565"))
	if facing.y > -0.5:
		var look := 3 if facing.x > 0.5 else (-3 if facing.x < -0.5 else 0)
		draw_rect(Rect2(-6 + look, -29, 2, 3), Color("#433529"))
		draw_rect(Rect2(4 + look, -29, 2, 3), Color("#433529"))
		draw_rect(Rect2(-1 + look, -23, 4, 2), Color("#b87a58"))
	# Direction marker and milk pail when carrying.
	if carrying > 0:
		draw_rect(Rect2(16, -3, 13, 17), Color("#dce8e9"))
		draw_rect(Rect2(18, 0, 9, 3), Color("#ffffff"))
		draw_arc(Vector2(22, -3), 7, PI, TAU, 8, Color("#586c73"), 2)
	if shotgun_equipped:
		draw_set_transform(Vector2(2, -9), facing.angle(), Vector2.ONE)
		draw_rect(Rect2(0, -4, 22, 8), Color("#5b3928"))
		draw_rect(Rect2(5, -3, 25, 6), Color("#8b6137"))
		draw_rect(Rect2(23, -2, 23, 4), Color("#39464b"))
		draw_rect(Rect2(29, -1, 18, 2), Color("#88989a"))
		draw_rect(Rect2(10, 3, 7, 6), Color("#4b3227"))
		if shot_time > 0.12:
			draw_colored_polygon(PackedVector2Array([
				Vector2(47, 0), Vector2(55, -7), Vector2(53, -2),
				Vector2(62, 0), Vector2(53, 2), Vector2(55, 7)
			]), Color("#ffd65b"))
			draw_rect(Rect2(47, -2, 7, 4), Color("#fff3a1"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
