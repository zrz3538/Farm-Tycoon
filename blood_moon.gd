extends Node2D

const PARASITE_HUMAN := preload("res://assets/enemies/parasite_skeletons/parasite_human.png")

var game: Node
var elapsed := 0.0
var boss_position := Vector2(1040, 190)
var boss_hp := 0
var boss_max_hp := 1800
var bombs: Array[Dictionary] = []
var bomb_timer := 1.0
var hit_flash := 0.0
var attack_time := 0.0

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
	attack_time=maxf(0.0,attack_time-delta)
	ensure_started()
	bomb_timer -= delta
	if bomb_timer <= 0.0:
		bomb_timer = randf_range(1.25, 2.0)
		attack_time=0.5
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
				game.take_damage(46.0,"被血月骷髅炸倒了")
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
	# The blood-moon boss uses the same cartoon parasite skeleton language as
	# the campaign creatures, enlarged into a towering red-tinted guardian.
	var p := boss_position
	var tint := Color.WHITE if hit_flash > 0 else Color("#ffb0af")
	var bob:=roundf(sin(elapsed*2.3)*3.0)
	var attack_progress:=1.0-attack_time/0.5 if attack_time>0.0 else 0.0
	var lean:=-0.22*sin(attack_progress*PI) if attack_time>0.0 else sin(elapsed*2.3)*0.025
	draw_set_transform(p+Vector2(sin(attack_progress*PI)*18.0,0),lean,Vector2(1.0+sin(attack_progress*PI)*0.12,1.0-sin(attack_progress*PI)*0.06))
	draw_texture_rect(PARASITE_HUMAN,Rect2(-86,-118+bob,172,258),false,tint)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if attack_time>0.0:draw_arc(p+Vector2(-50,-10),48,-2.2,0.2,13,Color("#ffdc91"),6)
	# Boss health bar.
	draw_rect(Rect2(820,74,400,24),Color("#27131a"))
	draw_rect(Rect2(826,80,388.0*float(boss_hp)/boss_max_hp,12),Color("#d23848"))
	for bomb in bombs:
		var bp: Vector2 = bomb.pos
		draw_circle(Vector2(bomb.target),88,Color("#ff3344",0.10))
		draw_arc(Vector2(bomb.target),88,0,TAU,32,Color("#ff6a52",0.75),3)
		draw_circle(bp,18,Color("#d9cfad")); draw_rect(Rect2(bp+Vector2(-12,6),Vector2(24,13)),Color("#d9cfad"))
		draw_rect(Rect2(bp+Vector2(-9,-4),Vector2(6,7)),Color("#5b1525")); draw_rect(Rect2(bp+Vector2(4,-4),Vector2(6,7)),Color("#5b1525"))
