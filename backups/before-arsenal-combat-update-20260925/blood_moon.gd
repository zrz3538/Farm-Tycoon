extends Node2D

var game: Node
var elapsed := 0.0
var boss_position := Vector2(1040, 190)
var boss_hp := 0
var boss_max_hp := 1800
var bombs: Array[Dictionary] = []
var bomb_timer := 1.0
var hit_flash := 0.0

func _ready() -> void:
	game = get_parent()
	z_index = 4
	queue_redraw()

func is_active() -> bool:
	return is_instance_valid(game) and game.playing and game.day_count >= 6 and not game.blood_moon_defeated

func ensure_started() -> void:
	if boss_hp <= 0 and not (is_instance_valid(game) and game.blood_moon_defeated):
		boss_hp=boss_max_hp

func _process(delta: float) -> void:
	visible = is_active() and game.scene_id == 0
	if not visible or game.suspended:
		return
	elapsed += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	ensure_started()
	bomb_timer -= delta
	if bomb_timer <= 0.0:
		bomb_timer = randf_range(1.25, 2.0)
		var target: Vector2 = game.player.position + Vector2(randf_range(-55,55),randf_range(-35,35))
		bombs.append({"pos":boss_position+Vector2(-35,30),"target":target,"time":0.9})
	for i in range(bombs.size()-1,-1,-1):
		var bomb: Dictionary = bombs[i]
		bomb.time = float(bomb.time)-delta
		bomb.pos = Vector2(bomb.pos).lerp(Vector2(bomb.target),minf(1.0,delta*3.5))
		bombs[i] = bomb
		if float(bomb.time) <= 0.0:
			var blast: Vector2 = bomb.target
			bombs.remove_at(i)
			game.combat_blast(blast,88.0)
			if game.player.position.distance_to(blast) < 88.0:
				game.combat_defeat("被血月骷髅炸倒了")
				return
	queue_redraw()

func shoot_at(point: Vector2, damage: int) -> Dictionary:
	if not visible or point.distance_to(boss_position) > 100.0:
		return {}
	ensure_started()
	boss_hp = maxi(0,boss_hp-damage)
	hit_flash = 0.12
	var killed := boss_hp <= 0
	if killed:
		bombs.clear()
		game.complete_blood_moon()
	queue_redraw()
	return {"hit":true,"killed":killed,"position":boss_position,"reward":30000 if killed else 0,"damage":damage}

func _draw() -> void:
	if not visible: return
	draw_rect(Rect2(0,54,1280,666),Color("#6d101d",0.32))
	# Huge cracked skull with parasite roots.
	var p := boss_position
	var bone := Color("#ead9b8") if hit_flash <= 0 else Color.WHITE
	draw_circle(p,74,bone)
	draw_rect(Rect2(p+Vector2(-55,35),Vector2(110,65)),bone)
	draw_rect(Rect2(p+Vector2(-63,-7),Vector2(126,53)),bone)
	for x in [-35,27]:
		draw_rect(Rect2(p+Vector2(x,-15),Vector2(26,31)),Color("#260d18"))
		draw_circle(p+Vector2(x+13,0),7,Color("#d92d43"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-12,18),p+Vector2(0,2),p+Vector2(13,18)]),Color("#392019"))
	for x in range(-45,50,18): draw_rect(Rect2(p+Vector2(x,58),Vector2(11,31)),Color("#38241f"))
	for i in 7:
		var root := p+Vector2(-75+i*24,45)
		var tip := root+Vector2(sin(elapsed*1.7+i)*35,95+i%2*28)
		draw_line(root,tip,Color("#56152c"),9)
		draw_circle(tip,6,Color("#bd2847"))
	# Boss health bar.
	draw_rect(Rect2(820,74,400,24),Color("#27131a"))
	draw_rect(Rect2(826,80,388.0*float(boss_hp)/boss_max_hp,12),Color("#d23848"))
	for bomb in bombs:
		var bp: Vector2 = bomb.pos
		draw_circle(Vector2(bomb.target),88,Color("#ff3344",0.10))
		draw_arc(Vector2(bomb.target),88,0,TAU,32,Color("#ff6a52",0.75),3)
		draw_circle(bp,18,Color("#d9cfad")); draw_rect(Rect2(bp+Vector2(-12,6),Vector2(24,13)),Color("#d9cfad"))
		draw_rect(Rect2(bp+Vector2(-9,-4),Vector2(6,7)),Color("#5b1525")); draw_rect(Rect2(bp+Vector2(4,-4),Vector2(6,7)),Color("#5b1525"))
