extends Node2D

const HOUSE_POINT := Vector2(1035, 500)
const ARMORY_POINT := Vector2(470, 520)
const CAMPAIGN_POINT := Vector2(765, 610)
var elapsed := 0.0
var enemies: Array[Vector2] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(825,105,375,320),Rect2(50,80,680,340),Rect2(340,550,260,150)]:
		_add_solid(rect)
	queue_redraw()

func _process(delta: float) -> void:
	if visible:
		elapsed += delta
		var game := get_parent()
		if game.playing and not game.suspended and game.scene_id == 1:
			for i in enemies.size():
				var offset: Vector2 = game.player.position - enemies[i]
				if offset.length() > 1.0:
					enemies[i] += offset.normalized() * (36.0 + i * 2.5) * delta
				if enemies[i].distance_to(game.player.position) < 25.0:
					if game.first_skeleton_encounter_completed:
						game.combat_defeat("寄生骷髅抓住了牛仔")
					else:
						game.trigger_game_over()
					return
		queue_redraw()

func spawn_attackers() -> void:
	if not enemies.is_empty(): return
	enemies = [Vector2(780,390),Vector2(875,455),Vector2(1160,470),Vector2(1220,385)]
	queue_redraw()

func shoot_at(point: Vector2) -> bool:
	var best := -1
	var distance := 48.0
	for i in enemies.size():
		var candidate := enemies[i].distance_to(point)
		if candidate < distance:
			distance = candidate
			best = i
	if best < 0: return false
	enemies.remove_at(best)
	if enemies.is_empty():
		var game := get_parent()
		game.first_skeleton_encounter_completed=true
		game._save_game()
	queue_redraw()
	return true

func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#879f5a"))
	draw_rect(Rect2(0,430,1280,95),Color("#c79658"))
	draw_rect(Rect2(730,310,90,410),Color("#c79658"))
	# Large corn field with alternating rows and visible ears.
	draw_rect(Rect2(50,80,680,355),Color("#765738"))
	for row in range(5):
		for col in range(14):
			var x := 75.0 + col * 46 + (row % 2) * 12
			var y := 112.0 + row * 62
			draw_rect(Rect2(x,y,5,38),Color("#3f713e"))
			draw_rect(Rect2(x-8,y+10,12,5),Color("#5f8b45"))
			draw_rect(Rect2(x+4,y+18,12,5),Color("#6f984b"))
			draw_rect(Rect2(x-3,y+2,11,18),Color("#e0b844"))
			draw_rect(Rect2(x,y+4,4,14),Color("#f2d061"))
	for x in range(48,735,45):
		draw_rect(Rect2(x,70,7,375),Color("#765037"))
	for y in [74,423]: draw_rect(Rect2(48,y,687,8),Color("#9f7046"))
	var game := get_parent()
	if is_instance_valid(game) and game.day_count >= 4:
		_draw_field_parasites()
	# Cowboy house.
	draw_rect(Rect2(825,250,375,175),Color("#a75e43"))
	draw_colored_polygon(PackedVector2Array([Vector2(790,250),Vector2(1015,105),Vector2(1235,250)]),Color("#59343a"))
	for y in range(125,245,16):
		var half_width := (y-105)*1.50
		draw_rect(Rect2(1015-half_width+7,y,half_width*2-14,6),Color("#74434a"))
	for x in range(842,1185,24): draw_rect(Rect2(x,265,5,145),Color("#c47b54"))
	for x in [872,1120]:
		draw_rect(Rect2(x,285,58,65),Color("#ead492")); draw_rect(Rect2(x+7,292,44,51),Color("#75a0a2")); draw_rect(Rect2(x+27,292,4,51),Color("#e7d293")); draw_rect(Rect2(x+7,315,44,4),Color("#e7d293"))
	draw_rect(Rect2(990,325,90,100),Color("#5c392e")); draw_rect(Rect2(1000,335,70,90),Color("#724736")); draw_rect(Rect2(1055,372,7,7),Color("#e1b84d"))
	# Chimney, foundation, flower boxes and porch depth.
	draw_rect(Rect2(1130,120,42,92),Color("#694438")); draw_rect(Rect2(1124,115,54,14),Color("#4b3431"))
	for y in range(132,202,16): draw_rect(Rect2(1134,y,34,4),Color("#8d5c48"))
	draw_rect(Rect2(815,417,395,18),Color("#5c493b"))
	for x in [870,1118]:
		draw_rect(Rect2(x,351,64,14),Color("#754a35"))
		for fx in range(x+6,x+58,12):
			draw_rect(Rect2(fx,342,4,11),Color("#4f7b43")); draw_rect(Rect2(fx-3,340,9,5),Color("#e7c35c"))
	# Porch and yard details.
	draw_rect(Rect2(925,425,215,18),Color("#75523a")); draw_rect(Rect2(945,443,175,12),Color("#a77749"))
	for x in [850,1165]:
		draw_rect(Rect2(x,470,8,46),Color("#604934")); draw_rect(Rect2(x-18,466,44,8),Color("#7b5d3e"))
	if is_instance_valid(game) and game._skeleton_count() >= 5:
		_draw_house_parasites(game._skeleton_count())
	_draw_armory()
	# Sealed cemetery shaft that opens after the blood moon boss.
	draw_circle(CAMPAIGN_POINT,43,Color("#302922")); draw_arc(CAMPAIGN_POINT,43,0,TAU,28,Color("#97744f"),8)
	for angle in [0.0,PI*0.5]: draw_line(CAMPAIGN_POINT+Vector2.from_angle(angle)*34,CAMPAIGN_POINT-Vector2.from_angle(angle)*34,Color("#795a3e"),7)
	if is_instance_valid(game) and not game.blood_moon_defeated:
		draw_line(CAMPAIGN_POINT+Vector2(-30,-30),CAMPAIGN_POINT+Vector2(30,30),Color("#73243b"),9)
	for enemy in enemies: _draw_enemy(enemy)
	_draw_marker(HOUSE_POINT, 0)
	_draw_marker(ARMORY_POINT,1)
	_draw_marker(CAMPAIGN_POINT,2)

func _draw_armory() -> void:
	# Timber weapon depot with barred display windows.
	draw_rect(Rect2(340,565,260,135),Color("#5b4b3e"))
	draw_colored_polygon(PackedVector2Array([Vector2(320,565),Vector2(470,500),Vector2(620,565)]),Color("#34363a"))
	for y in range(520,560,10):
		var half := (y-500)*2.25
		draw_rect(Rect2(470-half+6,y,half*2-12,4),Color("#51565b"))
	for x in range(355,590,28): draw_rect(Rect2(x,575,5,112),Color("#7b654e"))
	draw_rect(Rect2(430,625,80,75),Color("#2f3132"))
	for x in [360,520]:
		draw_rect(Rect2(x,585,58,34),Color("#22282a")); draw_rect(Rect2(x+6,591,46,4),Color("#aeb3a6")); draw_rect(Rect2(x+26,585,5,34),Color("#494f50"))
	draw_rect(Rect2(405,548,130,13),Color("#25272a")); draw_rect(Rect2(416,551,108,5),Color("#d0a95d"))

func _draw_house_parasites(count: int) -> void:
	var roots := [Vector2(815,410),Vector2(860,250),Vector2(930,170),Vector2(1010,112),Vector2(1100,175),Vector2(1190,260),Vector2(1200,410),Vector2(920,425),Vector2(1100,425)]
	var directions := [Vector2(-1,0.5),Vector2(-1,-0.2),Vector2(-0.7,-0.8),Vector2(0,-1),Vector2(0.7,-0.8),Vector2(1,-0.2),Vector2(1,0.5),Vector2(-0.3,1),Vector2(0.4,1)]
	for i in roots.size():
		var points := PackedVector2Array([roots[i]])
		for segment in range(1,6):
			var side := Vector2(-directions[i].y,directions[i].x)
			var sway := sin(elapsed*1.7+i*1.3+segment*0.9)*13.0
			points.append(roots[i]+directions[i]*(segment*34.0)+side*sway)
		draw_polyline(points,Color("#35111f"),13.0)
		draw_polyline(points,Color("#681c34"),6.0)
		var head := points[points.size()-1]
		draw_circle(head,9,Color("#9c2941")); draw_circle(head+directions[i]*3.0,3,Color("#efcd62"))
		for segment in range(1,points.size()-1): draw_circle(points[segment],5,Color("#7f233b"))

func _draw_field_parasites() -> void:
	var nests := [Vector2(120,160),Vector2(245,335),Vector2(370,205),Vector2(505,350),Vector2(650,155)]
	for i in nests.size():
		var base: Vector2 = nests[i]
		for arm in 3:
			var points := PackedVector2Array()
			for segment in 5:
				points.append(base+Vector2((arm-1)*12+sin(elapsed*2.2+i+segment)*7.0,-segment*13.0))
			draw_polyline(points,Color("#56182d"),5.0)
		var pulse := 7.0+sin(elapsed*3.0+i)*2.0
		draw_circle(base,pulse,Color("#85243c")); draw_circle(base+Vector2(2,-2),3,Color("#d7b957"))

func _draw_enemy(position: Vector2) -> void:
	# Low crawling parasite skeleton: exposed spine, ribs and hooked limbs.
	draw_ellipse_shadow(position)
	var spine := PackedVector2Array()
	for segment in 7:
		spine.append(position+Vector2(segment*9-27,sin(elapsed*6.0+segment)*4.0))
	draw_polyline(spine,Color("#e1d8b7"),6.0)
	for segment in range(1,6):
		var p := spine[segment]
		draw_line(p,p+Vector2(-5,-13),Color("#c8bea0"),4)
		draw_line(p,p+Vector2(6,13),Color("#c8bea0"),4)
	var head := position+Vector2(38,0)
	draw_rect(Rect2(head-Vector2(7,8),Vector2(16,16)),Color("#e5ddc2"))
	draw_rect(Rect2(head+Vector2(2,-4),Vector2(4,4)),Color("#8f2037"))
	for leg in [-1,1]:
		draw_line(position+Vector2(-18,leg*5),position+Vector2(-36,leg*18),Color("#5e1830"),6)
		draw_line(position+Vector2(10,leg*5),position+Vector2(28,leg*20),Color("#5e1830"),6)

func draw_ellipse_shadow(position: Vector2) -> void:
	draw_rect(Rect2(position-Vector2(37,7),Vector2(76,14)),Color("#283326",0.35))

func _draw_marker(point: Vector2, index: int) -> void:
	var game := get_parent()
	if not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var bob := roundf(sin(elapsed*3.0+index))*2.0
	var p := point + Vector2(-14,-48+bob)
	var ink := Color("#ffe4a0") if active else Color("#ccad70")
	draw_rect(Rect2(p,Vector2(28,32)),Color("#303b31")); draw_rect(Rect2(p+Vector2(4,4),Vector2(20,24)),Color("#61513b")); draw_rect(Rect2(p+Vector2(11,7),Vector2(6,11)),ink); draw_rect(Rect2(p+Vector2(11,22),Vector2(6,4)),ink)
