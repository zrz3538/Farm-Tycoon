extends CharacterBody2D

const SPEED := 205.0
const ACCELERATION := 1150.0
const DECELERATION := 1450.0
const COWBOY_SHEET := preload("res://assets/player_walk_4x4_aligned.png")
const WEAPON_SHEET := preload("res://assets/weapons/weapon_actions_clean_9x4.png")
const WEAPON_REGIONS := {
	"ar15":Rect2(35,145,189,84),
	"m1911":Rect2(74,588,118,88),
	"shotgun":Rect2(28,820,189,61)
}
const COWBOY_FRAME_SIZE := Vector2(128, 128)
const PLAYER_DRAW_SIZE := Vector2(116,116)
# Held-gun height: larger moves the gun down, smaller moves it up.
const WEAPON_HEIGHT_Y := -20.0
const WEAPON_FORWARD := 16.0
const WEAPON_DRAW_HEIGHTS := {"ar15":25.0,"m1911":17.0,"shotgun":24.0}
const WEAPON_EJECTION_FORWARD := {
	"ar15":9.0,
	"m1911":10.0,
	"shotgun":12.0
}
var facing := Vector2.DOWN
var carrying := 0
var walk_time := 0.0
var is_walking := false
var shotgun_equipped := false
var weapon_id := "shotgun"
var shot_time := 0.0
var reload_time := 0.0

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 12)
	collision.position = Vector2(0, 17)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	shot_time = maxf(0.0, shot_time - delta)
	reload_time=maxf(0.0,reload_time-delta)
	var input := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	if input != Vector2.ZERO:
		is_walking = true
		facing = input
		velocity = velocity.move_toward(input * SPEED, ACCELERATION * delta)
		walk_time += delta * 9.0
	else:
		is_walking = false
		walk_time = 0.0
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

func set_weapon(id: String) -> void:
	weapon_id = id if not id.is_empty() else "shotgun"
	shotgun_equipped = not id.is_empty()
	shot_time = 0.0
	queue_redraw()

func fire_toward(target: Vector2) -> void:
	var aim := target - global_position
	if aim.length() > 1:
		facing = aim.normalized()
	shot_time = 0.22
	velocity -= facing * 45.0
	queue_redraw()

func start_reload(duration: float) -> void:
	reload_time=duration
	queue_redraw()

func finish_reload() -> void:
	reload_time=0.0
	queue_redraw()

func faces_point(point: Vector2, max_distance := 100.0) -> bool:
	var offset := point - global_position
	return offset.length() <= max_distance and (offset.length() < 12 or facing.dot(offset.normalized()) > 0.15)

func get_ejection_point() -> Vector2:
	var forward:=float(WEAPON_EJECTION_FORWARD.get(weapon_id,8.0))
	return global_position+facing*forward-facing.orthogonal()*5.0+Vector2(0,WEAPON_HEIGHT_Y)

func get_magazine_point() -> Vector2:
	return global_position+facing*2.0-Vector2(0,3)

func get_reload_point() -> Vector2:
	return global_position+facing*8.0+Vector2(0,WEAPON_HEIGHT_Y)

func _draw() -> void:
	draw_rect(Rect2(-15, 21, 31, 7), Color("#32412d", 0.35))
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2 if facing.x > 0.0 else 1
	elif facing.y < 0.0:
		row = 3
	var column := 0
	if is_walking:
		var walk_frame:=int(floor(walk_time)) % 4
		column = walk_frame
	var source := Rect2(Vector2(column, row) * COWBOY_FRAME_SIZE, COWBOY_FRAME_SIZE)
	var weapon_behind := shotgun_equipped and facing.y < -0.35
	if weapon_behind: _draw_weapon()
	draw_texture_rect_region(COWBOY_SHEET, Rect2(-PLAYER_DRAW_SIZE.x*0.5,-82,PLAYER_DRAW_SIZE.x,PLAYER_DRAW_SIZE.y), source)
	if shotgun_equipped and not weapon_behind: _draw_weapon()
	if carrying > 0:
		draw_rect(Rect2(16, -3, 13, 17), Color("#dce8e9"))
		draw_rect(Rect2(18, 0, 9, 3), Color("#ffffff"))
		draw_arc(Vector2(22, -3), 7, PI, TAU, 8, Color("#586c73"), 2)

func _draw_weapon() -> void:
	var region: Rect2 = WEAPON_REGIONS.get(weapon_id,WEAPON_REGIONS.shotgun)
	var draw_height := float(WEAPON_DRAW_HEIGHTS.get(weapon_id,24.0))
	var draw_width := region.size.x*(draw_height/region.size.y)
	var direction := facing.normalized()
	if direction.length_squared()<0.01: direction=Vector2.DOWN
	var angle := direction.angle()
	var mirror_x := direction.x < 0.0
	if mirror_x: angle += PI
	var recoil := clampf(shot_time/0.22,0.0,1.0)
	var origin := Vector2(0,WEAPON_HEIGHT_Y)+direction*(WEAPON_FORWARD-recoil*3.0)
	var scale_sign := -1.0 if mirror_x else 1.0
	draw_set_transform(origin,angle-recoil*0.045*scale_sign,Vector2(scale_sign,1.0))
	draw_texture_rect_region(WEAPON_SHEET,Rect2(-draw_width*0.34,-draw_height*0.5,draw_width,draw_height),region)
	if shot_time>0.12:
		var muzzle_x := draw_width*0.66
		draw_colored_polygon(PackedVector2Array([Vector2(muzzle_x,-6),Vector2(muzzle_x+17,0),Vector2(muzzle_x,6),Vector2(muzzle_x+5,0)]),Color("#ffd34f"))
		draw_colored_polygon(PackedVector2Array([Vector2(muzzle_x+2,-3),Vector2(muzzle_x+11,0),Vector2(muzzle_x+2,3)]),Color("#fff3ae"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
