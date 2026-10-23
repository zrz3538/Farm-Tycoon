extends Node2D

const SAVE_PATH := "user://farm_tycoon_save.json"
const BUY_PRICE := 50
const MILK_VALUE := 8
const SLOT_COUNT := 12
const LOTTERY_PRICE := 150000
const PRESTIGE_COST := 100000000
const COW_NAMES := ["喵喵牛", "鲨鱼牛", "霸王龙牛", "雷霆牛", "熔岩牛", "机甲牛", "星空龙牛", "混沌牛魔王", "云朵牛", "幽灵牛", "彩虹牛", "宇宙帝王牛", "霜冻猛犸牛", "海盗船长牛", "赛博忍者牛", "凤凰牛", "时间领主牛", "虚空吞噬牛", "创世神牛"]
const COW_MILK := [5, 14, 40, 110, 300, 850, 2500, 8000, 24000, 70000, 220000, 750000, 2500000, 8000000, 26000000, 85000000, 280000000, 900000000, 3000000000]
const LOTTERY_WEIGHTS := [500000, 250000, 120000, 60000, 30000, 15000, 7000, 3500, 1600, 800, 400, 180, 80, 35, 15, 7, 3, 1]
const COW_ATLAS := preload("res://assets/cows.svg")
const CowSlot := preload("res://cow_slot.gd")
const FarmWorld := preload("res://farm_world.gd")
const Cowboy := preload("res://player.gd")
const SoundManager := preload("res://sound_manager.gd")
const TaskSystem := preload("res://task_system.gd")

var coins := 500
var cows: Array[int] = []
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

func _ready() -> void:
	sounds = SoundManager.new()
	add_child(sounds)
	task_system = TaskSystem.new()
	add_child(task_system)
	var world := FarmWorld.new()
	world.name = "FarmWorld"
	add_child(world)
	_build_cow_field()
	player = Cowboy.new()
	player.position = Vector2(650, 430)
	player.z_index = 5
	player.set_physics_process(false)
	add_child(player)
	_build_hud()
	cows.resize(SLOT_COUNT)
	cows.fill(-1)
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
	medal_label = _hud_label(top, Vector2(1160, 15), Color("#ffe38b"))

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
	if notice_time > 0:
		notice_time -= delta
		message_label.visible = notice_time > 0


func _input(event: InputEvent) -> void:
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
		elif event.keycode == KEY_E:
			_try_interact(true)
		elif event.keycode == KEY_F:
			_try_interact(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and playing and not suspended:
		if shotgun_equipped:
			_try_shoot_cow(event.position)
		elif not _mouse_over_cow_slot(event.position):
			_try_interact(true)

func _try_interact(allow_barn: bool) -> void:
	if _near(FarmWorld.TRUCK_POINT):
		_buy_cow()
	elif _near(FarmWorld.LOTTERY_POINT):
		_play_lottery()
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

func _mouse_over_cow_slot(point: Vector2) -> bool:
	for slot in slots:
		if slot.get_global_rect().has_point(point):
			return true
	return false

func can_manage_cows() -> bool:
	return playing and not suspended

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
	_advance_task("buy")
	sounds.play_sfx("cash")
	show_message("购买成功：喵喵牛来到牧场")
	_save_game()
	_refresh_all()

func _on_cow_dropped(from_index: int, to_index: int) -> void:
	if not can_manage_cows() or from_index == to_index or cows[from_index] < 0:
		return
	if cows[to_index] == -1:
		cows[to_index] = cows[from_index]
		cows[from_index] = -1
		sounds.play_sfx("swap")
		show_message("奶牛已移动到新草地")
	elif cows[to_index] == cows[from_index]:
		var level := cows[to_index]
		if level >= COW_NAMES.size() - 1:
			show_message("创世神牛已经是最高等级")
			return
		cows[from_index] = -1
		cows[to_index] = level + 1
		_advance_task("merge")
		sounds.play_sfx("merge")
		show_message("合成成功：%s！" % COW_NAMES[level + 1])
		slots[to_index].play_merge_animation()
		_celebrate("合成成功！  %s" % COW_NAMES[level + 1], Color("#ffe080"), Vector2(390, 245))
	else:
		var held := cows[from_index]
		cows[from_index] = cows[to_index]
		cows[to_index] = held
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
		_advance_task("produce", stored_milk - before)
	_refresh_hud()

func _take_milk() -> void:
	if stored_milk <= 0:
		show_message("奶罐是空的，等奶牛产奶吧")
		return
	carried_milk += stored_milk
	stored_milk = 0
	sounds.play_sfx("milk")
	player.carrying = carried_milk
	show_message("已提取全部牛奶，去右侧市场出售")
	_refresh_hud()
	_save_game()

func _sell_milk() -> void:
	if carried_milk <= 0:
		show_message("你没有携带牛奶，先去奶罐取奶")
		return
	var sold := carried_milk
	var earned := sold * MILK_VALUE
	coins += earned
	_advance_task("sell", sold)
	sounds.play_sfx("sell")
	show_message("售出 %d 份牛奶，获得 %d 金币" % [carried_milk, earned])
	_celebrate("+%d 金币" % earned, Color("#ffd45d"), Vector2(835, 260))
	carried_milk = 0
	player.carrying = 0
	_refresh_hud()
	_save_game()

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

func _play_lottery() -> void:
	var empty := cows.find(-1)
	if empty == -1:
		show_message("牧场没有空位")
		return
	if coins < LOTTERY_PRICE:
		show_message("彩票需要 %d 金币" % LOTTERY_PRICE)
		return
	coins -= LOTTERY_PRICE
	var level := _roll_lottery_level()
	cows[empty] = level
	_advance_task("lottery")
	sounds.play_sfx("cash")
	sounds.play_sfx("lottery")
	_refresh_all()
	_save_game()
	_celebrate("抽中 %s！" % COW_NAMES[level], Color("#f0a8ff"), Vector2(390, 245))

func _toggle_shotgun() -> void:
	shotgun_equipped = not shotgun_equipped
	player.set_shotgun(shotgun_equipped)
	sounds.play_sfx("equip")
	if shotgun_equipped:
		var cursor := load("res://assets/crosshair.svg")
		Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(16, 16))
		show_message("猎枪已取出")
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		show_message("猎枪已收回")

func _try_shoot_cow(mouse_position: Vector2) -> void:
	if shooting:
		return
	sounds.play_sfx("shot")
	for i in slots.size():
		if cows[i] >= 0 and slots[i].get_global_rect().has_point(mouse_position):
			_delete_cow(i, mouse_position)
			return
	player.fire_toward(mouse_position)

func _delete_cow(index: int, mouse_position: Vector2) -> void:
	shooting = true
	player.fire_toward(mouse_position)
	var level := cows[index]
	await get_tree().create_timer(0.08).timeout
	await slots[index].play_delete_animation()
	sounds.play_sfx("poof")
	var refund := roundi(BUY_PRICE * pow(2.0, level) * 0.30)
	cows[index] = -1
	coins += refund
	_advance_task("recycle")
	_refresh_all()
	_save_game()
	_celebrate("回收 +%d 金币" % refund, Color("#ffbd69"), Vector2(390, 245))
	shooting = false

func _milk_per_second() -> int:
	var total := 0
	for level in cows:
		if level >= 0:
			total += COW_MILK[level]
	return roundi(total * (1.0 + prestige_medals * 0.20))

func _roll_lottery_level() -> int:
	var total := 0
	for weight in LOTTERY_WEIGHTS:
		total += weight
	var roll := randi_range(1, total)
	for i in LOTTERY_WEIGHTS.size():
		roll -= LOTTERY_WEIGHTS[i]
		if roll <= 0:
			return i + 1
	return COW_NAMES.size() - 1

func _advance_task(kind: String, amount := 1) -> void:
	if task_system.advance(kind, amount):
		sounds.play_sfx("task")
		_celebrate("任务完成！", Color("#fff29b"), Vector2(390, 190))

func _tank_capacity() -> int:
	return roundi(100.0 * pow(1.75, tank_level - 1))

func _tank_upgrade_cost() -> int:
	return roundi(150.0 * pow(1.55, tank_level - 1))

func _refresh_all() -> void:
	for i in SLOT_COUNT:
		slots[i].set_cow(cows[i], COW_NAMES, COW_MILK)
	_refresh_hud()

func _refresh_hud() -> void:
	coin_label.text = "金币  %d" % coins
	milk_label.text = "奶罐已满" if stored_milk >= _tank_capacity() else ""
	carry_label.text = "携带牛奶  %d" % carried_milk
	tank_label.text = "奶罐 Lv.%d  产量 %d/秒" % [tank_level, _milk_per_second()]
	medal_label.text = "★ %d" % prestige_medals
	farm_title.text = farm_name

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

func _save_game() -> bool:
	if not playing or active_slot < 1:
		return false
	var file := FileAccess.open(_slot_path(active_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"farm_name": farm_name, "saved_at": Time.get_datetime_string_from_system(),
			"coins": coins, "cows": cows, "tank_level": tank_level,
			"stored_milk": stored_milk, "carried_milk": carried_milk,
			"player_x": player.position.x, "player_y": player.position.y,
			"prestige_count": prestige_count, "prestige_medals": prestige_medals,
			"tasks": task_system.tasks, "task_stars": task_system.task_stars,
			"completed_tasks": task_system.completed
		}))

		return file.get_error() == OK
	return false

func _load_game() -> void:
	cows.resize(SLOT_COUNT)
	cows.fill(-1)
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
	task_system.load_data(data, prestige_count)
	player.carrying = carried_milk
	player.position = Vector2(float(data.get("player_x", 650)), float(data.get("player_y", 430)))
	var saved: Array = data.get("cows", [])
	for i in mini(saved.size(), SLOT_COUNT):
		cows[i] = clampi(int(saved[i]), -1, COW_NAMES.size() - 1)

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
	panel.position = Vector2(365, 70)
	panel.size = Vector2(550, 580)
	panel.add_theme_stylebox_override("panel", _box(Color("#eedeb1"), Color("#684e36"), 0, 6))
	menu.add_child(panel)
	var margin := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 28)
	panel.add_child(margin)
	menu_column = VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 14)
	margin.add_child(menu_column)

func _clear_menu(title: String) -> void:
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
	tank_level = 1
	stored_milk = 0
	carried_milk = 0
	prestige_count = 0
	prestige_medals = 0
	task_system.reset_run(0)
	player.position = Vector2(815, 430)
	player.carrying = 0
	shotgun_equipped = false
	player.set_shotgun(false)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	playing = true
	_resume()
	_refresh_all()
	_save_game()

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
	menu_status.text = "转生 %d 次 · 永久产量 +%d％ · 任务星星 %d" % [prestige_count, prestige_medals * 20, task_system.task_stars]
	_menu_button("继续游戏", _resume)
	_menu_button("牧场转生", _show_prestige)
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

func _show_tasks() -> void:
	suspended = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_clear_menu("牧场任务")
	menu_status.text = "完成任务领取金币和星星。星星可提高本轮转生奖励。\n现有任务星星：%d" % task_system.task_stars
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
	coins += int(reward.coins)
	sounds.play_sfx("task")
	_celebrate("任务奖励 +%d 金币  ★+%d" % [reward.coins, reward.stars], Color("#fff29b"), Vector2(390, 190))
	_save_game()
	_refresh_hud()
	_show_tasks()

func _has_final_cow() -> bool:
	return cows.has(COW_NAMES.size() - 1)

func _prestige_reward() -> int:
	return clampi(1 + floori(float(coins) / PRESTIGE_COST) + floori(float(task_system.task_stars) / 5.0), 1, 100)

func _show_prestige() -> void:
	_clear_menu("牧场转生")
	var eligible := coins >= PRESTIGE_COST and _has_final_cow()
	menu_status.text = "转生会重置金币、奶牛和奶罐，保留牧场名与勋章。\n每枚勋章永久增加 20％ 产奶。\n\n要求：1 亿金币 + 1 只创世神牛\n本次可获得：★%d\n当前永久加成：+%d％" % [_prestige_reward(), prestige_medals * 20]
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
	tank_level = 1
	stored_milk = 0
	carried_milk = 0
	player.position = Vector2(815, 430)
	player.carrying = 0
	task_system.reset_run(prestige_count)
	sounds.play_sfx("prestige")
	_refresh_all()
	_save_game()
	_resume()
	_celebrate("转生成功！ ★+%d" % reward, Color("#fff4a8"), Vector2(390, 220))
	show_message("永久产奶加成提升至 +%d％" % (prestige_medals * 20))
