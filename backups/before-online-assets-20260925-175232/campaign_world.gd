extends Node2D

const ENTRY_POINT := Vector2(75,625)
const EXIT_POINT := Vector2(1195,115)
const HEART_POINT := Vector2(1040,205)
const STAGE_NAMES := ["枯骨墓园","腐水沼泽","哭泣礼拜堂","断脊峡谷","孵化巢穴","祖父矿井"]
const ENTRY_NAMES := ["跳入封死的墓井","乘坐腐木筏","敲响逆鸣丧钟","启动骨骸升降机","钻进搏动虫道","乘坐矿车深入矿井"]
const STAGE_STORIES := ["墓碑背面刻着祖父的姓名，地下传来骨犬刨土声。","腐水中的骨架被长腿寄生虫吊起，木筏是唯一的路。","礼拜堂的祷告者没有脸，丧钟控制着下一道门。","峡谷由巨大脊骨拼成，升降机还在缓慢呼吸。","这里不断孵化新的骷髅，矿井炸药藏在母巢后方。","矿车冲入祖父封死的旧矿道——他一直在供奉寄生虫之心。"]
const ENEMY_NAMES := ["掘墓寄生骨犬","淤泥长腿骷髅","无面祷告者","裂脊冲锋兽","孵化母骸","矿井守门者"]
const COLORS := [Color("#425044"),Color("#354d43"),Color("#4b4052"),Color("#785041"),Color("#54263b"),Color("#292b35")]

var stage_index := 0
var elapsed := 0.0
var arrival := 0.0
var enemies: Array[Dictionary] = []
var cleared := false
var game: Node
var hit_flashes: Array[Dictionary] = []

func setup(index: int) -> void:
	stage_index = index
	name = "CampaignWorld%d" % (index+1)

func _ready() -> void:
	game = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func activate() -> void:
	arrival = 0.0
	cleared = game.campaign_progress > stage_index
	if not cleared and enemies.is_empty():
		_spawn_wave()
	queue_redraw()

func _spawn_wave() -> void:
	enemies.clear()
	var count := 4 + mini(stage_index,3)
	for i in count:
		var hp := 100 + stage_index*85
		if stage_index == 5: hp = 650 if i == 0 else 310
		enemies.append({
			"pos":Vector2(330+(i%4)*190,180+(i/4)*230),
			"hp":hp,"max_hp":hp,"speed":34.0+stage_index*5.5+(i%3)*3,
			"kind":stage_index,"rise":0.0,"phase":randf()*TAU
		})

func _process(delta: float) -> void:
	if not visible or game.suspended: return
	elapsed += delta
	arrival += delta
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		enemy.rise = minf(1.0,float(enemy.get("rise",0.0))+delta*0.65)
		enemies[i] = enemy
		if float(enemy.rise)<1.0: continue
		var offset: Vector2 = game.player.position-Vector2(enemy.pos)
		if offset.length() < 520 and offset.length() > 2:
			var side := Vector2(-offset.y,offset.x).normalized()*sin(elapsed*2.2+float(enemy.phase))*12.0
			enemy.pos = Vector2(enemy.pos)+(offset.normalized()*float(enemy.speed)+side)*delta
		enemies[i] = enemy
		if Vector2(enemy.pos).distance_to(game.player.position) < 29.0:
			game.take_damage(18.0+stage_index*4.0,"%s扑倒了牛仔" % ENEMY_NAMES[stage_index])
			enemy.pos=Vector2(enemy.pos)-(offset.normalized()*75.0)
			enemies[i]=enemy
	for i in range(hit_flashes.size()-1,-1,-1):
		hit_flashes[i].time = float(hit_flashes[i].time)-delta
		if float(hit_flashes[i].time)<=0: hit_flashes.remove_at(i)
	queue_redraw()

func shoot_at(point: Vector2, damage: int) -> Dictionary:
	var best := -1
	var distance := 62.0
	for i in enemies.size():
		var d := Vector2(enemies[i].pos).distance_to(point)
		if d < distance:
			distance=d; best=i
	if best < 0: return {}
	var enemy: Dictionary = enemies[best]
	enemy.hp = maxi(0,int(enemy.hp)-damage)
	var position: Vector2 = enemy.pos
	var killed := int(enemy.hp)<=0
	hit_flashes.append({"pos":position,"time":0.18})
	if killed:
		enemies.remove_at(best)
	else:
		enemies[best]=enemy
	if enemies.is_empty() and not cleared:
		cleared=true
		game.complete_campaign_stage(stage_index)
	queue_redraw()
	return {"hit":true,"killed":killed,"position":position,"reward":(900+stage_index*650) if killed else 0,"damage":damage}

func can_exit() -> bool: return cleared

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),COLORS[stage_index])
	draw_rect(Rect2(0,530,1280,190),COLORS[stage_index].lightened(0.12))
	_draw_environment()
	_draw_detail_pass()
	for enemy in enemies:
		var rise := float(enemy.get("rise",1.0))
		var ep: Vector2 = enemy.pos
		if rise<1.0:
			_draw_oval(ep+Vector2(0,22),Vector2(48,16),Color("#19171a"))
			var emerging: Dictionary = enemy.duplicate()
			emerging.pos = Vector2.ZERO
			draw_set_transform(ep+Vector2(0,32*(1.0-rise)),0,Vector2(1.0,maxf(0.08,rise)))
			_draw_enemy(emerging)
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			for grit in 7:
				draw_rect(Rect2(ep+Vector2(-42+grit*14,sin(elapsed*9+grit)*9+28),Vector2(7,5)),Color("#716044"))
		else: _draw_enemy(enemy)
	if arrival < 1.3:
		draw_rect(Rect2(0,54,1280,666),Color(0.03,0.03,0.05,1.0-arrival/1.3))
	for flash in hit_flashes:
		var size := 18.0+float(flash.time)*100.0
		draw_arc(Vector2(flash.pos),size,0,TAU,16,Color("#fff09a"),5)
	_draw_marker(ENTRY_POINT,0)
	_draw_marker(HEART_POINT if stage_index==5 else EXIT_POINT,1)

func _draw_environment() -> void:
	# Dense ground texture keeps each combat map from looking like a flat board.
	for i in 520:
		var px:=float((i*197+stage_index*83)%1240+20)
		var py:=float((i*113+stage_index*61)%610+72)
		var speck: Color=COLORS[stage_index].lightened(0.18) if i%2==0 else COLORS[stage_index].darkened(0.12)
		draw_rect(Rect2(px,py,3+i%3,3+i%2),speck)
	if stage_index == 0:
		for x in range(100,1200,150):
			var y:=170+(x%3)*65
			draw_rect(Rect2(x,y,55,75),Color("#817c6a")); draw_rect(Rect2(x-9,y+8,73,12),Color("#aaa38a")); draw_rect(Rect2(x+10,y+34,34,5),Color("#514b43"))
			for root in [-1,1]: draw_line(Vector2(x+27,y+75),Vector2(x+27+root*22,y+91),Color("#3b3029"),5)
		# Engraved slabs, chips, burial mounds and votive candles.
		for x in range(100,1200,150):
			var y := 170+(x%3)*65
			draw_rect(Rect2(x+4,y+24,46,3),Color("#b1a88b"))
			draw_rect(Rect2(x+6,y+30,3,38),Color("#5f5d50"))
			for line in 3: draw_rect(Rect2(x+16,y+44+line*6,22-line*4,2),Color("#4c4d43"))
			draw_line(Vector2(x+42,y+9),Vector2(x+34,y+22),Color("#4e5047"),2)
			draw_line(Vector2(x+34,y+22),Vector2(x+39,y+32),Color("#4e5047"),2)
			_draw_oval(Vector2(x+25,y+100),Vector2(40,14),Color("#303d31"))
			for dirt in 8: draw_rect(Rect2(x-9+dirt*9,y+94+dirt%2*8,5,3),Color("#645d45"))
			draw_rect(Rect2(x-12,y+55,6,18),Color("#d5c4a0"))
			draw_rect(Rect2(x-11,y+49,4,6),Color("#e6ae51"))
		# Collapsed crypt mouth, broken arch, candles and dead trees.
		draw_rect(Rect2(34,548,86,115),Color("#302d2c")); draw_arc(Vector2(77,552),48,PI,TAU,18,Color("#91866f"),12)
		for i in 9: draw_circle(Vector2(38+(i%3)*32,600+(i/3)*23),16+i%3*4,Color("#6f6759"))
		for x in [225,1040]:
			draw_line(Vector2(x,500),Vector2(x,260),Color("#302c29"),18); draw_line(Vector2(x,330),Vector2(x-70,260),Color("#302c29"),11); draw_line(Vector2(x,365),Vector2(x+75,300),Color("#302c29"),10)
		for i in 8: draw_circle(Vector2(300+i*105,120+i%2*300),35,Color("#d7d0bd",0.04))
	elif stage_index == 1:
		for x in range(60,1250,115):
			draw_circle(Vector2(x,210+(x%4)*90),50,Color("#243c34")); draw_line(Vector2(x,250),Vector2(x-20,345),Color("#795f43"),14)
		for x in range(160,1120,180): _draw_oval(Vector2(x,560+(x%2)*60),Vector2(80,28),Color("#273c39"))
		# Visible rotten raft with rope, logs and a crooked pole.
		for y in range(585,646,13): draw_rect(Rect2(35,y,150,10),Color("#765638")); draw_rect(Rect2(38,y+2,144,3),Color("#a17b4d"))
		draw_line(Vector2(46,580),Vector2(174,650),Color("#3f3027"),4); draw_line(Vector2(174,580),Vector2(46,650),Color("#3f3027"),4)
		draw_line(Vector2(162,585),Vector2(196,490),Color("#5c4632"),8); draw_colored_polygon(PackedVector2Array([Vector2(190,493),Vector2(245,535),Vector2(180,548)]),Color("#665a47"))
		for i in 12: draw_circle(Vector2(250+i*70,480+(i%3)*37),6,Color("#8b334b")); draw_circle(Vector2(250+i*70,480+(i%3)*37),2,Color("#e1bd55"))
	elif stage_index == 2:
		draw_rect(Rect2(180,110,920,390),Color("#352d3b"));
		for x in range(210,1080,110): draw_rect(Rect2(x,140,22,360),Color("#756878"))
		draw_circle(Vector2(1195,115),42,Color("#b69a57")); draw_circle(Vector2(1195,115),25,Color("#352d3b"))
		for x in range(250,1050,170):
			draw_rect(Rect2(x,190,85,120),Color("#241d2c")); draw_colored_polygon(PackedVector2Array([Vector2(x+8,300),Vector2(x+42,202),Vector2(x+77,300)]),Color("#7f284d")); draw_circle(Vector2(x+42,258),12,Color("#cf9a43"))
		for y in [400,455]:
			for x in range(250,1050,150): draw_rect(Rect2(x,y,110,18),Color("#6c4d3c")); draw_rect(Rect2(x+12,y+18,12,40),Color("#49342e"))
	elif stage_index == 3:
		for x in range(0,1280,95): draw_colored_polygon(PackedVector2Array([Vector2(x,530),Vector2(x+48,180+(x%5)*45),Vector2(x+95,530)]),Color("#4f302e"))
		draw_rect(Rect2(1150,70,90,150),Color("#382921")); draw_line(Vector2(1170,70),Vector2(1170,210),Color("#d0c39c"),8)
		draw_rect(Rect2(1110,195,145,35),Color("#6a5741")); draw_rect(Rect2(1130,225,105,50),Color("#373330")); draw_circle(Vector2(1145,275),15,Color("#171a1d")); draw_circle(Vector2(1218,275),15,Color("#171a1d"))
		for x in range(150,1080,160): draw_line(Vector2(x,500),Vector2(x+85,420),Color("#d8cfb2"),11); draw_circle(Vector2(x+45,458),13,Color("#80253e"))
	elif stage_index == 4:
		for x in range(90,1240,145):
			draw_circle(Vector2(x,190+(x%4)*80),58,Color("#782b49")); draw_circle(Vector2(x,190+(x%4)*80),25,Color("#2f1422")); draw_circle(Vector2(x-12,180+(x%4)*80),6,Color("#e6b34d"))
		draw_circle(EXIT_POINT,48,Color("#2b101d")); draw_arc(EXIT_POINT,48,0,TAU,24,Color("#a43459"),12)
		for x in range(120,1100,120):
			draw_line(Vector2(x,54),Vector2(x+sin(x)*20,180+(x%5)*30),Color("#7e2848"),8); draw_circle(Vector2(x,190+(x%5)*30),18,Color("#a83757")); draw_circle(Vector2(x+4,190+(x%5)*30),5,Color("#e3bf57"))
	else:
		for x in range(0,1280,80):
			draw_colored_polygon(PackedVector2Array([Vector2(x,54),Vector2(x+40,115+(x%3)*25),Vector2(x+80,54)]),Color("#181923"))
			draw_line(Vector2(0,610),Vector2(1280,610),Color("#775b3c"),8)
		for x in range(20,1260,55): draw_line(Vector2(x,600),Vector2(x+18,625),Color("#98734c"),7)
		for x in range(80,1230,180): draw_rect(Rect2(x,95,18,470),Color("#513e34")); draw_line(Vector2(x-35,125),Vector2(x+55,125),Color("#785b42"),13)
		for p in [Vector2(310,185),Vector2(525,350),Vector2(760,150),Vector2(1210,420)]:
			draw_colored_polygon(PackedVector2Array([p+Vector2(-14,20),p,p+Vector2(12,24)]),Color("#5c8db0")); draw_line(p,p+Vector2(0,35),Color("#9bd2e8"),3)
		# Grandfather's stone altar, candles and faded portrait.
		draw_rect(Rect2(920,255,240,95),Color("#3d3940")); draw_rect(Rect2(900,335,280,34),Color("#17191f"))
		draw_rect(Rect2(1000,265,80,58),Color("#6e5948")); draw_rect(Rect2(1010,274,60,40),Color("#352d2a")); draw_circle(Vector2(1040,288),11,Color("#b28a65")); draw_rect(Rect2(1028,299,24,14),Color("#493b35"))
		for x in [940,1130]: draw_rect(Rect2(x,308,7,29),Color("#d7c38a")); draw_circle(Vector2(x+3,305),6,Color("#f0a947"))
		# Movable mine cart parked at the entry and grandfather's parasite heart.
		draw_rect(Rect2(105,565,105,48),Color("#624736")); draw_rect(Rect2(115,575,85,25),Color("#8d6546")); draw_circle(Vector2(130,615),12,Color("#292d32")); draw_circle(Vector2(187,615),12,Color("#292d32"))
		if is_instance_valid(game) and game.parasite_heart_destroyed:
			for i in 12: draw_rect(Rect2(HEART_POINT+Vector2((i%4)*18-36,(i/4)*13-10),Vector2(12,8)),Color("#2a1d22"))
		else:
			var pulse := 48.0+sin(elapsed*3.0)*5.0
			draw_circle(HEART_POINT,pulse,Color("#8b1e42")); draw_circle(HEART_POINT+Vector2(-18,-8),27,Color("#bd3156")); draw_circle(HEART_POINT+Vector2(20,-10),29,Color("#a92549"))
			for i in 7: draw_line(HEART_POINT,HEART_POINT+Vector2.from_angle(i*TAU/7.0)*(75+20*(i%2)),Color("#60172f"),8)

func _draw_oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24: pts.append(center+Vector2(cos(i*TAU/24.0)*radius.x,sin(i*TAU/24.0)*radius.y))
	draw_colored_polygon(pts,color)

func _draw_enemy(enemy: Dictionary) -> void:
	var p: Vector2 = enemy.pos
	var kind := int(enemy.kind)
	draw_rect(Rect2(p+Vector2(-34,24),Vector2(68,10)),Color("#14191a",0.4))
	# Every stage has a different parasite skeleton silhouette.
	if kind == 0:
		draw_polyline(PackedVector2Array([p+Vector2(-35,15),p+Vector2(-10,-8),p+Vector2(22,7),p+Vector2(38,-6)]),Color("#ddd1ad"),7)
		for x in [-22,0,20]: draw_line(p+Vector2(x,3),p+Vector2(x-10,28),Color("#712038"),6)
	elif kind == 1:
		draw_line(p+Vector2(0,-32),p+Vector2(0,25),Color("#d4c7a6"),7)
		for side in [-1,1]: draw_line(p+Vector2(0,-12),p+Vector2(side*38,20),Color("#6f253a"),7)
		draw_circle(p+Vector2(0,-40),15,Color("#cfc4a6"))
	elif kind == 2:
		draw_rect(Rect2(p+Vector2(-22,-34),Vector2(44,68)),Color("#71627a")); draw_circle(p+Vector2(0,-42),18,Color("#e0d2ae")); draw_rect(Rect2(p+Vector2(-13,-47),Vector2(26,12)),Color("#32182b"))
	elif kind == 3:
		draw_polyline(PackedVector2Array([p+Vector2(-45,12),p+Vector2(-18,-15),p+Vector2(18,10),p+Vector2(44,-18)]),Color("#e2d5b2"),9)
		for side in [-1,1]: draw_line(p,p+Vector2(side*42,33),Color("#77223a"),9)
	elif kind == 4:
		draw_circle(p,38,Color("#7f2748")); draw_circle(p,24,Color("#d5c8a7"));
		for i in 6: draw_line(p,p+Vector2.from_angle(i*TAU/6.0)*58,Color("#9c3054"),8)
	else:
		draw_rect(Rect2(p+Vector2(-35,-40),Vector2(70,75)),Color("#4a4650")); draw_circle(p+Vector2(0,-48),28,Color("#dacdab")); draw_rect(Rect2(p+Vector2(-19,-55),Vector2(13,13)),Color("#b12443")); draw_rect(Rect2(p+Vector2(7,-55),Vector2(13,13)),Color("#b12443"))
	# Shared horror detail: exposed ribs, wet parasite cords, too many eyes and a split jaw.
	for rib in range(-2,3):
		draw_arc(p+Vector2(rib*8,4),Vector2(13,19).length(),-1.2,1.2,7,Color("#d9ceb0"),3)
	for eye in range(3+kind%3):
		var ep:=p+Vector2(-18+eye*10,-25+(eye%2)*8)
		draw_circle(ep,4,Color("#a51f3e")); draw_circle(ep,1.5,Color("#f4d060"))
	draw_rect(Rect2(p+Vector2(-17,18),Vector2(35,8)),Color("#1b1016"))
	for tooth in range(5): draw_colored_polygon(PackedVector2Array([p+Vector2(-15+tooth*7,18),p+Vector2(-10+tooth*7,18),p+Vector2(-12+tooth*7,27)]),Color("#e6ddbe"))
	for cord in 5:
		var root:=p+Vector2(-25+cord*13,10)
		var tip:=root+Vector2(sin(elapsed*5.0+cord+float(enemy.phase))*18,34+cord%2*12)
		draw_line(root,tip,Color("#7d1e3b"),5); draw_circle(tip,4,Color("#c43851"))
	var ratio := float(enemy.hp)/float(enemy.max_hp)
	draw_rect(Rect2(p+Vector2(-34,-72),Vector2(68,7)),Color("#24161b")); draw_rect(Rect2(p+Vector2(-32,-70),Vector2(64*ratio,3)),Color("#dd4854"))

func _draw_marker(point: Vector2, index: int) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var p := point+Vector2(-14,-53+roundf(sin(elapsed*3.0+index))*2.0)
	var ink := Color("#ffe4a0") if active else Color("#b59164")
	draw_rect(Rect2(p,Vector2(28,32)),Color("#251d22")); draw_rect(Rect2(p+Vector2(4,4),Vector2(20,24)),Color("#573047")); draw_rect(Rect2(p+Vector2(11,7),Vector2(6,11)),ink); draw_rect(Rect2(p+Vector2(11,22),Vector2(6,4)),ink)

func _draw_detail_pass() -> void:
	for i in 75:
		var p := Vector2(24+(i*157)%1210,160+(i*97)%520)
		var ground: Color = COLORS[stage_index]
		draw_line(p,p+Vector2(6,-7),ground.darkened(0.22),2)
		draw_line(p+Vector2(5,0),p+Vector2(9,-10),ground.lightened(0.17),2)
		if i%4==0:
			draw_rect(Rect2(p+Vector2(-3,2),Vector2(18,6)),ground.darkened(0.3))
			draw_rect(Rect2(p,Vector2(11,5)),ground.lightened(0.2))
	if stage_index == 0:
		for row in 7:
			for col in 14:
				var p := Vector2(235+col*65+(row%2)*24,465+row*23)
				draw_rect(Rect2(p,Vector2(58,19)),Color("#646459").darkened((col%3)*0.04))
				draw_line(p,p+Vector2(55,0),Color("#97907a"),2)
				draw_line(p+Vector2(7,3),p+Vector2(23,11),Color("#454a43"),1)
				if col%3==0: draw_rect(Rect2(p+Vector2(1,13),Vector2(18,3)),Color("#465e43"))
		for x in range(20,1260,27):
			draw_line(Vector2(x,145),Vector2(x,78),Color("#252c2b"),4)
			draw_colored_polygon(PackedVector2Array([Vector2(x-5,82),Vector2(x,68),Vector2(x+5,82)]),Color("#4c5550"))
		draw_line(Vector2(20,112),Vector2(1260,112),Color("#444e48"),5)
		for row in 5:
			for col in 4:
				draw_rect(Rect2(5+col*35+(row%2)*8,435+row*32,32,28),Color("#777464"))
		draw_rect(Rect2(36,468,78,172),Color("#15171a"))
		for i in 22:
			var t := clampf((arrival-0.35-float(i%5)*0.09)/1.4,0.0,1.0)
			var p := Vector2(20+(i%5)*26,450+(i/5)*22+145*t*t)
			draw_rect(Rect2(p,Vector2(21+i%3*4,19)),Color("#817c6c").darkened((i%3)*0.1))
		if arrival<2.6:
			for i in 13: draw_circle(Vector2(15+i*13,630-sin(arrival*3+i)*22),18,Color("#b3a78d",maxf(0.0,0.32-arrival*0.1)))
		_draw_boat(EXIT_POINT+Vector2(-75,35))
	elif stage_index == 1:
		_draw_boat(ENTRY_POINT+Vector2(15,-20))
	elif stage_index == 2:
		for x in [175,1090]:
			for y in range(120,490,28): draw_rect(Rect2(x,y,28,23),Color("#756573"))
	elif stage_index == 3:
		var lift := EXIT_POINT+Vector2(-65,80+sin(elapsed)*9)
		for x in [-70,70]:
			draw_rect(Rect2(lift+Vector2(x,-205),Vector2(12,250)),Color("#41464b"))
			for y in range(-200,0,15): draw_rect(Rect2(lift+Vector2(x+3,y),Vector2(6,6)),Color("#ada28a"))
		draw_rect(Rect2(lift+Vector2(-75,-40),Vector2(150,90)),Color("#342d2c"))
		for x in range(-65,70,20): draw_line(lift+Vector2(x,-38),lift+Vector2(x,40),Color("#b1a386"),5)
		draw_rect(Rect2(lift+Vector2(-85,40),Vector2(170,18)),Color("#8e6e47"))
		draw_circle(lift+Vector2(0,-195),24,Color("#4e4840"))
		for i in 8: draw_line(lift+Vector2(0,-195),lift+Vector2(0,-195)+Vector2.from_angle(elapsed+i*TAU/8)*20,Color("#c2af81"),3)

func _draw_boat(p: Vector2) -> void:
	p.y += roundf(sin(elapsed*1.8)*3.0)
	_draw_oval(p+Vector2(0,37),Vector2(105,30),Color("#243e40"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-100,0),p+Vector2(-66,-29),p+Vector2(74,-29),p+Vector2(105,4),p+Vector2(67,42),p+Vector2(-65,42)]),Color("#4a3025"))
	for row in 5: draw_rect(Rect2(p+Vector2(-65,-21+row*11),Vector2(138,8)),Color("#a47847").darkened(row*0.07))
	for x in [-48,8,58]: draw_rect(Rect2(p+Vector2(x,-24),Vector2(10,64)),Color("#c29a5e"))
	draw_line(p+Vector2(-85,-38),p+Vector2(78,65),Color("#b58b53"),7)
	draw_colored_polygon(PackedVector2Array([p+Vector2(62,47),p+Vector2(78,42),p+Vector2(101,69),p+Vector2(84,79)]),Color("#83613c"))


