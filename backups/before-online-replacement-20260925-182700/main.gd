extends Node2D

const SAVE_PATH := "user://farm_tycoon_save.json"
const BUY_PRICE := 50
const MILK_VALUE := 3
const SLOT_COUNT := 12
const LOTTERY_PRICE := 150000
const PRESTIGE_COST := 100000000
const ECONOMY_VERSION := 2
const COW_NAMES := ["喵喵牛", "鲨鱼牛", "霸王龙牛", "雷霆牛", "熔岩牛", "机甲牛", "星空龙牛", "混沌牛魔王", "云朵牛", "幽灵牛", "彩虹牛", "宇宙帝王牛", "霜冻猛犸牛", "海盗船长牛", "赛博忍者牛", "凤凰牛", "时间领主牛", "虚空吞噬牛", "创世神牛", "火箭牛", "深海巨鲸牛", "法老牛", "武圣牛", "暗夜蝙蝠牛", "黄金圣甲牛", "量子牛", "银河列车牛", "黑洞牛", "终焉龙神牛"]
const COW_MILK := [2, 4, 7, 12, 20, 34, 56, 90, 145, 230, 365, 580, 920, 1450, 2300, 3600, 5600, 8700, 13500, 21000, 32500, 50000, 77000, 118000, 180000, 275000, 420000, 640000, 980000]
const TRAIT_TEMPLATES := [
	{"kind":"milk", "name":"高产", "min":0.04, "max":0.18},
	{"kind":"sale", "name":"优质奶", "min":0.03, "max":0.15},
	{"kind":"capacity", "name":"节食", "min":0.05, "max":0.22},
	{"kind":"upgrade", "name":"工程直觉", "min":0.04, "max":0.16},
	{"kind":"lottery", "name":"幸运星", "min":0.03, "max":0.12},
	{"kind":"task", "name":"勤劳", "min":0.05, "max":0.20},
	{"kind":"recycle", "name":"珍稀血统", "min":0.08, "max":0.28},
	{"kind":"prestige", "name":"轮回印记", "min":1.0, "max":1.0}
]
const LOTTERY_TIERS := [
	{"name":"普通牛仔彩票", "price":5000, "min":1, "max":7, "ratio":0.56},
	{"name":"黄金牛仔彩票", "price":180000, "min":4, "max":15, "ratio":0.58},
	{"name":"传奇牛仔彩票", "price":6000000, "min":9, "max":28, "ratio":0.62}
]
const COW_ATLAS := preload("res://assets/cows.svg")
const CowSlot := preload("res://cow_slot.gd")
const FarmWorld := preload("res://farm_world.gd")
const CornWorld := preload("res://corn_world.gd")
const HouseWorld := preload("res://house_world.gd")
const BloodMoon := preload("res://blood_moon.gd")
const CampaignWorld := preload("res://campaign_world.gd")
const Cowboy := preload("res://player.gd")
const SoundManager := preload("res://sound_manager.gd")
const TaskSystem := preload("res://task_system.gd")
const WeaponBar := preload("res://weapon_bar.gd")
const WeaponIcon := preload("res://weapon_icon.gd")
const WEAPONS := {
	"shotgun":{"name":"双管猎枪","damage":92,"cooldown":0.72,"price":0,"mag":2,"reload":1.15,"modes":["semi"]},
	"m4a1":{"name":"M4A1","damage":34,"cooldown":0.105,"price":25000,"mag":30,"reload":1.25,"modes":["auto","burst","semi"]},
	"ar15":{"name":"AR-15","damage":55,"cooldown":0.17,"price":85000,"mag":20,"reload":1.35,"modes":["auto","burst","semi"]},
	"m700":{"name":"Remington M700","damage":275,"cooldown":0.95,"price":240000,"mag":5,"reload":1.7,"modes":["semi"]},
	"ak47":{"name":"AK-47","damage":48,"cooldown":0.12,"price":130000,"mag":30,"reload":1.45,"modes":["auto","semi"]},
	"mp5":{"name":"H&K MP5","damage":25,"cooldown":0.075,"price":95000,"mag":30,"reload":1.1,"modes":["auto","burst","semi"]},
	"scarh":{"name":"FN SCAR-H","damage":72,"cooldown":0.16,"price":310000,"mag":20,"reload":1.5,"modes":["auto","semi"]},
	"deagle":{"name":"Desert Eagle","damage":120,"cooldown":0.42,"price":180000,"mag":7,"reload":1.25,"modes":["semi"]},
	"m249":{"name":"M249 SAW","damage":39,"cooldown":0.082,"price":520000,"mag":100,"reload":2.4,"modes":["auto"]}
}
const WEAPON_ORDER := ["shotgun","m4a1","ar15","m700","ak47","mp5","scarh","deagle","m249"]

var coins := 500
var cows: Array[int] = []
var cow_traits: Array[Dictionary] = []
var cow_states: Array[String] = []
var tank_level := 1
var stored_milk := 0
var carried_milk := 0
var player: CharacterBody2D
var slots: Array = []
var coin_label: Label
var milk_label: Label
var carry_label: Label
var tank_label: Label
var message_label: Label
var prompt_label: Label
var farm_title: Label
var menu: Control
var menu_column: VBoxContainer
var menu_status: Label
var effects_layer: CanvasLayer
var farm_name := "我的牧场"
var active_slot := 0
var playing := false
var suspended := false
var name_input: LineEdit
var notice_time := 0.0
var save_root := "user://"
var shotgun_equipped := false
var shooting := false
var sounds: Node
var task_system: Node
var prestige_count := 0
var prestige_medals := 0
var medal_label: Label
var scene_id := 0
var farm_world: Node2D
var corn_world: Node2D
var house_world: Node2D
var day_count := 1
var time_of_day := 8.0
var day_label: Label
var night_overlay: ColorRect
var parasite_purchase_count := 0
var parasite_purchase_target := 4
var night_warning_shown := false
var milk_contaminated := false
var carried_contaminated := false
var market_closed_day := -1
var game_over := false
var weapon_id := "shotgun"
var owned_weapons := {"shotgun":true,"m4a1":false,"ar15":false,"m700":false,"ak47":false,"mp5":false,"scarh":false,"deagle":false,"m249":false}
var weapon_ammo: Dictionary = {}
var weapon_modes: Dictionary = {}
var last_shot_msec := -10000
var trigger_held := false
var burst_remaining := 0
var reload_remaining := 0.0
var reloading := false
var aim_position := Vector2.ZERO
var blood_moon_defeated := false
var blood_moon_announced := false
var campaign_progress := 0
var dynamite_owned := false
var parasite_heart_destroyed := false
var first_skeleton_encounter_completed := false
var day4_wave_spawned := false
var parasite_ever_discovered := false
var free_mode := false
var health := 100.0
var max_health := 100.0
var last_damage_time := -10.0
var runtime_seconds := 0.0
var health_label: Label
var story_label: Label
var damage_overlay: ColorRect
var weapon_bar: Control
var tab_held := false
var tab_hold_time := 0.0
var tester_opened_this_hold := false
var blood_moon: Node2D
var campaign_worlds: Array[Node2D] = []

func _ready() -> void:
	_reset_weapon_state()
	sounds = SoundManager.new()
	add_child(sounds)
	task_system = TaskSystem.new()
	add_child(task_system)
	farm_world = FarmWorld.new()
	farm_world.name = "FarmWorld"
	add_child(farm_world)
	corn_world = CornWorld.new()
	corn_world.name = "CornWorld"
	add_child(corn_world)
	house_world = HouseWorld.new()
	house_world.name = "HouseWorld"
	add_child(house_world)
	blood_moon = BloodMoon.new()
	blood_moon.name = "BloodMoon"
	add_child(blood_moon)
	for stage in 6:
		var world := CampaignWorld.new()
		world.setup(stage)
		add_child(world)
		campaign_worlds.append(world)
	_build_cow_field()
	player = Cowboy.new()
	player.position = Vector2(650, 430)
	player.z_index = 5
	player.set_physics_process(false)
	add_child(player)
	_build_hud()
	cows.resize(SLOT_COUNT)
	cows.fill(-1)
	cow_traits.resize(SLOT_COUNT)
	cow_states.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		cow_traits[i] = {}
		cow_states[i] = "empty"
	_switch_scene(0, Vector2(650, 430))
	_refresh_all()
	_build_menu()
	_show_start()
	var production := Timer.new()
	production.wait_time = 1.0
	production.autostart = true
	production.timeout.connect(_produce_milk)
	add_child(production)
	var autosave := Timer.new()
	autosave.wait_time = 5.0
	autosave.autostart = true
	autosave.timeout.connect(_save_game)
	add_child(autosave)

func _build_cow_field() -> void:
	for i in SLOT_COUNT:
		var slot = CowSlot.new()
		slot.setup(i, COW_ATLAS, self)
		slot.position = Vector2(48 + (i % 4) * 184, 66 + floori(i / 4.0) * 102)
		slot.z_index = 2
		slot.cow_dropped.connect(_on_cow_dropped)
		add_child(slot)
		slots.append(slot)

func _build_hud() -> void:
	var night_layer := CanvasLayer.new()
	night_layer.layer = 9
	add_child(night_layer)
	night_overlay = ColorRect.new()
	night_overlay.color = Color(0.035, 0.055, 0.14, 0.0)
	night_overlay.position = Vector2.ZERO
	night_overlay.size = Vector2(1280,720)
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_layer.add_child(night_overlay)
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	effects_layer = CanvasLayer.new()
	effects_layer.layer = 20
	add_child(effects_layer)
	var top := ColorRect.new()
	top.color = Color("#243b2a", 0.94)
	top.position = Vector2.ZERO
	top.size = Vector2(1280, 54)
	canvas.add_child(top)
	var title := Label.new()
	farm_title = title
	title.text = "农场大亨"
	title.position = Vector2(22, 10)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_font_size_override("font_size", 20)
	title.size.x = 202
	title.clip_text = true
	title.add_theme_color_override("font_color", Color("#fff0b5"))
	top.add_child(title)
	coin_label = _hud_label(top, Vector2(240, 15), Color("#ffd45d"))
	milk_label = _hud_label(top, Vector2(440, 15), Color("#e8fbff"))
	carry_label = _hud_label(top, Vector2(690, 15), Color("#ffffff"))
	tank_label = _hud_label(top, Vector2(870, 15), Color("#bfe7ef"))
	day_label = _hud_label(top, Vector2(990, 15), Color("#fff0b5"))
	medal_label = _hud_label(top, Vector2(1180, 15), Color("#ffe38b"))
	health_label = _hud_label(top,Vector2(1170,15),Color("#ff9b93"))
	health_label.add_theme_font_size_override("font_size",16)
	medal_label.position.x=1220
	weapon_bar=WeaponBar.new()
	weapon_bar.game=self
	weapon_bar.position=Vector2(12,62)
	weapon_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(weapon_bar)
	story_label = Label.new()
	story_label.position = Vector2(270, 62)
	story_label.size = Vector2(740, 38)
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_label.add_theme_font_size_override("font_size", 16)
	story_label.add_theme_color_override("font_color", Color("#fff1bd"))
	story_label.add_theme_stylebox_override("normal", _box(Color("#17231e", 0.88), Color("#8e7a4c"), 3, 1))
	story_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(story_label)
	damage_overlay=ColorRect.new()
	damage_overlay.position=Vector2.ZERO
	damage_overlay.size=Vector2(1280,720)
	damage_overlay.color=Color(0.65,0.0,0.05,0.0)
	damage_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	effects_layer.add_child(damage_overlay)

	message_label = Label.new()
	message_label.position = Vector2(350, 661)
	message_label.size = Vector2(580, 42)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("#fff7cf"))
	message_label.add_theme_stylebox_override("normal", _box(Color("#263a2b", 0.9), Color("#d5bd70"), 4, 2))
	message_label.text = ""
	message_label.hide()
	canvas.add_child(message_label)

func _hud_label(parent: Node, pos: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _box(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _process(delta: float) -> void:
	runtime_seconds += delta
	if notice_time > 0:
		notice_time -= delta
		message_label.visible = notice_time > 0
	if playing and tab_held and not tester_opened_this_hold:
		tab_hold_time += delta
		if tab_hold_time >= 2.0:
			tester_opened_this_hold=true
			_show_tester_panel()
	if playing and not suspended:
		if reloading:
			reload_remaining-=delta
			if reload_remaining<=0.0: _finish_reload()
		if health<max_health and runtime_seconds-last_damage_time>1.6:
			health=minf(max_health,health+28.0*delta)
			_refresh_health()
		if health<35.0:
			damage_overlay.color.a=0.12+(1.0-health/max_health)*0.20+sin(runtime_seconds*7.0)*0.035
		if shotgun_equipped and not reloading:
			var mode := str(weapon_modes.get(weapon_id,"semi"))
			if (mode=="auto" and trigger_held) or burst_remaining>0:
				if _fire_weapon(aim_position) and burst_remaining>0: burst_remaining-=1
		time_of_day = minf(24.0, time_of_day + delta * 0.10)
		var darkness := clampf((time_of_day - 17.5) / 5.5, 0.0, 1.0) * 0.58
		night_overlay.color.a = darkness
		day_label.text = "DAY %d  %s" % [day_count, _format_time()]
		if time_of_day >= 20.0 and not night_warning_shown:
			night_warning_shown = true
			show_message("天黑了，回到玉米地的家中上床睡觉")
		if scene_id == 0 and player.position.x >= 1254:
			_switch_scene(1, Vector2(30, 480))
		elif scene_id == 1 and player.position.x <= 26:
			_switch_scene(0, Vector2(1248, 455))
		if day_count >= 6 and not blood_moon_defeated and not blood_moon_announced:
			blood_moon_announced = true
			show_message("血月升起：牧场出现了会投掷骷髅头炸弹的巨大骷髅！")
			_celebrate("血月降临",Color("#ff5262"),Vector2(390,190))

func _format_time() -> String:
	var hour := floori(time_of_day)
	var minute := floori((time_of_day - hour) * 60.0)
	return "%02d:%02d" % [hour, minute]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		trigger_held=false
	if event is InputEventKey and event.keycode==KEY_TAB:
		tab_held=event.pressed
		if not event.pressed:
			tab_hold_time=0.0; tester_opened_this_hold=false
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and playing:
			if suspended:
				_resume()
			else:
				_show_pause()
			get_viewport().set_input_as_handled()
			return
		if not playing or suspended:
			return
		if event.keycode == KEY_X:
			_toggle_shotgun()
		elif event.keycode == KEY_R:
			_start_reload()
		elif event.keycode == KEY_B:
			_cycle_fire_mode()
		elif event.keycode == KEY_E:
			_try_interact(true)
		elif event.keycode == KEY_F:
			_try_interact(false)
	elif event is InputEventMouseButton and playing and not suspended:
		if event.button_index == MOUSE_BUTTON_LEFT:
			aim_position=event.position
			trigger_held=event.pressed
			if event.pressed and shotgun_equipped:
				var mode := str(weapon_modes.get(weapon_id,"semi"))
				if mode=="burst": burst_remaining=3
				elif mode=="semi": _fire_weapon(event.position)
	elif event is InputEventMouseMotion:
		aim_position=event.position

func _try_interact(allow_barn: bool) -> void:
	trigger_held=false; burst_remaining=0
	if scene_id == 1:
		if _near(CornWorld.CAMPAIGN_POINT) and parasite_ever_discovered and not free_mode:
			if not blood_moon_defeated:
				show_message("墓井被血月封印，先击败牧场里的巨大骷髅")
			else:
				_switch_scene(3,CampaignWorld.ENTRY_POINT+Vector2(80,0))
				show_message(CampaignWorld.STAGE_STORIES[0])
		elif _near(CornWorld.HOUSE_POINT):
			_switch_scene(2, Vector2(640, 620))
		else:
			show_message("靠近房门才能进入")
		return
	if scene_id >= 3:
		var stage := scene_id-3
		var world: Node2D = campaign_worlds[stage]
		if _near(CampaignWorld.ENTRY_POINT):
			if stage == 0:
				show_message("身后的墓穴洞口已经坍塌，只能继续向深处走")
			else:
				_switch_scene(scene_id-1,CampaignWorld.EXIT_POINT+Vector2(-85,70))
		elif stage == 5 and _near(CampaignWorld.HEART_POINT):
			_try_destroy_heart(world)
		elif _near(CampaignWorld.EXIT_POINT):
			if not world.can_exit():
				show_message("出口被寄生骨骸封住，清除这个区域的怪物")
			elif stage < 5:
				if stage == 4:
					_celebrate("矿车启动！",Color("#ffd477"),Vector2(390,220))
				_switch_scene(scene_id+1,CampaignWorld.ENTRY_POINT+Vector2(80,0))
				show_message(CampaignWorld.STAGE_STORIES[stage+1])
		return
	if scene_id == 2:
		if _near(HouseWorld.ARMORY_POINT):
			_show_armory()
		elif _near(HouseWorld.BED_POINT):
			_sleep_until_morning()
		elif _near(HouseWorld.EXIT_POINT):
			if time_of_day >= 24.0:
				show_message("已经深夜，必须先上床睡觉")
			else:
				_switch_scene(1, CornWorld.HOUSE_POINT + Vector2(0, 80))
		else:
			show_message("靠近房门才能离开")
		return
	if _near(FarmWorld.TRUCK_POINT):
		_buy_cow()
	elif _near(FarmWorld.LOTTERY_POINT):
		_show_lottery()
	elif _near(FarmWorld.TASK_POINT):
		_show_tasks()
	elif _near(FarmWorld.TANK_POINT):
		_take_milk()
	elif _near(FarmWorld.MARKET_POINT):
		_sell_milk()
	elif allow_barn and _near(FarmWorld.BARN_POINT):
		_upgrade_tank()
	elif not shotgun_equipped:
		show_message("请进入设施的交互范围")

func _near(point: Vector2, radius := 155.0) -> bool:
	return player.global_position.distance_to(point) <= radius

func _can_click_interact() -> bool:
	if scene_id == 1:
		return _near(CornWorld.HOUSE_POINT) or (_near(CornWorld.CAMPAIGN_POINT) and parasite_ever_discovered)
	if scene_id == 2:
		return _near(HouseWorld.BED_POINT) or _near(HouseWorld.EXIT_POINT) or _near(HouseWorld.ARMORY_POINT)
	if scene_id >= 3:
		return _near(CampaignWorld.ENTRY_POINT) or _near(CampaignWorld.EXIT_POINT) or (scene_id==8 and _near(CampaignWorld.HEART_POINT))
	return false

func _mouse_over_cow_slot(point: Vector2) -> bool:
	if scene_id != 0:
		return false
	for slot in slots:
		if slot.get_global_rect().has_point(point):
			return true
	return false

func can_manage_cows() -> bool:
	return playing and not suspended and scene_id == 0

func _buy_cow() -> void:
	if not playing or suspended or not _near(FarmWorld.TRUCK_POINT):
		return
	var empty := cows.find(-1)
	if empty == -1:
		show_message("牧场已满")
		return
	if coins < BUY_PRICE:
		show_message("金币不足，先去市场卖牛奶")
		return
	coins -= BUY_PRICE
	cows[empty] = 0
	cow_states[empty] = _next_cat_cow_state()
	cow_traits[empty] = _roll_cow_trait(0) if cow_states[empty] == "normal" else {}
	_advance_task("buy")
	sounds.play_sfx("cash")
	if cow_states[empty] == "parasite":
		if not parasite_ever_discovered:
			parasite_ever_discovered=true
			_unlock_splash("发现隐藏矿道","玉米地南侧的地面塌陷，露出祖父封死的旧矿道")
		sounds.play_sfx("poof")
		show_message("卡车里混进了一只不产奶的寄生虫牛……")
		_celebrate("发现寄生虫牛", Color("#c97778"), Vector2(390,245))
	else:
		show_message("购买成功：喵喵牛来到牧场")
	_save_game()
	_refresh_all()

func _on_cow_dropped(from_index: int, to_index: int) -> void:
	if not can_manage_cows() or from_index == to_index or cows[from_index] < 0 or cow_states[from_index] != "normal":
		return
	if cows[to_index] == -1:
		cows[to_index] = cows[from_index]
		cow_traits[to_index] = cow_traits[from_index].duplicate(true)
		cow_states[to_index] = cow_states[from_index]
		cows[from_index] = -1
		cow_traits[from_index] = {}
		cow_states[from_index] = "empty"
		sounds.play_sfx("swap")
		show_message("奶牛已移动到新草地")
	elif cow_states[to_index] == "normal" and cows[to_index] == cows[from_index]:
		var level := cows[to_index]
		if level >= COW_NAMES.size() - 1:
			show_message("终焉龙神牛已经是最高等级")
			return
		var first_trait: Dictionary = cow_traits[from_index]
		var second_trait: Dictionary = cow_traits[to_index]
		cows[from_index] = -1
		cow_traits[from_index] = {}
		cow_states[from_index] = "empty"
		cows[to_index] = level + 1
		cow_states[to_index] = "normal"
		cow_traits[to_index] = _merge_cow_trait(first_trait, second_trait, level + 1)
		_advance_task("merge")
		sounds.play_sfx("merge")
		show_message("合成成功：%s！" % COW_NAMES[level + 1])
		slots[to_index].play_merge_animation()
		_celebrate("合成成功！  %s" % COW_NAMES[level + 1], Color("#ffe080"), Vector2(390, 245))
	else:
		var held := cows[from_index]
		var held_trait: Dictionary = cow_traits[from_index]
		var held_state: String = cow_states[from_index]
		cows[from_index] = cows[to_index]
		cow_traits[from_index] = cow_traits[to_index]
		cow_states[from_index] = cow_states[to_index]
		cows[to_index] = held
		cow_traits[to_index] = held_trait
		cow_states[to_index] = held_state
		sounds.play_sfx("swap")
		show_message("两只奶牛交换了位置")
	_save_game()
	_refresh_all()

func _produce_milk() -> void:
	if not playing or suspended:
		return
	var amount := _milk_per_second()
	if amount > 0 and stored_milk < _tank_capacity():
		var before := stored_milk
		stored_milk = mini(_tank_capacity(), stored_milk + amount)
		if _parasite_count() + _skeleton_count() > 0:
			milk_contaminated = true
		_advance_task("produce", stored_milk - before)
	_refresh_hud()

func _take_milk() -> void:
	if stored_milk <= 0:
		show_message("奶罐是空的，等奶牛产奶吧")
		return
	carried_milk += stored_milk
	carried_contaminated = carried_contaminated or milk_contaminated
	stored_milk = 0
	milk_contaminated = false
	sounds.play_sfx("milk")
	player.carrying = carried_milk
	show_message("已提取全部牛奶，去右侧市场出售")
	_refresh_hud()
	_save_game()

func _sell_milk() -> void:
	if _market_is_closed():
		show_message("关门了")
		return
	if carried_milk <= 0:
		show_message("你没有携带牛奶，先去奶罐取奶")
		return
	var sold := carried_milk
	var earned := roundi(sold * MILK_VALUE * (1.0 + _cow_bonus("sale")))
	coins += earned
	_advance_task("sell", sold)
	sounds.play_sfx("sell")
	show_message("售出 %d 份牛奶，获得 %d 金币" % [carried_milk, earned])
	_celebrate("+%d 金币" % earned, Color("#ffd45d"), Vector2(835, 260))
	carried_milk = 0
	if carried_contaminated:
		market_closed_day = day_count + 1
	carried_contaminated = false
	player.carrying = 0
	_refresh_hud()
	_save_game()

func _market_is_closed() -> bool:
	return day_count == market_closed_day

func _upgrade_tank() -> void:
	var price := _tank_upgrade_cost()
	if coins < price:
		show_message("升级需要 %d 金币" % price)
		return
	coins -= price
	tank_level += 1
	_advance_task("upgrade")
	sounds.play_sfx("cash")
	sounds.play_sfx("upgrade")
	show_message("奶罐升到 %d 级，容量提升至 %d" % [tank_level, _tank_capacity()])
	_celebrate("奶罐升级！  Lv.%d" % tank_level, Color("#9fe9ff"), Vector2(390, 245))
	_refresh_hud()
	_save_game()

func _show_lottery() -> void:
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_clear_menu("牛仔彩票")
	menu_status.text = "三档彩票奖池不同。越高档越可能抽到稀有牛，但顶级牛仍非常罕见。"
	for i in LOTTERY_TIERS.size():
		var tier: Dictionary = LOTTERY_TIERS[i]
		var price := _lottery_price(int(tier.price))
		_menu_button("%s · %d 金币\n奖池：%s — %s" % [tier.name, price, COW_NAMES[int(tier.min)], COW_NAMES[int(tier.max)]], _play_lottery.bind(i))
	_menu_button("离开彩票店", _resume)

func _play_lottery(tier_index := 0) -> void:
	var empty := cows.find(-1)
	if empty == -1:
		show_message("牧场没有空位")
		return
	var tier: Dictionary = LOTTERY_TIERS[clampi(tier_index, 0, LOTTERY_TIERS.size() - 1)]
	var price := _lottery_price(int(tier.price))
	if coins < price:
		show_message("这档彩票需要 %d 金币" % price)
		return
	coins -= price
	var level := _roll_lottery_level(tier_index)
	cows[empty] = level
	cow_states[empty] = "normal"
	cow_traits[empty] = _roll_cow_trait(level, 0.08 + tier_index * 0.08)
	_advance_task("lottery")
	sounds.play_sfx("cash")
	sounds.play_sfx("lottery")
	_refresh_all()
	_save_game()
	_celebrate("抽中 %s！" % COW_NAMES[level], Color("#f0a8ff"), Vector2(390, 245))
	_show_lottery()

func _reset_weapon_state() -> void:
	weapon_ammo.clear(); weapon_modes.clear()
	for id in WEAPON_ORDER:
		weapon_ammo[id]=int(WEAPONS[id].mag)
		weapon_modes[id]=str(WEAPONS[id].modes[0])

func _show_armory() -> void:
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_clear_menu("地下武器库")
	menu_status.text = "这里是唯一可以更换武器的地方。购买或点击已拥有的枪械进行装备；R 换弹，B 切换射击模式。"
	var grid:=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	menu_column.add_child(grid)
	for id in WEAPON_ORDER:
		var weapon: Dictionary = WEAPONS[id]
		var button:=Button.new()
		button.custom_minimum_size=Vector2(155,112)
		button.add_theme_font_size_override("font_size",13)
		button.add_theme_color_override("font_color",Color("#fff0cb"))
		button.add_theme_stylebox_override("normal",_box(Color("#465b4c"),Color("#293c33"),0,2))
		var caption := "\n\n%s\n伤害 %d" % [weapon.name,weapon.damage]
		if bool(owned_weapons.get(id,false)):
			caption += "  · 已装备" if weapon_id==id else "  · 选择"
			button.pressed.connect(_select_weapon.bind(id))
		else:
			caption += "\n%d 金币" % int(weapon.price)
			button.pressed.connect(_buy_weapon.bind(id))
		button.text=caption
		var icon:=WeaponIcon.new(); icon.weapon_id=id; icon.position=Vector2(14,2); icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(icon); grid.add_child(button)
	_menu_button("离开武器库",_resume)

func _buy_weapon(id: String) -> void:
	var price := int(WEAPONS[id].price)
	if coins < price:
		show_message("购买 %s 需要 %d 金币" % [WEAPONS[id].name,price])
		return
	coins -= price
	owned_weapons[id] = true
	weapon_id = id
	shotgun_equipped = true
	player.set_weapon(id)
	sounds.play_sfx("cash")
	_celebrate("获得 %s！" % WEAPONS[id].name,Color("#ffe39a"),Vector2(390,205))
	_refresh_hud(); _save_game(); _show_armory()

func _select_weapon(id: String) -> void:
	if not bool(owned_weapons.get(id,false)): return
	weapon_id=id
	shotgun_equipped=true
	player.set_weapon(id)
	sounds.play_sfx("equip")
	show_message("已装备 %s" % WEAPONS[id].name)
	_save_game(); _show_armory()

func _select_weapon_slot(index: int) -> void:
	if index<0 or index>=WEAPON_ORDER.size(): return
	var id: String=WEAPON_ORDER[index]
	if not bool(owned_weapons.get(id,false)):
		show_message("该栏位的武器尚未购买")
		return
	_equip_weapon(id)

func _cycle_weapon(direction: int) -> void:
	var owned: Array[String]=[]
	for id in WEAPON_ORDER:
		if bool(owned_weapons.get(id,false)): owned.append(id)
	if owned.is_empty(): return
	var current:=owned.find(weapon_id)
	current=(current+direction+owned.size())%owned.size()
	_equip_weapon(owned[current])

func _equip_weapon(id: String) -> void:
	weapon_id=id; shotgun_equipped=true; trigger_held=false; burst_remaining=0; reloading=false
	player.set_weapon(id); sounds.play_sfx("equip")
	Input.set_custom_mouse_cursor(load("res://assets/crosshair.svg"),Input.CURSOR_ARROW,Vector2(16,16))
	show_message("切换至 %s · %s" % [WEAPONS[id].name,_mode_name(str(weapon_modes[id]))])
	weapon_bar.queue_redraw(); _save_game()

func _cycle_fire_mode() -> void:
	if not shotgun_equipped: return
	var modes: Array=WEAPONS[weapon_id].modes
	if modes.size()<=1:
		show_message("%s仅支持半自动射击" % WEAPONS[weapon_id].name)
		return
	var next:=(modes.find(str(weapon_modes[weapon_id]))+1)%modes.size()
	weapon_modes[weapon_id]=str(modes[next])
	trigger_held=false; burst_remaining=0
	show_message("%s：%s" % [WEAPONS[weapon_id].name,_mode_name(weapon_modes[weapon_id])])
	sounds.play_sfx("equip"); _save_game()

func _mode_name(mode: String) -> String:
	return {"auto":"全自动","burst":"三连发","semi":"半自动"}.get(mode,mode)

func _start_reload() -> void:
	if not shotgun_equipped or reloading: return
	if int(weapon_ammo[weapon_id])>=int(WEAPONS[weapon_id].mag):
		show_message("弹夹是满的")
		return
	reloading=true; trigger_held=false; burst_remaining=0
	reload_remaining=float(WEAPONS[weapon_id].reload)
	player.start_reload(reload_remaining)
	_eject_casing(true)
	sounds.play_sfx("equip")
	show_message("正在更换 %s 弹夹……" % WEAPONS[weapon_id].name)

func _finish_reload() -> void:
	reloading=false
	weapon_ammo[weapon_id]=int(WEAPONS[weapon_id].mag)
	player.finish_reload()
	sounds.play_sfx("reload")
	show_message("换弹完成")

func _toggle_shotgun() -> void:
	shotgun_equipped = not shotgun_equipped
	trigger_held=false; burst_remaining=0; reloading=false
	player.set_weapon(weapon_id if shotgun_equipped else "")
	sounds.play_sfx("equip")
	if shotgun_equipped:
		var cursor := load("res://assets/crosshair.svg")
		Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(16, 16))
		show_message("%s已取出" % WEAPONS[weapon_id].name)
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		show_message("猎枪已收回")
	weapon_bar.queue_redraw()

func _bullet_tracer(from: Vector2,to: Vector2) -> void:
	var direction:=(to-from).normalized()
	if direction.length_squared() < 0.001: return
	var distances: Array[float] = []
	if direction.x > 0.001: distances.append((1280.0-from.x)/direction.x)
	elif direction.x < -0.001: distances.append((0.0-from.x)/direction.x)
	if direction.y > 0.001: distances.append((720.0-from.y)/direction.y)
	elif direction.y < -0.001: distances.append((54.0-from.y)/direction.y)
	var ray_length := 1600.0
	for distance in distances:
		if distance > 0.0: ray_length = minf(ray_length,distance)
	var end:=from+direction*(ray_length+8.0)
	var line:=Line2D.new()
	line.points=PackedVector2Array([from,end])
	line.width=3.0 if weapon_id in ["m700","shotgun"] else 2.0
	line.default_color=Color("#fff4a1")
	effects_layer.add_child(line)
	var flash:=Polygon2D.new()
	flash.polygon=PackedVector2Array([from+direction*25+direction.orthogonal()*5,from+direction*46,from+direction*25-direction.orthogonal()*5])
	flash.color=Color("#ffca55")
	effects_layer.add_child(flash)
	var tween:=create_tween(); tween.set_parallel(true)
	tween.tween_property(line,"modulate:a",0.0,0.11)
	tween.tween_property(flash,"modulate:a",0.0,0.08)
	tween.chain().tween_callback(line.queue_free); tween.chain().tween_callback(flash.queue_free)

func _eject_casing(magazine: bool) -> void:
	var piece:=Label.new()
	piece.text="▮" if magazine else "▪"
	piece.position=player.position+Vector2(8,-18)
	piece.add_theme_font_size_override("font_size",22 if magazine else 13)
	piece.add_theme_color_override("font_color",Color("#41484a") if magazine else Color("#d7ad53"))
	effects_layer.add_child(piece)
	var target:=piece.position+Vector2(randf_range(-34,34),55 if magazine else 32)
	var tween:=create_tween(); tween.set_parallel(true)
	tween.tween_property(piece,"position",target,0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(piece,"rotation",randf_range(-3.0,3.0),0.48)
	tween.tween_property(piece,"modulate:a",0.0,0.32).set_delay(0.35)
	tween.chain().tween_callback(piece.queue_free)

func _try_shoot_cow(mouse_position: Vector2) -> void:
	_fire_weapon(mouse_position)

func _fire_weapon(mouse_position: Vector2) -> bool:
	if shooting:
		return false
	var weapon: Dictionary = WEAPONS[weapon_id]
	var now := Time.get_ticks_msec()
	if now-last_shot_msec < int(float(weapon.cooldown)*1000.0): return false
	if reloading: return false
	if int(weapon_ammo.get(weapon_id,0))<=0:
		burst_remaining=0; trigger_held=false
		show_message("弹夹打空了，按 R 换弹")
		sounds.play_sfx("equip")
		return false
	last_shot_msec = now
	weapon_ammo[weapon_id]=int(weapon_ammo[weapon_id])-1
	sounds.play_sfx("shot")
	player.fire_toward(mouse_position)
	_bullet_tracer(player.position+player.facing*34.0,mouse_position)
	_eject_casing(false)
	if scene_id == 0:
		var boss_hit: Dictionary = blood_moon.shoot_at(mouse_position,int(weapon.damage))
		if not boss_hit.is_empty():
			_handle_combat_hit(boss_hit); return true
		for i in slots.size():
			if cows[i] >= 0 and slots[i].get_global_rect().has_point(mouse_position):
				_delete_cow(i, mouse_position)
				return true
	elif scene_id == 1 and corn_world.shoot_at(mouse_position):
		_handle_combat_hit({"hit":true,"killed":true,"position":mouse_position,"reward":350,"damage":int(weapon.damage)})
		return true
	elif scene_id >= 3:
		var hit: Dictionary = campaign_worlds[scene_id-3].shoot_at(mouse_position,int(weapon.damage))
		if not hit.is_empty():
			_handle_combat_hit(hit); return true
	return true

func _switch_scene(next_scene: int, spawn: Vector2) -> void:
	if free_mode and next_scene >= 3:
		show_message("自由模式中墓穴已封闭")
		return
	var previous_scene := scene_id
	scene_id = clampi(next_scene, 0, 8)
	farm_world.visible = scene_id == 0
	corn_world.visible = scene_id == 1
	house_world.visible = scene_id == 2
	blood_moon.visible = scene_id == 0
	for i in campaign_worlds.size():
		campaign_worlds[i].visible = scene_id == i+3
	for slot in slots:
		slot.visible = scene_id == 0
	var all_worlds: Array = [farm_world, corn_world, house_world]
	all_worlds.append_array(campaign_worlds)
	for world in all_worlds:
		var active: bool = world.visible
		for child in world.get_children():
			if child is CollisionObject2D:
				child.collision_layer = 1 if active else 0
				child.collision_mask = 1 if active else 0
	player.position = spawn
	player.velocity = Vector2.ZERO
	if previous_scene == 2 and scene_id == 1 and day_count == 4 and _skeleton_count() > 0 and not day4_wave_spawned and not first_skeleton_encounter_completed:
		day4_wave_spawned=true
		corn_world.spawn_attackers()
		_save_game()
	if scene_id >= 3:
		campaign_worlds[scene_id-3].activate()
	elif scene_id == 0 and day_count >= 6 and not blood_moon_defeated:
		blood_moon.ensure_started()
	if playing and previous_scene!=scene_id:
		var titles:=["牧场","玉米地与住宅","牛仔之家","枯骨墓园","腐水沼泽","哭泣礼拜堂","断脊峡谷","孵化巢穴","祖父矿井"]
		var subtitles:=["守住你的牛群","矿道的风从玉米叶下吹来","武器库藏在右侧密室","墓穴入口在身后坍塌","别踏进会呼吸的水","丧钟一响，祷告者苏醒","骨骸升降机仍在运转","这里制造了所有怪物","祖父供奉的心脏就在前方"]
		_scene_splash(titles[scene_id],subtitles[scene_id])
	_refresh_story_hint()

func trigger_game_over() -> void:
	if game_over: return
	game_over = true
	playing = false
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	var save_file := ProjectSettings.globalize_path(_slot_path(active_slot))
	if FileAccess.file_exists(_slot_path(active_slot)):
		DirAccess.remove_absolute(save_file)
	_clear_menu("GAME OVER")
	menu_status.text = "寄生骷髅抓住了牛仔。当前存档已经删除。"
	var art := Control.new()
	art.custom_minimum_size = Vector2(460,210)
	art.set_script(preload("res://game_over_art.gd"))
	menu_column.add_child(art)
	_menu_button("返回标题", _show_start)

func combat_defeat(reason: String) -> void:
	if suspended or game_over: return
	var lost := mini(coins, maxi(250, roundi(coins*0.05)))
	coins -= lost
	stored_milk = maxi(0,stored_milk-roundi(stored_milk*0.15))
	carried_milk = 0
	carried_contaminated = false
	player.carrying = 0
	health=max_health
	_refresh_health()
	_switch_scene(2,HouseWorld.WAKE_POINT)
	time_of_day = 6.0
	night_overlay.color.a = 0.0
	_refresh_hud()
	_save_game()
	sounds.play_sfx("poof")
	_celebrate("从床上惊醒",Color("#d8e9ff"),Vector2(390,215))
	show_message("%s，损失 %d 金币和少量牛奶" % [reason,lost])

func take_damage(amount: float, reason: String) -> void:
	if suspended or game_over: return
	if runtime_seconds-last_damage_time<0.65: return
	health=maxf(0.0,health-amount)
	last_damage_time=runtime_seconds
	_refresh_health()
	damage_overlay.color.a=clampf(0.18+(1.0-health/max_health)*0.42,0.0,0.58)
	var tween:=create_tween()
	tween.tween_property(damage_overlay,"color:a",clampf((1.0-health/max_health)*0.24,0.0,0.28),0.45)
	_hit_effect(player.position,false,roundi(amount))
	if health<=0.0: combat_defeat(reason)

func _refresh_health() -> void:
	if is_instance_valid(health_label): health_label.text="生命 %d" % ceili(health)
	if is_instance_valid(damage_overlay) and runtime_seconds-last_damage_time>1.6:
		damage_overlay.color.a=clampf((1.0-health/max_health)*0.20,0.0,0.22)

func combat_blast(position: Vector2, radius: float) -> void:
	var ring := Label.new()
	ring.text = "✦"
	ring.position = position-Vector2(45,55)
	ring.size = Vector2(90,90)
	ring.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ring.add_theme_font_size_override("font_size",72)
	ring.add_theme_color_override("font_color",Color("#ff6b4a"))
	effects_layer.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring,"scale",Vector2(radius/38.0,radius/38.0),0.28)
	tween.tween_property(ring,"modulate:a",0.0,0.38)
	tween.chain().tween_callback(ring.queue_free)
	sounds.play_sfx("poof")

func _handle_combat_hit(hit: Dictionary) -> void:
	var at: Vector2 = hit.get("position",player.position)
	var killed := bool(hit.get("killed",false))
	var reward := int(hit.get("reward",0))
	_hit_effect(at,killed,int(hit.get("damage",0)))
	sounds.play_sfx("kill" if killed else "hit")
	if killed:
		coins += reward
		_celebrate("消灭！ +%d 金币" % reward,Color("#ffe477"),Vector2(390,205))
		_refresh_hud()
		_save_game()

func _hit_effect(position: Vector2, killed: bool, damage: int) -> void:
	var label := Label.new()
	label.text = "击破！" if killed else "命中 %d" % damage
	label.position = position-Vector2(65,70)
	label.size = Vector2(130,45)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",26 if killed else 20)
	label.add_theme_color_override("font_color",Color("#fff08b") if killed else Color("#ffffff"))
	label.add_theme_color_override("font_outline_color",Color("#6d2430"))
	label.add_theme_constant_override("outline_size",5)
	effects_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label,"position",label.position+Vector2(0,-55),0.5)
	tween.tween_property(label,"scale",Vector2(1.45,1.45),0.18)
	tween.tween_property(label,"modulate:a",0.0,0.55).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)
	var ring:=Line2D.new()
	var points:=PackedVector2Array()
	for i in 17: points.append(position+Vector2.from_angle(i*TAU/16.0)*(14 if not killed else 24))
	ring.points=points; ring.width=5.0; ring.default_color=Color("#fff4a6") if not killed else Color("#ffb13b")
	effects_layer.add_child(ring)
	var rt:=create_tween(); rt.set_parallel(true)
	rt.tween_property(ring,"scale",Vector2(3.2,3.2) if killed else Vector2(1.9,1.9),0.24)
	rt.tween_property(ring,"modulate:a",0.0,0.28)
	rt.chain().tween_callback(ring.queue_free)
	if killed:
		for i in 12:
			var shard:=Label.new(); shard.text=["✦","◆","★"][i%3]; shard.position=position-Vector2(10,10)
			shard.add_theme_font_size_override("font_size",18+i%3*5); shard.add_theme_color_override("font_color",Color.from_hsv(float(i)/12.0,0.55,1.0)); effects_layer.add_child(shard)
			var st:=create_tween(); st.set_parallel(true); st.tween_property(shard,"position",shard.position+Vector2.from_angle(i*TAU/12.0)*(75+i%2*40),0.42); st.tween_property(shard,"modulate:a",0.0,0.48).set_delay(0.16); st.chain().tween_callback(shard.queue_free)

func complete_blood_moon() -> void:
	if blood_moon_defeated: return
	blood_moon_defeated = true
	campaign_progress = maxi(campaign_progress,0)
	_celebrate("血月骷髅粉碎！",Color("#ffd477"),Vector2(390,165))
	_unlock_splash("枯骨墓园已解锁","玉米地下方的封印被血月骷髅一同击碎")
	show_message("玉米地南侧的墓井封印松动了，那里通往寄生虫巢穴")
	_save_game()

func complete_campaign_stage(index: int) -> void:
	campaign_progress = maxi(campaign_progress,index+1)
	if index == 4:
		dynamite_owned = true
	var bonus := 5000+index*3500
	coins += bonus
	_celebrate("区域净化！ +%d" % bonus,Color("#9ff7b1"),Vector2(390,170))
	if index<5: _unlock_splash("新区域解锁",CampaignWorld.STAGE_NAMES[index+1])
	show_message("出口已开启：%s" % ("获得炸药，乘矿车进入祖父矿井" if index==4 else CampaignWorld.ENTRY_NAMES[mini(index+1,5)]))
	_refresh_hud()
	_refresh_story_hint()
	_save_game()

func _try_destroy_heart(world: Node2D) -> void:
	if not world.can_exit():
		show_message("矿井守门怪物仍守着寄生虫之心")
		return
	if parasite_heart_destroyed:
		show_message("只剩一团焦黑的寄生虫残骸")
		return
	if not dynamite_owned:
		show_message("需要炸药才能摧毁寄生虫之心")
		return
	parasite_heart_destroyed = true
	combat_blast(CampaignWorld.HEART_POINT,150.0)
	coins += 100000
	_celebrate("寄生虫之心已摧毁！",Color("#fff0a0"),Vector2(390,170))
	show_message("祖父留下的秘密随矿井坍塌。剧情完成，奖励 100000 金币")
	_refresh_hud(); _save_game(); world.queue_redraw()
	await get_tree().create_timer(0.75).timeout
	_show_completion()

func _delete_cow(index: int, mouse_position: Vector2) -> void:
	if cow_states[index] == "skeleton":
		show_message("牛骷髅已经和土地长在一起，无法清理")
		return
	shooting = true
	player.fire_toward(mouse_position)
	var level := cows[index]
	await get_tree().create_timer(0.08).timeout
	await slots[index].play_delete_animation()
	sounds.play_sfx("poof")
	var was_parasite := cow_states[index] == "parasite"
	var refund := 0 if was_parasite else roundi(BUY_PRICE * pow(1.72, level) * 0.30 * (1.0 + _cow_bonus("recycle")))
	cows[index] = -1
	cow_traits[index] = {}
	cow_states[index] = "empty"
	coins += refund
	_advance_task("recycle")
	_refresh_all()
	_save_game()
	if was_parasite:
		_celebrate("寄生虫已清除", Color("#a8d993"), Vector2(390,245))
	else:
		_celebrate("回收 +%d 金币" % refund, Color("#ffbd69"), Vector2(390, 245))
	shooting = false

func _milk_per_second() -> int:
	var total := 0.0
	for i in cows.size():
		var level := cows[i]
		if level >= 0 and cow_states[i] == "normal":
			var amount := float(COW_MILK[level])
			if str(cow_traits[i].get("kind", "")) == "milk":
				amount *= 1.0 + float(cow_traits[i].get("value", 0.0))
			total += amount
	return roundi(total * (1.0 + prestige_medals * 0.12))

func _roll_lottery_level(tier_index := 0) -> int:
	var tier: Dictionary = LOTTERY_TIERS[clampi(tier_index, 0, LOTTERY_TIERS.size() - 1)]
	var weights: Array[int] = []
	var total := 0
	for level in range(int(tier.min), int(tier.max) + 1):
		var weight := maxi(1, roundi(1000000.0 * pow(float(tier.ratio), level - int(tier.min))))
		weights.append(weight)
		total += weight
	var roll := randi_range(1, total)
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0:
			return int(tier.min) + i
	return int(tier.max)

func _lottery_price(base_price: int) -> int:
	return maxi(1, roundi(base_price * maxf(0.55, 1.0 - _cow_bonus("lottery"))))

func _cow_bonus(kind: String) -> float:
	var total := 0.0
	for cow_trait in cow_traits:
		if not cow_trait.is_empty() and str(cow_trait.get("kind", "")) == kind:
			total += float(cow_trait.get("value", 0.0))
	return total

func _roll_cow_trait(level: int, extra_chance := 0.0) -> Dictionary:
	var chance := clampf(0.28 + level * 0.008 + extra_chance, 0.28, 0.68)
	if randf() > chance:
		return {}
	var template: Dictionary = TRAIT_TEMPLATES[randi_range(0, TRAIT_TEMPLATES.size() - 1)]
	var value: float = randf_range(float(template.min), float(template.max))
	if str(template.kind) == "prestige":
		value = 1.0
	return {"kind": str(template.kind), "name": str(template.name), "value": value}

func _merge_cow_trait(first: Dictionary, second: Dictionary, level: int) -> Dictionary:
	var inherited: Array[Dictionary] = []
	if not first.is_empty(): inherited.append(first)
	if not second.is_empty(): inherited.append(second)
	if not inherited.is_empty() and randf() < 0.62:
		var result: Dictionary = inherited.pick_random().duplicate(true)
		if str(result.get("kind", "")) != "prestige":
			result.value = minf(float(result.value) * 1.08, 0.35)
		return result
	return _roll_cow_trait(level, 0.07)

func _next_cat_cow_state() -> String:
	if free_mode or day_count < 3:
		return "normal"
	parasite_purchase_count += 1
	if parasite_purchase_count >= parasite_purchase_target:
		parasite_purchase_count = 0
		parasite_purchase_target = randi_range(3,6)
		milk_contaminated = true
		return "parasite"
	return "normal"

func _parasite_count() -> int:
	return cow_states.count("parasite")

func _skeleton_count() -> int:
	return cow_states.count("skeleton")

func _spread_parasites() -> int:
	if _parasite_count() <= 0:
		return 0
	var candidates: Array[int] = []
	for i in cows.size():
		if cows[i] >= 0 and cow_states[i] == "normal":
			candidates.append(i)
	candidates.shuffle()
	var amount := mini(randi_range(1,3), candidates.size())
	for i in amount:
		var index := candidates[i]
		cow_states[index] = "skeleton"
		cow_traits[index] = {}
	return amount

func _sleep_until_morning() -> void:
	if time_of_day < 18.0:
		show_message("现在还不困，天黑后再睡")
		return
	_spread_parasites()
	if _parasite_count() + _skeleton_count() > 0:
		milk_contaminated = true
	day_count += 1
	time_of_day = 6.0
	night_warning_shown = false
	night_overlay.color.a = 0.0
	_switch_scene(2, HouseWorld.WAKE_POINT)
	_refresh_all()
	_save_game()
	sounds.play_sfx("upgrade")
	_celebrate("DAY %d" % day_count, Color("#ffe6a0"), Vector2(390,205))

func _advance_task(kind: String, amount := 1) -> void:
	if task_system.advance(kind, amount):
		sounds.play_sfx("task")
		_celebrate("任务完成！", Color("#fff29b"), Vector2(390, 190))

func _tank_capacity() -> int:
	return roundi(100.0 * pow(1.45, tank_level - 1) * (1.0 + _cow_bonus("capacity")))

func _tank_upgrade_cost() -> int:
	return roundi(250.0 * pow(1.85, tank_level - 1) * maxf(0.45, 1.0 - _cow_bonus("upgrade")))

func _refresh_all() -> void:
	for i in SLOT_COUNT:
		slots[i].set_cow(cows[i], COW_NAMES, COW_MILK, cow_traits[i], cow_states[i])
	_refresh_hud()

func _refresh_hud() -> void:
	coin_label.text = "金币  %d" % coins
	milk_label.text = "奶罐已满" if stored_milk >= _tank_capacity() else ""
	carry_label.text = "携带牛奶  %d" % carried_milk
	tank_label.text = "奶罐 Lv.%d" % tank_level
	day_label.text = "DAY %d  %s" % [day_count, _format_time()]
	medal_label.text = "★ %d" % prestige_medals if free_mode else ""
	_refresh_health()
	if is_instance_valid(weapon_bar): weapon_bar.queue_redraw()
	_refresh_story_hint()
	farm_title.text = farm_name

func _refresh_story_hint() -> void:
	if not is_instance_valid(story_label): return
	story_label.visible = playing and not suspended
	if not playing: return
	var objective := ""
	if free_mode:
		objective = "自由经营：扩建奶罐、合成稀有奶牛，武器只能在家中武器库更换"
	elif parasite_heart_destroyed:
		objective = "主线完成：可在通关页面进入自由模式"
	elif scene_id >= 3:
		var stage := scene_id-3
		if campaign_worlds[stage].can_exit():
			objective = "区域已净化：前往发光出口 · %s" % ("把炸药安放到寄生虫之心" if stage==5 else CampaignWorld.ENTRY_NAMES[mini(stage+1,5)])
		else:
			objective = "当前目标：消灭 %s · 清场后出口才会开启" % CampaignWorld.ENEMY_NAMES[stage]
	elif day_count >= 6 and not blood_moon_defeated:
		objective = "当前目标：在牧场击败血月巨骷髅，躲开落地爆炸的骷髅头"
	elif parasite_ever_discovered and not first_skeleton_encounter_completed:
		objective = "当前目标：准备武器；第四天从家门出来会遭遇寄生骷髅"
	elif parasite_ever_discovered:
		objective = "当前目标：第六天击败血月巨骷髅，随后从玉米地墓井追查源头"
	elif day_count >= 3:
		objective = "当前目标：继续从卡车购牛并检查牛群，异常正在混入牧场"
	elif cows.count(-1) == SLOT_COUNT:
		objective = "新手目标：走到右侧卡车购买两只喵喵牛，然后拖动同级奶牛合成"
	elif stored_milk <= 0:
		objective = "新手目标：等待产奶；同级奶牛可直接拖到一起合成"
	elif carried_milk <= 0:
		objective = "新手目标：走近奶罐按 E 或 F 取出牛奶"
	else:
		objective = "新手目标：把牛奶带到右下市场，面对柜台按 E 或 F 出售"
	story_label.text = objective

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	notice_time = 3.0
	if is_instance_valid(menu_status) and is_instance_valid(menu) and menu.visible:
		menu_status.text = text

func _celebrate(text: String, color: Color, origin: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = origin
	label.size = Vector2(500, 72)
	label.pivot_offset = Vector2(250, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#3b3225"))
	label.add_theme_constant_override("outline_size", 8)
	label.scale = Vector2(0.35, 0.35)
	effects_layer.add_child(label)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.10)
	tween.tween_interval(0.45)
	tween.set_parallel(true)
	tween.tween_property(label, "position", origin + Vector2(0, -80), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
	for i in 8:
		var spark := Label.new()
		spark.text = "◆"
		spark.position = origin + Vector2(235, 25)
		spark.add_theme_font_size_override("font_size", 18 + i % 3 * 4)
		spark.add_theme_color_override("font_color", color.lightened(0.2))
		effects_layer.add_child(spark)
		var angle := TAU * i / 8.0
		var target := spark.position + Vector2.from_angle(angle) * (80 + i % 2 * 35)
		var star_tween := create_tween()
		star_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		star_tween.set_parallel(true)
		star_tween.tween_property(spark, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		star_tween.tween_property(spark, "modulate:a", 0.0, 0.55).set_delay(0.18)
		star_tween.chain().tween_callback(spark.queue_free)

func _scene_splash(title: String,subtitle: String) -> void:
	var panel:=ColorRect.new(); panel.position=Vector2(0,250); panel.size=Vector2(1280,170); panel.color=Color("#120d14",0.9); panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; effects_layer.add_child(panel)
	var label:=Label.new(); label.text="◆  %s  ◆\n%s" % [title,subtitle]; label.position=Vector2(140,18); label.size=Vector2(1000,130); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",34); label.add_theme_color_override("font_color",Color("#ffe5a0")); label.add_theme_color_override("font_outline_color",Color("#5e1f31")); label.add_theme_constant_override("outline_size",8); panel.add_child(label)
	panel.scale=Vector2(0.0,1.0); panel.pivot_offset=Vector2(640,85)
	var tween:=create_tween(); tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); tween.tween_property(panel,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT); tween.tween_interval(0.8); tween.tween_property(panel,"modulate:a",0.0,0.35); tween.tween_callback(panel.queue_free)
	sounds.play_sfx("upgrade")

func _unlock_splash(title: String,subtitle: String) -> void:
	_celebrate("解锁！ %s" % title,Color("#fff08c"),Vector2(390,145))
	show_message(subtitle)
	sounds.play_sfx("prestige")

func _show_completion() -> void:
	suspended=true; player.set_physics_process(false); trigger_held=false
	_clear_menu("寄生虫之心已毁灭")
	menu_status.text="矿井开始坍塌，寄生虫的尖叫逐渐停止。牧场、玉米地与奶罐终于恢复安静。\n\n通关奖励：100000 金币\n自由模式：关闭全部寄生虫事件，并重新开放牧场转生。"
	var art:=Label.new(); art.text="✦  COMPLETE  ✦"; art.custom_minimum_size=Vector2(460,120); art.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; art.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; art.add_theme_font_size_override("font_size",42); art.add_theme_color_override("font_color",Color("#f7d775")); menu_column.add_child(art)
	_menu_button("开启自由模式",_enter_free_mode)
	_menu_button("保存并返回标题",func(): _save_game(); _show_start())

func _enter_free_mode() -> void:
	free_mode=true; blood_moon_defeated=true; corn_world.enemies.clear(); milk_contaminated=false; carried_contaminated=false; market_closed_day=-1
	for i in cow_states.size():
		if cow_states[i] in ["parasite","skeleton"]:
			cow_states[i]="empty"; cows[i]=-1; cow_traits[i]={}
	_switch_scene(0,Vector2(650,450)); health=max_health; _refresh_all(); _save_game(); _resume()
	_unlock_splash("自由模式","寄生虫事件已关闭，转生系统重新开放")

func _save_game() -> bool:
	if not playing or active_slot < 1:
		return false
	var file := FileAccess.open(_slot_path(active_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"economy_version": ECONOMY_VERSION,
			"farm_name": farm_name, "saved_at": Time.get_datetime_string_from_system(),
			"coins": coins, "cows": cows, "cow_traits": cow_traits, "cow_states": cow_states, "tank_level": tank_level,
			"stored_milk": stored_milk, "carried_milk": carried_milk,
			"player_x": player.position.x, "player_y": player.position.y, "scene_id": scene_id,
			"day_count": day_count, "time_of_day": time_of_day,
			"parasite_purchase_count": parasite_purchase_count, "parasite_purchase_target": parasite_purchase_target,
			"milk_contaminated": milk_contaminated, "carried_contaminated": carried_contaminated,
			"market_closed_day": market_closed_day,
			"weapon_id":weapon_id,"owned_weapons":owned_weapons,
			"weapon_ammo":weapon_ammo,"weapon_modes":weapon_modes,
			"blood_moon_defeated":blood_moon_defeated,"blood_moon_announced":blood_moon_announced,
			"campaign_progress":campaign_progress,"dynamite_owned":dynamite_owned,
			"parasite_heart_destroyed":parasite_heart_destroyed,
			"first_skeleton_encounter_completed":first_skeleton_encounter_completed,
			"day4_wave_spawned":day4_wave_spawned,"parasite_ever_discovered":parasite_ever_discovered,
			"free_mode":free_mode,"health":health,
			"prestige_count": prestige_count, "prestige_medals": prestige_medals,
			"tasks": task_system.tasks, "task_stars": task_system.task_stars,
			"completed_tasks": task_system.completed
		}))

		return file.get_error() == OK
	return false

func _load_game() -> void:
	cows.resize(SLOT_COUNT)
	cows.fill(-1)
	cow_traits.resize(SLOT_COUNT)
	cow_states.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		cow_traits[i] = {}
		cow_states[i] = "empty"
	if not FileAccess.file_exists(_slot_path(active_slot)):
		return
	var file := FileAccess.open(_slot_path(active_slot), FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	farm_name = str(data.get("farm_name", "我的牧场"))
	coins = int(data.get("coins", 500))
	tank_level = maxi(1, int(data.get("tank_level", 1)))
	stored_milk = maxi(0, int(data.get("stored_milk", 0)))
	carried_milk = maxi(0, int(data.get("carried_milk", 0)))
	prestige_count = maxi(0, int(data.get("prestige_count", 0)))
	prestige_medals = maxi(0, int(data.get("prestige_medals", 0)))
	day_count = maxi(1, int(data.get("day_count", 1)))
	time_of_day = clampf(float(data.get("time_of_day", 8.0)), 0.0, 24.0)
	parasite_purchase_count = maxi(0, int(data.get("parasite_purchase_count", 0)))
	parasite_purchase_target = clampi(int(data.get("parasite_purchase_target", randi_range(3,6))), 3, 6)
	milk_contaminated = bool(data.get("milk_contaminated", false))
	carried_contaminated = bool(data.get("carried_contaminated", false))
	market_closed_day = int(data.get("market_closed_day", -1))
	weapon_id = str(data.get("weapon_id","shotgun"))
	if not WEAPONS.has(weapon_id): weapon_id="shotgun"
	var saved_weapons = data.get("owned_weapons",{})
	owned_weapons={}
	for id in WEAPON_ORDER: owned_weapons[id]=id=="shotgun"
	if saved_weapons is Dictionary:
		for id in owned_weapons.keys(): owned_weapons[id]=bool(saved_weapons.get(id,owned_weapons[id]))
	_reset_weapon_state()
	var saved_ammo=data.get("weapon_ammo",{})
	var saved_modes=data.get("weapon_modes",{})
	if saved_ammo is Dictionary:
		for id in WEAPON_ORDER: weapon_ammo[id]=clampi(int(saved_ammo.get(id,weapon_ammo[id])),0,int(WEAPONS[id].mag))
	if saved_modes is Dictionary:
		for id in WEAPON_ORDER:
			var mode:=str(saved_modes.get(id,weapon_modes[id])); weapon_modes[id]=mode if mode in WEAPONS[id].modes else str(WEAPONS[id].modes[0])
	blood_moon_defeated=bool(data.get("blood_moon_defeated",false))
	blood_moon_announced=bool(data.get("blood_moon_announced",false))
	campaign_progress=clampi(int(data.get("campaign_progress",0)),0,6)
	dynamite_owned=bool(data.get("dynamite_owned",false))
	parasite_heart_destroyed=bool(data.get("parasite_heart_destroyed",false))
	first_skeleton_encounter_completed=bool(data.get("first_skeleton_encounter_completed",false))
	day4_wave_spawned=bool(data.get("day4_wave_spawned",false))
	parasite_ever_discovered=bool(data.get("parasite_ever_discovered",false))
	free_mode=bool(data.get("free_mode",false))
	health=clampf(float(data.get("health",max_health)),1.0,max_health)
	shotgun_equipped=false
	player.set_weapon("")
	blood_moon.bombs.clear()
	blood_moon.boss_hp=0
	for world in campaign_worlds:
		world.enemies.clear(); world.cleared=false
	task_system.load_data(data, prestige_count)
	player.carrying = carried_milk
	var saved_position := Vector2(float(data.get("player_x", 650)), float(data.get("player_y", 430)))
	scene_id = clampi(int(data.get("scene_id", 0)), 0, 8)
	var saved: Array = data.get("cows", [])
	for i in mini(saved.size(), SLOT_COUNT):
		cows[i] = clampi(int(saved[i]), -1, COW_NAMES.size() - 1)
	var saved_traits: Array = data.get("cow_traits", [])
	var saved_states: Array = data.get("cow_states", [])
	for i in SLOT_COUNT:
		if i < saved_traits.size() and saved_traits[i] is Dictionary:
			cow_traits[i] = saved_traits[i].duplicate(true)
		elif cows[i] >= 0:
			cow_traits[i] = _roll_cow_trait(cows[i])
		if i < saved_states.size() and str(saved_states[i]) in ["normal","parasite","skeleton","empty"]:
			cow_states[i] = str(saved_states[i])
		else:
			cow_states[i] = "normal" if cows[i] >= 0 else "empty"
	if int(data.get("economy_version", 1)) < ECONOMY_VERSION:
		coins = maxi(500, roundi(coins / 100.0))
		stored_milk = maxi(0, roundi(stored_milk / 50.0))
		carried_milk = maxi(0, roundi(carried_milk / 50.0))
		player.carrying = carried_milk
		stored_milk = mini(stored_milk, _tank_capacity())
	_switch_scene(scene_id, saved_position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not playing or _save_game():
			get_tree().quit()
		else:
			show_message("保存失败，请检查磁盘空间")

func _slot_path(index: int) -> String:
	return save_root + "farm_slot_%d.json" % index

func _read_slot(index: int) -> Dictionary:
	var path := _slot_path(index)
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(menu)
	var shade := ColorRect.new()
	shade.color = Color("#192c24", 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(365, 15)
	panel.size = Vector2(550, 690)
	panel.add_theme_stylebox_override("panel", _box(Color("#eedeb1"), Color("#684e36"), 0, 6))
	menu.add_child(panel)
	var margin := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 28)
	panel.add_child(margin)
	menu_column = VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 14)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(482,600)
	margin.add_child(scroll)
	menu_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(menu_column)

func _clear_menu(title: String) -> void:
	menu_column.add_theme_constant_override("separation",14)
	for child in menu_column.get_children():
		menu_column.remove_child(child)
		child.queue_free()
	menu.show()
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("#493c2c"))
	menu_column.add_child(heading)
	menu_status = Label.new()
	menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status.add_theme_color_override("font_color", Color("#72503b"))
	menu_status.add_theme_font_size_override("font_size", 16)
	menu_column.add_child(menu_status)

func _menu_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 60
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff0cb"))
	button.add_theme_stylebox_override("normal", _box(Color("#516e52"), Color("#304b3b"), 0, 3))
	button.add_theme_stylebox_override("hover", _box(Color("#6f895c"), Color("#d5b76c"), 0, 3))
	if action.is_valid():
		button.pressed.connect(func():
			sounds.play_sfx("ui")
			action.call()
		)
	menu_column.add_child(button)

func _show_start() -> void:
	game_over = false
	playing = false
	suspended = true
	player.set_physics_process(false)
	message_label.hide()
	_clear_menu("农场大亨")
	for index in range(1, 4):
		var data := _read_slot(index)
		if data.is_empty() and FileAccess.file_exists(_slot_path(index)):
			_menu_button("存档 %d · 文件无法读取" % index, func(): show_message("此存档已保留，未覆盖"))
		elif data.is_empty():
			_menu_button("存档 %d · 新建牧场" % index, _show_new.bind(index))
		else:
			_menu_button("存档 %d · %s" % [index, data.get("farm_name", "我的牧场")], _continue_game.bind(index))
		if FileAccess.file_exists(_slot_path(index)):
			var slot_button: Button = menu_column.get_child(menu_column.get_child_count()-1)
			slot_button.gui_input.connect(_slot_right_click.bind(index))
	if FileAccess.file_exists(SAVE_PATH):
		_menu_button("导入旧版进度", _import_legacy)
	_menu_button("退出游戏", func(): get_tree().quit())

func _show_new(index: int) -> void:
	active_slot = index
	_clear_menu("为牧场起个名字")
	name_input = LineEdit.new()
	name_input.placeholder_text = "输入牧场名称"
	name_input.max_length = 12
	name_input.custom_minimum_size.y = 60
	name_input.add_theme_font_size_override("font_size", 24)
	menu_column.add_child(name_input)
	_menu_button("开始经营", _start_new)
	_menu_button("返回", _show_start)
	name_input.grab_focus()

func _start_new() -> void:
	if name_input.text.strip_edges().is_empty():
		name_input.placeholder_text = "请先输入牧场名称"
		return
	farm_name = name_input.text.strip_edges()
	coins = 500
	cows.fill(-1)
	for i in SLOT_COUNT:
		cow_traits[i] = {}
		cow_states[i] = "empty"
	tank_level = 1
	stored_milk = 0
	carried_milk = 0
	prestige_count = 0
	prestige_medals = 0
	day_count = 1
	time_of_day = 8.0
	parasite_purchase_count = 0
	parasite_purchase_target = randi_range(3,6)
	night_warning_shown = false
	milk_contaminated = false
	carried_contaminated = false
	market_closed_day = -1
	weapon_id="shotgun"
	owned_weapons={}
	for id in WEAPON_ORDER: owned_weapons[id]=id=="shotgun"
	_reset_weapon_state()
	blood_moon_defeated=false
	blood_moon_announced=false
	campaign_progress=0
	dynamite_owned=false
	parasite_heart_destroyed=false
	first_skeleton_encounter_completed=false
	day4_wave_spawned=false
	parasite_ever_discovered=false
	free_mode=false
	health=max_health
	for world in campaign_worlds:
		world.enemies.clear(); world.cleared=false
	task_system.reset_run(0)
	_switch_scene(0, Vector2(815, 430))
	player.carrying = 0
	shotgun_equipped = false
	player.set_shotgun(false)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	playing = true
	_resume()
	_refresh_all()
	_save_game()
	_scene_splash("欢迎来到 %s" % farm_name,"先去右侧卡车购买两只奶牛；拖动同级奶牛即可合成")
	show_message("沿着顶部剧情目标行动；武器只能在家里的武器库选择")

func _continue_game(index: int) -> void:
	active_slot = index
	_load_game()
	playing = true
	_resume()
	_refresh_all()

func _import_legacy() -> void:
	for index in range(1, 4):
		if not FileAccess.file_exists(_slot_path(index)):
			var source := FileAccess.get_file_as_string(SAVE_PATH)
			if not JSON.parse_string(source) is Dictionary:
				show_message("旧版存档无法读取")
				return
			var file := FileAccess.open(_slot_path(index), FileAccess.WRITE)
			if file:
				file.store_string(source)
				file.close()
				_continue_game(index)
			return
	show_message("没有空存档位，旧版进度已保留")

func _show_pause() -> void:
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	_clear_menu(farm_name)
	menu_status.text = ("自由模式 · 转生 %d 次 · 永久产量 +%d％ · 任务星星 %d" % [prestige_count,prestige_medals*12,task_system.task_stars]) if free_mode else ("主线进行中 · 任务星星 %d · 转生将在通关后的自由模式开放" % task_system.task_stars)
	_menu_button("继续游戏", _resume)
	_menu_button("测试者模式", _show_tester_panel)
	if free_mode: _menu_button("自由模式转生", _show_prestige)
	_menu_button("保存进度", func():
		if _save_game():
			show_message("进度已保存")
			_resume()
	)
	_menu_button("保存并返回标题", func():
		if _save_game():
			_show_start()
	)
	_menu_button("保存并退出游戏", func():
		if _save_game():
			get_tree().quit()
	)

func _resume() -> void:
	suspended = false
	menu.hide()
	player.set_physics_process(true)
	if shotgun_equipped:
		Input.set_custom_mouse_cursor(load("res://assets/crosshair.svg"), Input.CURSOR_ARROW, Vector2(16, 16))

func _show_tester_panel() -> void:
	if not playing: return
	suspended=true; player.set_physics_process(false); trigger_held=false
	_clear_menu("测试者模式")
	menu_column.add_theme_constant_override("separation",6)
	menu_status.text="体验更新专用。长按 TAB 两秒可随时重新打开。"
	_menu_button("金币 +1,000,000",func(): coins+=1000000; _refresh_hud(); _save_game(); _show_tester_panel())
	_menu_button("解锁并装满全部武器",func():
		for id in WEAPON_ORDER: owned_weapons[id]=true; weapon_ammo[id]=int(WEAPONS[id].mag)
		_equip_weapon("m249"); _show_tester_panel())
	_menu_button("时间倒流到前一天",func(): day_count=maxi(1,day_count-1); time_of_day=8.0; blood_moon_announced=false; _refresh_hud(); _save_game(); _show_tester_panel())
	_menu_button("时间快进五小时",func(): time_of_day=minf(24.0,time_of_day+5.0); _refresh_hud(); _save_game(); _show_tester_panel())
	_menu_button("重置第四天骷髅事件",func(): day_count=4; time_of_day=8.0; day4_wave_spawned=false; first_skeleton_encounter_completed=false; corn_world.enemies.clear(); _save_game(); _show_tester_panel())
	_menu_button("恢复生命并清除装填状态",func(): health=max_health; reloading=false; _refresh_health(); _show_tester_panel())
	_menu_button("直接解锁战役区域",func(): parasite_ever_discovered=true; blood_moon_defeated=true; campaign_progress=6; dynamite_owned=true; _save_game(); _show_tester_panel())
	_menu_button("返回游戏",_resume)

func _show_tasks() -> void:
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_clear_menu("牧场任务")
	menu_status.text = "完成任务领取金币和星星。星星会在通关后的自由模式中提高转生奖励。\n现有任务星星：%d" % task_system.task_stars
	for i in task_system.tasks.size():
		var task: Dictionary = task_system.tasks[i]
		var done: bool = int(task.progress) >= int(task.target)
		var caption := "%s  %d/%d\n奖励 %d 金币 · ★%d" % [task.title, task.progress, task.target, task.reward, task.stars]
		if done:
			caption = "领取 · " + caption
		_menu_button(caption, _claim_task.bind(i) if done else Callable())
		var button: Button = menu_column.get_child(menu_column.get_child_count() - 1)
		button.disabled = not done
	_menu_button("返回牧场", _resume)

func _claim_task(index: int) -> void:
	var reward: Dictionary = task_system.claim(index)
	if reward.is_empty():
		return
	var paid := mini(12000, roundi(int(reward.coins) * (1.0 + _cow_bonus("task"))))
	coins += paid
	sounds.play_sfx("task")
	_celebrate("任务奖励 +%d 金币  ★+%d" % [paid, reward.stars], Color("#fff29b"), Vector2(390, 190))
	_save_game()
	_refresh_hud()
	_show_tasks()

func _has_final_cow() -> bool:
	return cows.has(COW_NAMES.size() - 1)

func _prestige_reward() -> int:
	return clampi(1 + floori(float(coins) / PRESTIGE_COST) + floori(float(task_system.task_stars) / 5.0) + roundi(_cow_bonus("prestige")), 1, 100)

func _show_prestige() -> void:
	if not free_mode:
		show_message("转生只在通关后的自由模式开放")
		return
	_clear_menu("牧场转生")
	var eligible := coins >= PRESTIGE_COST and _has_final_cow()
	menu_status.text = "转生会重置金币、奶牛和奶罐，保留牧场名与勋章。\n每枚勋章永久增加 12％ 产奶。\n\n要求：1 亿金币 + 1 只终焉龙神牛\n本次可获得：★%d\n当前永久加成：+%d％" % [_prestige_reward(), prestige_medals * 12]
	if eligible:
		_menu_button("确认转生 · 获得 ★%d" % _prestige_reward(), _do_prestige)
	else:
		_menu_button("尚未满足转生条件", Callable())
		var button: Button = menu_column.get_child(menu_column.get_child_count() - 1)
		button.disabled = true
	_menu_button("返回", _show_pause)

func _do_prestige() -> void:
	if coins < PRESTIGE_COST or not _has_final_cow():
		return
	var reward := _prestige_reward()
	prestige_medals += reward
	prestige_count += 1
	coins = 500 + prestige_medals * 100
	cows.fill(-1)
	for i in SLOT_COUNT:
		cow_traits[i] = {}
		cow_states[i] = "empty"
	tank_level = 1
	stored_milk = 0
	carried_milk = 0
	day_count = 1
	time_of_day = 8.0
	parasite_purchase_count = 0
	parasite_purchase_target = randi_range(3,6)
	milk_contaminated = false
	carried_contaminated = false
	market_closed_day = -1
	weapon_id="shotgun"
	owned_weapons={}
	for id in WEAPON_ORDER: owned_weapons[id]=id=="shotgun"
	_reset_weapon_state()
	blood_moon_defeated=true
	blood_moon_announced=false
	campaign_progress=6
	dynamite_owned=true
	parasite_heart_destroyed=true
	first_skeleton_encounter_completed=false
	day4_wave_spawned=false
	parasite_ever_discovered=false
	health=max_health
	for world in campaign_worlds:
		world.enemies.clear(); world.cleared=false
	_switch_scene(0, Vector2(815, 430))
	player.carrying = 0
	task_system.reset_run(prestige_count)
	sounds.play_sfx("prestige")
	_refresh_all()
	_save_game()
	_resume()
	_celebrate("转生成功！ ★+%d" % reward, Color("#fff4a8"), Vector2(390, 220))
	show_message("永久产奶加成提升至 +%d％" % (prestige_medals * 12))

func _slot_right_click(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_clear_menu("存档 %d" % index)
		menu_status.text = "删除后无法恢复，只删除选中的存档。"
		_menu_button("删除这个存档", _delete_selected_slot.bind(index))
		_menu_button("取消", _show_start)

func _delete_selected_slot(index: int) -> void:
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(index)))
	if error != OK:
		show_message("删除失败，存档已保留")
		return
	_show_start()


