extends Node2D

const MAP_BACKGROUND := preload("res://assets/maps/corn_house.png")
const HOUSE_POINT := Vector2(870, 365)
const CAMPAIGN_POINT := Vector2(930, 610)
const PARASITE_DOG := preload("res://assets/enemies/parasite_skeletons/parasite_dog.png")
const MARKER_SHEET := preload("res://assets/ui/interaction_marker_4x1.png")
var elapsed := 0.0
var enemies: Array[Dictionary] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(700,75,345,250),Rect2(15,20,675,300),Rect2(1025,155,165,170),Rect2(55,440,285,225),Rect2(330,480,270,185),Rect2(820,455,265,215)]:
		_add_solid(rect)
	queue_redraw()

func _process(delta: float) -> void:
	if visible:
		elapsed += delta
		var game := get_parent()
		if game.playing and not game.suspended and game.scene_id == 1:
			for i in enemies.size():
				var enemy:Dictionary=enemies[i]
				var offset:Vector2=game.player.position-Vector2(enemy.pos)
				enemy.attack=maxf(0.0,float(enemy.attack)-delta);enemy.cooldown=maxf(0.0,float(enemy.cooldown)-delta)
				if offset.length()<75.0 and float(enemy.cooldown)<=0.0:
					enemy.attack=0.44;enemy.cooldown=1.0;enemy.hit=false
				if float(enemy.attack)>0.0:
					var progress:=1.0-float(enemy.attack)/0.44
					if progress>0.38 and progress<0.70 and not bool(enemy.hit) and offset.length()<88.0:
						enemy.hit=true
						if game.first_skeleton_encounter_completed:game.take_damage(35.0,"寄生骷髅抓住了牛仔")
						else:game.trigger_game_over()
				elif offset.length()>2.0:enemy.pos=Vector2(enemy.pos)+offset.normalized()*(44.0+i*2.5)*delta
				enemies[i]=enemy
		queue_redraw()

func spawn_attackers() -> void:
	if not enemies.is_empty(): return
	enemies = []
	for i in 4:enemies.append({"pos":[Vector2(780,390),Vector2(875,455),Vector2(1160,470),Vector2(1220,385)][i],"attack":0.0,"cooldown":0.2+i*0.15,"hit":false,"phase":i*1.4})
	queue_redraw()

func shoot_at(point: Vector2) -> bool:
	var best := -1
	var distance := 84.0
	for i in enemies.size():
		var candidate := Vector2(enemies[i].pos).distance_to(point)
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
	draw_texture_rect(MAP_BACKGROUND,Rect2(0,0,1280,720),false)
	var state_game := get_parent()
	for i in enemies.size():
		_draw_walking_attacker(enemies[i],i)
	_draw_marker(HOUSE_POINT,0)
	if is_instance_valid(state_game) and state_game.parasite_ever_discovered:
		_draw_marker(CAMPAIGN_POINT,1)
	return
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
	if is_instance_valid(game) and game.day_count >= 4 and not game.free_mode:
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
	# The buried service shaft only reveals itself after the first parasite is found.
	if is_instance_valid(game) and game.parasite_ever_discovered and not game.free_mode:
		draw_circle(CAMPAIGN_POINT,50,Color("#1b1b1d")); draw_arc(CAMPAIGN_POINT,50,0,TAU,28,Color("#97744f"),9)
		for angle in [0.0,PI*0.5]: draw_line(CAMPAIGN_POINT+Vector2.from_angle(angle)*39,CAMPAIGN_POINT-Vector2.from_angle(angle)*39,Color("#795a3e"),7)
		for i in 6: draw_line(CAMPAIGN_POINT+Vector2(-55+i*20,-35),CAMPAIGN_POINT+Vector2(-45+i*20,38),Color("#48382d"),4)
		if not game.blood_moon_defeated: draw_line(CAMPAIGN_POINT+Vector2(-34,-34),CAMPAIGN_POINT+Vector2(34,34),Color("#73243b"),10)
	for enemy in enemies: _draw_enemy(Vector2(enemy.pos))
	_draw_marker(HOUSE_POINT, 0)
	if is_instance_valid(game) and game.parasite_ever_discovered and not game.free_mode: _draw_marker(CAMPAIGN_POINT,2)

func _draw_house_parasites(count: int) -> void:
	var roots := [Vector2(705,300),Vector2(740,190),Vector2(790,110),Vector2(870,80),Vector2(950,105),Vector2(1030,180),Vector2(1040,300),Vector2(780,320),Vector2(960,320)]
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
	draw_ellipse_shadow(position)
	var bob:=roundf(sin(elapsed*6.0+position.x*0.01)*2.0)
	draw_texture_rect(PARASITE_DOG,Rect2(position.x-58,position.y-73+bob,116,88),false)

func _draw_walking_attacker(enemy:Dictionary,index: int) -> void:
	var game := get_parent()
	var position:Vector2=enemy.pos
	var phase := elapsed*8.5+float(index)*1.7
	var stride := sin(phase)
	var footfall := absf(stride)
	var facing := 1.0
	if is_instance_valid(game.player) and game.player.position.x < position.x: facing = -1.0
	var shadow_width := 52.0-footfall*6.0
	draw_rect(Rect2(position.x-shadow_width*0.5,position.y-7,shadow_width,12),Color("#182219",0.42))
	if footfall > 0.82:
		for grit in 3:
			var dust_x := position.x-facing*(25.0+grit*8.0)
			draw_rect(Rect2(dust_x,position.y-4-grit*3,4,4),Color("#8d7655",0.55))
	var attack_time:=float(enemy.get("attack",0.0));var attacking:=attack_time>0.0;var attack_progress:=1.0-attack_time/0.44 if attacking else 0.0
	var lunge:=sin(attack_progress*PI)*24.0 if attacking else 0.0
	var tilt:=(-facing*0.24*sin(attack_progress*PI)) if attacking else stride*0.11
	draw_set_transform(position+Vector2(facing*lunge+stride*4.0,-2.0-footfall*7.0),tilt,Vector2(facing*(1.0+footfall*0.07),1.0-footfall*0.06))
	draw_texture_rect(PARASITE_DOG,Rect2(-43,-58,86,65),false)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if attacking:draw_arc(position+Vector2(facing*28,-25),27,-1.1 if facing>0 else PI-1.1,1.1 if facing>0 else PI+1.1,9,Color("#ffe0a0"),4)

func draw_ellipse_shadow(position: Vector2) -> void:
	draw_rect(Rect2(position-Vector2(37,7),Vector2(76,14)),Color("#283326",0.35))

func _draw_marker(point: Vector2, index: int) -> void:
	var game := get_parent()
	if not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var frame:int=2 if active else int([0,1,3,1][int(elapsed*3.0+index)%4])
	var cell:=Vector2(MARKER_SHEET.get_width()/4.0,MARKER_SHEET.get_height());var bob:=roundf(sin(elapsed*3.0+index))*3.0
	draw_texture_rect_region(MARKER_SHEET,Rect2(point+Vector2(-22,-66+bob),Vector2(44,58)),Rect2(Vector2(frame,0)*cell,cell))

