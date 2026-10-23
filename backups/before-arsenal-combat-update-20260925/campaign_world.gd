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
			"kind":stage_index,"phase":randf()*TAU
		})

func _process(delta: float) -> void:
	if not visible or game.suspended: return
	elapsed += delta
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var offset: Vector2 = game.player.position-Vector2(enemy.pos)
		if offset.length() < 520 and offset.length() > 2:
			var side := Vector2(-offset.y,offset.x).normalized()*sin(elapsed*2.2+float(enemy.phase))*12.0
			enemy.pos = Vector2(enemy.pos)+(offset.normalized()*float(enemy.speed)+side)*delta
		enemies[i] = enemy
		if Vector2(enemy.pos).distance_to(game.player.position) < 29.0:
			game.combat_defeat("%s扑倒了牛仔" % ENEMY_NAMES[stage_index])
			return
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
	for enemy in enemies: _draw_enemy(enemy)
	for flash in hit_flashes:
		var size := 18.0+float(flash.time)*100.0
		draw_arc(Vector2(flash.pos),size,0,TAU,16,Color("#fff09a"),5)
	_draw_marker(ENTRY_POINT,0)
	_draw_marker(HEART_POINT if stage_index==5 else EXIT_POINT,1)

func _draw_environment() -> void:
	if stage_index == 0:
		for x in range(100,1200,150):
			draw_rect(Rect2(x,170+(x%3)*65,55,75),Color("#817c6a")); draw_rect(Rect2(x-9,178+(x%3)*65,73,12),Color("#aaa38a"))
		draw_circle(Vector2(75,625),45,Color("#1f2220")); draw_arc(Vector2(75,625),45,0,TAU,24,Color("#9d8b64"),7)
	elif stage_index == 1:
		for x in range(60,1250,115):
			draw_circle(Vector2(x,210+(x%4)*90),50,Color("#243c34")); draw_line(Vector2(x,250),Vector2(x-20,345),Color("#795f43"),14)
		for x in range(160,1120,180): _draw_oval(Vector2(x,560+(x%2)*60),Vector2(80,28),Color("#273c39"))
	elif stage_index == 2:
		draw_rect(Rect2(180,110,920,390),Color("#352d3b"));
		for x in range(210,1080,110): draw_rect(Rect2(x,140,22,360),Color("#756878"))
		draw_circle(Vector2(1195,115),42,Color("#b69a57")); draw_circle(Vector2(1195,115),25,Color("#352d3b"))
	elif stage_index == 3:
		for x in range(0,1280,95): draw_colored_polygon(PackedVector2Array([Vector2(x,530),Vector2(x+48,180+(x%5)*45),Vector2(x+95,530)]),Color("#4f302e"))
		draw_rect(Rect2(1150,70,90,150),Color("#382921")); draw_line(Vector2(1170,70),Vector2(1170,210),Color("#d0c39c"),8)
	elif stage_index == 4:
		for x in range(90,1240,145):
			draw_circle(Vector2(x,190+(x%4)*80),58,Color("#782b49")); draw_circle(Vector2(x,190+(x%4)*80),25,Color("#2f1422")); draw_circle(Vector2(x-12,180+(x%4)*80),6,Color("#e6b34d"))
		draw_circle(EXIT_POINT,48,Color("#2b101d")); draw_arc(EXIT_POINT,48,0,TAU,24,Color("#a43459"),12)
	else:
		for x in range(0,1280,80):
			draw_colored_polygon(PackedVector2Array([Vector2(x,54),Vector2(x+40,115+(x%3)*25),Vector2(x+80,54)]),Color("#181923"))
			draw_line(Vector2(0,610),Vector2(1280,610),Color("#775b3c"),8)
		for x in range(20,1260,55): draw_line(Vector2(x,600),Vector2(x+18,625),Color("#98734c"),7)
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
	var ratio := float(enemy.hp)/float(enemy.max_hp)
	draw_rect(Rect2(p+Vector2(-34,-72),Vector2(68,7)),Color("#24161b")); draw_rect(Rect2(p+Vector2(-32,-70),Vector2(64*ratio,3)),Color("#dd4854"))

func _draw_marker(point: Vector2, index: int) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	var active: bool = game.player.faces_point(point,155.0)
	var p := point+Vector2(-14,-53+roundf(sin(elapsed*3.0+index))*2.0)
	var ink := Color("#ffe4a0") if active else Color("#b59164")
	draw_rect(Rect2(p,Vector2(28,32)),Color("#251d22")); draw_rect(Rect2(p+Vector2(4,4),Vector2(20,24)),Color("#573047")); draw_rect(Rect2(p+Vector2(11,7),Vector2(6,11)),ink); draw_rect(Rect2(p+Vector2(11,22),Vector2(6,4)),ink)
