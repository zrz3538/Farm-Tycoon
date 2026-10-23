extends Node2D

const STAGE_COUNT:=6
const FINAL_STAGE:=5
const STAGE_NAMES:=["沉土墓园","腐水浅滩","山谷礼拜堂","断脊峡谷","研究温室","寄生虫矿井"]
const ENEMY_NAMES:=["墓园骷髅","沼泽骨鳄","钟楼骷髅","裂谷迅猛龙","温室迅猛龙","核心守门兽"]
const ENTRY_POINT:=Vector2(90,630)
const EXIT_POINT:=Vector2(1150,155)
const HEART_POINT:=Vector2(1080,245)
const PARASITE_DOG:=preload("res://assets/enemies/parasite_skeletons/parasite_dog.png")
const PARASITE_PIG:=preload("res://assets/enemies/parasite_skeletons/parasite_pig.png")
const PARASITE_HUMAN:=preload("res://assets/enemies/parasite_skeletons/parasite_human.png")
const NEW_SPECIES:=preload("res://assets/enemies/parasite_skeletons/new_species_3x2.png")
const TNT_SHEET:=preload("res://assets/effects/tnt_box_4x2.png")
const MARKER_SHEET:=preload("res://assets/ui/interaction_marker_4x1.png")
const Foreground:=preload("res://campaign_foreground.gd")

var stage_index:=0
var elapsed:=0.0
var arrival:=0.0
var enemies:Array[Dictionary]=[]
var cleared:=false
var game:Node
var layout:Dictionary={}
var background:Texture2D
var hit_flashes:Array[Dictionary]=[]
var broken_graves:Array[Vector2]=[]
var tnt_active:=false
var tnt_elapsed:=0.0
var tnt_callback:=Callable()
var wave_index:=0
var wave_total:=2

func setup(index:int)->void:
	stage_index=index
	name="CampaignWorld%02d"%(index+1)

func _ready()->void:
	game=get_parent();texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var file:=FileAccess.open("res://assets/maps/story/campaign_layouts.json",FileAccess.READ)
	var all:Variant=JSON.parse_string(file.get_as_text()) if file else []
	if all is Array and stage_index<all.size():layout=all[stage_index]
	background=load("res://assets/maps/story/campaign_%02d.png"%stage_index)
	_build_collisions()
	var foreground:=Foreground.new();add_child(foreground);foreground.setup(self)
	queue_redraw()

func _build_collisions()->void:
	for raw in layout.get("collisions",[]):
		var a:Array=raw
		if a.size()>=4:_add_solid(Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3])))
	for rect in [Rect2(0,54,18,540),Rect2(0,680,1280,40),Rect2(1262,54,18,626),Rect2(0,54,1280,18)]:_add_solid(rect)

func _add_solid(rect:Rect2)->void:
	var body:=StaticBody2D.new();var collision:=CollisionShape2D.new();var shape:=RectangleShape2D.new()
	shape.size=rect.size;collision.shape=shape;body.position=rect.get_center();body.add_child(collision);add_child(body)

func _vec(value:Variant)->Vector2:
	return Vector2(float(value[0]),float(value[1])) if value is Array and value.size()>=2 else Vector2.ZERO
func get_entry_point()->Vector2:return _vec(layout.get("entry",[90,630]))
func get_exit_point()->Vector2:return _vec(layout.get("exit",[1150,155]))
func get_note_point()->Vector2:return _vec(layout.get("note_point",[640,560]))
func get_heart_point()->Vector2:return _vec(layout.get("heart",[1080,245]))
func get_title()->String:return str(layout.get("title",STAGE_NAMES[stage_index]))
func get_subtitle()->String:return str(layout.get("subtitle","继续深入"))
func get_note_text()->String:return str(layout.get("note",""))
func is_interior()->bool:return bool(layout.get("interior",false))

func activate()->void:
	arrival=0.0;cleared=game.campaign_progress>stage_index
	if not cleared and enemies.is_empty():
		wave_index=0
		wave_total=2+(1 if is_interior() or stage_index%5==4 else 0)
		_spawn_wave()
	queue_redraw()

func _spawn_wave()->void:
	enemies.clear()
	if wave_index==0:broken_graves.clear()
	var count:=int(layout.get("enemy_count",4))
	var spots:=[Vector2(310,210),Vector2(520,190),Vector2(765,235),Vector2(980,340),Vector2(760,470),Vector2(510,500),Vector2(290,445),Vector2(1060,540),Vector2(875,590),Vector2(600,340)]
	for i in count:
		var hp:=130+stage_index*34+wave_index*55+(180 if stage_index==FINAL_STAGE else 0)
		var kind:=7 if stage_index==FINAL_STAGE else (0 if stage_index==0 else (stage_index+floori(i/2.0)+wave_index)%8)
		enemies.append({"pos":spots[i%spots.size()]+Vector2((i%3)*16,-(i%2)*12),"hp":hp,"max_hp":hp,"speed":39.0+minf(34.0,stage_index*1.2)+(i%3)*2.5,"kind":kind,"variant":i%2,"rise":0.0,"phase":float(i)*1.37,"attack":0.0,"attack_cooldown":0.25+float(i%3)*0.17,"attack_hit":false})

func start_tnt_sequence(callback:Callable)->void:
	if tnt_active:return
	tnt_active=true;tnt_elapsed=0.0;tnt_callback=callback;queue_redraw()

func _process(delta:float)->void:
	if not visible or not is_instance_valid(game) or game.suspended:return
	elapsed+=delta;arrival+=delta
	if tnt_active:
		tnt_elapsed+=delta
		if tnt_elapsed>=1.72:
			tnt_active=false
			if tnt_callback.is_valid():tnt_callback.call_deferred()
	for i in enemies.size():
		var enemy:Dictionary=enemies[i]
		var old_rise:=float(enemy.get("rise",0.0));enemy.rise=minf(1.0,old_rise+delta*0.72)
		if stage_index==0 and old_rise<1.0 and float(enemy.rise)>=1.0:broken_graves.append(Vector2(enemy.pos))
		if float(enemy.rise)<1.0:enemies[i]=enemy;continue
		var offset:Vector2=game.player.position-Vector2(enemy.pos)
		enemy.attack_cooldown=maxf(0.0,float(enemy.attack_cooldown)-delta);enemy.attack=maxf(0.0,float(enemy.attack)-delta)
		if offset.length()<82.0 and float(enemy.attack_cooldown)<=0.0:
			enemy.attack=0.46;enemy.attack_cooldown=1.0;enemy.attack_hit=false
		if float(enemy.attack)>0.0:
			var progress:=1.0-float(enemy.attack)/0.46
			if progress>0.36 and progress<0.68 and not bool(enemy.attack_hit) and offset.length()<96.0:
				enemy.attack_hit=true;game.take_damage(13.0+stage_index*0.8,"被%s击中"%ENEMY_NAMES[stage_index])
		elif offset.length()<560.0 and offset.length()>4.0:
			var side:=Vector2(-offset.y,offset.x).normalized()*sin(elapsed*2.0+float(enemy.phase))*11.0
			enemy.pos=Vector2(enemy.pos)+(offset.normalized()*float(enemy.speed)+side)*delta
		enemies[i]=enemy
	for i in range(hit_flashes.size()-1,-1,-1):
		hit_flashes[i].time=float(hit_flashes[i].time)-delta
		if float(hit_flashes[i].time)<=0:hit_flashes.remove_at(i)
	queue_redraw()

func shoot_at(point:Vector2,damage:int)->Dictionary:
	var best:=-1;var distance:=102.0
	for i in enemies.size():
		var d:=Vector2(enemies[i].pos).distance_to(point)
		if d<distance:distance=d;best=i
	if best<0:return {}
	var enemy:Dictionary=enemies[best];enemy.hp=maxi(0,int(enemy.hp)-damage)
	var p:Vector2=enemy.pos;var killed:=int(enemy.hp)<=0
	hit_flashes.append({"pos":p,"time":0.2})
	if killed:enemies.remove_at(best)
	else:enemies[best]=enemy
	if enemies.is_empty() and not cleared:
		if wave_index+1<wave_total:
			wave_index+=1
			_spawn_wave()
			game.show_message("下一批骨骸从区域深处爬了出来 · WAVE %d/%d"%[wave_index+1,wave_total])
		else:
			cleared=true;game.complete_campaign_stage(stage_index)
	queue_redraw()
	return {"hit":true,"killed":killed,"position":p,"reward":int(layout.get("reward",1000)) if killed else 0,"damage":damage}

func can_exit()->bool:return cleared

func _draw()->void:
	if is_instance_valid(background):draw_texture_rect(background,Rect2(0,0,1280,720),false)
	if stage_index==0:
		for grave in broken_graves:_draw_broken_grave(grave,1.0)
	for enemy in enemies:
		var rise:=float(enemy.get("rise",1.0));var p:Vector2=enemy.pos
		if rise<1.0:
			if stage_index==0:_draw_broken_grave(p,rise)
			_draw_oval(p+Vector2(0,22),Vector2(43,13),Color("#17191d"))
			var emerging:=enemy.duplicate();emerging.pos=Vector2.ZERO
			draw_set_transform(p+Vector2(0,34*(1.0-rise)),0,Vector2(1.0,maxf(0.08,rise)));_draw_enemy(emerging);draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			for grit in 6:draw_rect(Rect2(p+Vector2(-36+grit*13,sin(elapsed*9+grit)*7+25),Vector2(7,5)),Color("#77634b"))
		else:_draw_enemy(enemy)
	if tnt_active:_draw_tnt_box()
	for flash in hit_flashes:
		var size:=18.0+float(flash.time)*110.0;draw_arc(Vector2(flash.pos),size,0,TAU,16,Color("#fff09a"),5)
	_draw_marker(get_entry_point(),0);_draw_marker(get_exit_point(),1);_draw_note_marker(get_note_point())
	if arrival<1.15:draw_rect(Rect2(0,54,1280,666),Color(0.02,0.025,0.035,1.0-arrival/1.15))

func _draw_enemy(enemy:Dictionary)->void:
	var p:Vector2=enemy.pos;var kind:=int(enemy.kind);var texture:Texture2D=PARASITE_HUMAN;var region:=Rect2();var size:=Vector2(76,108)
	match kind:
		0:texture=PARASITE_HUMAN;size=Vector2(76,108)
		1:texture=PARASITE_DOG;size=Vector2(94,72)
		2:texture=PARASITE_PIG;size=Vector2(98,76)
		3:texture=NEW_SPECIES;region=Rect2(0,0,512,512);size=Vector2(102,90)
		4:texture=NEW_SPECIES;region=Rect2(512,0,512,512);size=Vector2(104,92)
		5:texture=NEW_SPECIES;region=Rect2(1024,0,512,512);size=Vector2(112,78)
		6:texture=NEW_SPECIES;region=Rect2(0,512,512,512);size=Vector2(106,104)
		7:texture=NEW_SPECIES;region=Rect2(512 if int(enemy.variant)==0 else 1024,512,512,512);size=Vector2(116,108)
	var attack_time:=float(enemy.get("attack",0.0));var attacking:=attack_time>0.0;var attack_progress:=1.0-attack_time/0.46 if attacking else 0.0
	var stride:=sin(elapsed*(9.5+float(enemy.speed)*0.04)+float(enemy.phase));var step:=absf(stride);var facing:=1.0 if game.player.position.x>=p.x else -1.0
	var lunge:=sin(attack_progress*PI)*27.0 if attacking else 0.0;p.x+=facing*lunge
	draw_rect(Rect2(p+Vector2(-size.x*0.31,23),Vector2(size.x*0.62,10)),Color("#11171a",0.44))
	if step>0.75:
		for grit in 3:draw_rect(Rect2(p+Vector2(-facing*(28+grit*7),19-grit*3),Vector2(5,4)),Color("#8b7558",0.56))
	var tilt:=(-facing*0.26*sin(attack_progress*PI)) if attacking else stride*0.12;var stretch:=0.18*sin(attack_progress*PI) if attacking else step*0.07
	draw_set_transform(p+Vector2(stride*5.0,29-step*8.0),tilt,Vector2(facing*(1.0+stretch),1.0-stretch*0.5))
	if region.size==Vector2.ZERO:draw_texture_rect(texture,Rect2(-size.x*0.5,-size.y,size.x,size.y),false)
	else:draw_texture_rect_region(texture,Rect2(-size.x*0.5,-size.y,size.x,size.y),region)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if attacking:
		var center:=p+Vector2(facing*35,-22);draw_arc(center,30,-1.15 if facing>0 else PI-1.15,1.15 if facing>0 else PI+1.15,10,Color("#ffe0a0",0.9),4)
	var ratio:=float(enemy.hp)/float(enemy.max_hp);var y:=p.y-size.y+18
	draw_rect(Rect2(p.x-35,y,70,7),Color("#21161a"));draw_rect(Rect2(p.x-33,y+2,66*ratio,3),Color("#dc4853"))

func _draw_broken_grave(p:Vector2,progress:float)->void:
	var open:=clampf((progress-0.16)/0.84,0.0,1.0)
	if open<=0.0:return
	_draw_oval(p+Vector2(0,14),Vector2(47,14),Color("#202328"))
	for piece in 9:
		var angle:=piece*TAU/9.0;var q:=p+Vector2.from_angle(angle)*(18.0+open*(17+piece%3*6))+Vector2(0,-5)
		draw_set_transform(q,angle+open*1.5,Vector2.ONE);draw_rect(Rect2(-7,-5,14,10),Color("#8d9187"));draw_rect(Rect2(-7,-5,14,10),Color("#23303a"),false,2);draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_tnt_box()->void:
	var cell:=Vector2(TNT_SHEET.get_width()/4.0,TNT_SHEET.get_height()/2.0);var frame:=clampi(int(tnt_elapsed/0.215),0,7)
	var source:=Rect2(Vector2(frame%4,floori(frame/4.0))*cell,cell);var pulse:=1.0+sin(tnt_elapsed*19.0)*0.025
	draw_set_transform(get_heart_point()+Vector2(0,100),0,Vector2(pulse,pulse));draw_texture_rect_region(TNT_SHEET,Rect2(-76,-76,152,152),source);draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_marker(point:Vector2,index:int)->void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):return
	var active:bool=game.player.faces_point(point,155.0);var frame:int=2 if active else int([0,1,3,1][int(elapsed*3.0+index)%4])
	var cell:=Vector2(MARKER_SHEET.get_width()/4.0,MARKER_SHEET.get_height());var bob:=roundf(sin(elapsed*3.0+index))*3.0
	draw_texture_rect_region(MARKER_SHEET,Rect2(point+Vector2(-22,-66+bob),Vector2(44,58)),Rect2(Vector2(frame,0)*cell,cell))

func _draw_note_marker(point:Vector2)->void:
	var pulse:=1.0+sin(elapsed*4.0)*0.08
	draw_set_transform(point+Vector2(0,-28),0,Vector2(pulse,pulse));draw_rect(Rect2(-17,-13,34,26),Color("#17232a"));draw_rect(Rect2(-13,-10,26,20),Color("#ead69a"));draw_line(Vector2(-8,-4),Vector2(8,-4),Color("#725b42"),2);draw_line(Vector2(-8,2),Vector2(5,2),Color("#725b42"),2);draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_oval(center:Vector2,radius:Vector2,color:Color)->void:
	var pts:=PackedVector2Array()
	for i in 24:pts.append(center+Vector2(cos(i*TAU/24.0)*radius.x,sin(i*TAU/24.0)*radius.y))
	draw_colored_polygon(pts,color)
