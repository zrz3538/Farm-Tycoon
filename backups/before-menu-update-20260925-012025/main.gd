extends Node2D

const SAVE_PATH := "user://farm_tycoon_save.json"
const BUY_PRICE := 50
const MILK_VALUE := 6
const SLOT_COUNT := 12
const COW_NAMES := ["喵喵牛", "鲨鱼牛", "霸王龙牛", "雷霆牛", "熔岩牛", "机甲牛", "星空龙牛", "混沌牛魔王"]
const COW_MILK := [1, 3, 8, 20, 50, 120, 300, 800]
const COW_ATLAS := preload("res://assets/cows.svg")
const CowSlot := preload("res://cow_slot.gd")
const FarmWorld := preload("res://farm_world.gd")
const Cowboy := preload("res://player.gd")

var coins := 200
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
var buy_button: Button

func _ready() -> void:
	var world := FarmWorld.new()
	add_child(world)
	_build_cow_field()
	player = Cowboy.new()
	player.position = Vector2(650, 430)
	player.z_index = 5
	add_child(player)
	_build_hud()
	_load_game()
	_refresh_all()
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
	var top := ColorRect.new()
	top.color = Color("#243b2a", 0.94)
	top.position = Vector2.ZERO
	top.size = Vector2(1280, 54)
	canvas.add_child(top)
	var title := Label.new()
	title.text = "农场大亨"
	title.position = Vector2(22, 10)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#fff0b5"))
	top.add_child(title)
	coin_label = _hud_label(top, Vector2(240, 15), Color("#ffd45d"))
	milk_label = _hud_label(top, Vector2(440, 15), Color("#e8fbff"))
	carry_label = _hud_label(top, Vector2(690, 15), Color("#ffffff"))
	tank_label = _hud_label(top, Vector2(900, 15), Color("#bfe7ef"))

	var side := PanelContainer.new()
	side.position = Vector2(842, 76)
	side.size = Vector2(406, 270)
	side.add_theme_stylebox_override("panel", _box(Color("#f3e2af", 0.96), Color("#6f5936"), 5, 4))
	canvas.add_child(side)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 15)
	pad.add_theme_constant_override("margin_bottom", 15)
	side.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var guide := Label.new()
	guide.text = "牧场工作手册"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_font_size_override("font_size", 23)
	guide.add_theme_color_override("font_color", Color("#503a27"))
	column.add_child(guide)
	var controls := Label.new()
	controls.text = "WASD  移动牛仔\n蓝圈附近：拖动奶牛合成\n奶罐：面对后按 E/F 取奶\n市场：面对后按 E/F 卖奶\n谷仓：面对后按 E 升级奶罐"
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("#514737"))
	column.add_child(controls)
	buy_button = Button.new()
	buy_button.text = "购买喵喵牛　50 金币"
	buy_button.custom_minimum_size = Vector2(0, 48)
	buy_button.add_theme_font_size_override("font_size", 19)
	buy_button.add_theme_stylebox_override("normal", _box(Color("#e9b945"), Color("#74501d"), 4, 3))
	buy_button.add_theme_stylebox_override("hover", _box(Color("#ffd467"), Color("#74501d"), 4, 3))
	buy_button.pressed.connect(_buy_cow)
	column.add_child(buy_button)

	message_label = Label.new()
	message_label.position = Vector2(350, 661)
	message_label.size = Vector2(580, 42)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("#fff7cf"))
	message_label.add_theme_stylebox_override("normal", _box(Color("#263a2b", 0.9), Color("#d5bd70"), 4, 2))
	message_label.text = "走到牧场入口，开始管理奶牛"
	canvas.add_child(message_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(475, 395)
	prompt_label.size = Vector2(330, 44)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color("#fff7bd"))
	prompt_label.add_theme_stylebox_override("normal", _box(Color("#24332a", 0.88), Color("#fff0a3"), 4, 2))
	prompt_label.hide()
	canvas.add_child(prompt_label)

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

func _process(_delta: float) -> void:
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_try_interact(true)
		elif event.keycode == KEY_F:
			_try_interact(false)

func _try_interact(allow_barn: bool) -> void:
	if player.faces_point(FarmWorld.TANK_POINT, 105):
		_take_milk()
	elif player.faces_point(FarmWorld.MARKET_POINT, 110):
		_sell_milk()
	elif allow_barn and player.faces_point(FarmWorld.BARN_POINT, 105):
		_upgrade_tank()
	else:
		show_message("请靠近交互点，并让牛仔面对设施")

func _update_prompt() -> void:
	var text := ""
	if player.faces_point(FarmWorld.TANK_POINT, 105):
		text = "E / F  取出全部牛奶"
	elif player.faces_point(FarmWorld.MARKET_POINT, 110):
		text = "E / F  出售携带的牛奶"
	elif player.faces_point(FarmWorld.BARN_POINT, 105):
		text = "E  升级奶罐（%d 金币）" % _tank_upgrade_cost()
	elif can_manage_cows():
		text = "现在可以用鼠标拖动奶牛"
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func can_manage_cows() -> bool:
	return player.global_position.distance_to(FarmWorld.PASTURE_POINT) <= 115.0

func _buy_cow() -> void:
	var empty := cows.find(-1)
	if empty == -1:
		show_message("牧场已满，去蓝色交互点合成奶牛吧")
		return
	if coins < BUY_PRICE:
		show_message("金币不足，先去市场卖牛奶")
		return
	coins -= BUY_PRICE
	cows[empty] = 0
	show_message("购买成功：喵喵牛来到牧场")
	_save_game()
	_refresh_all()

func _on_cow_dropped(from_index: int, to_index: int) -> void:
	if not can_manage_cows() or from_index == to_index or cows[from_index] < 0:
		return
	if cows[to_index] == -1:
		cows[to_index] = cows[from_index]
		cows[from_index] = -1
		show_message("奶牛已移动到新草地")
	elif cows[to_index] == cows[from_index]:
		var level := cows[to_index]
		if level >= COW_NAMES.size() - 1:
			show_message("混沌牛魔王已经是最高等级")
			return
		cows[from_index] = -1
		cows[to_index] = level + 1
		show_message("合成成功：%s！" % COW_NAMES[level + 1])
	else:
		show_message("只有同等级奶牛才能合成")
	_save_game()
	_refresh_all()

func _produce_milk() -> void:
	var amount := _milk_per_second()
	if amount > 0 and stored_milk < _tank_capacity():
		stored_milk = mini(_tank_capacity(), stored_milk + amount)
	_refresh_hud()

func _take_milk() -> void:
	if stored_milk <= 0:
		show_message("奶罐是空的，等奶牛产奶吧")
		return
	carried_milk += stored_milk
	stored_milk = 0
	player.carrying = carried_milk
	show_message("已提取全部牛奶，去右侧市场出售")
	_refresh_hud()
	_save_game()

func _sell_milk() -> void:
	if carried_milk <= 0:
		show_message("你没有携带牛奶，先去奶罐取奶")
		return
	var earned := carried_milk * MILK_VALUE
	coins += earned
	show_message("售出 %d 份牛奶，获得 %d 金币" % [carried_milk, earned])
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
	show_message("奶罐升到 %d 级，容量提升至 %d" % [tank_level, _tank_capacity()])
	_refresh_hud()
	_save_game()

func _milk_per_second() -> int:
	var total := 0
	for level in cows:
		if level >= 0:
			total += COW_MILK[level]
	return total

func _tank_capacity() -> int:
	return roundi(30.0 * pow(1.55, tank_level - 1))

func _tank_upgrade_cost() -> int:
	return roundi(100.0 * pow(1.7, tank_level - 1))

func _refresh_all() -> void:
	for i in SLOT_COUNT:
		slots[i].set_cow(cows[i], COW_NAMES, COW_MILK)
	_refresh_hud()

func _refresh_hud() -> void:
	coin_label.text = "金币  %d" % coins
	milk_label.text = "奶罐  %d / %d" % [stored_milk, _tank_capacity()]
	carry_label.text = "携带牛奶  %d" % carried_milk
	tank_label.text = "奶罐 Lv.%d  产量 %d/秒" % [tank_level, _milk_per_second()]
	buy_button.disabled = coins < BUY_PRICE or cows.find(-1) == -1

func show_message(text: String) -> void:
	message_label.text = text

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"coins": coins, "cows": cows, "tank_level": tank_level,
			"stored_milk": stored_milk, "carried_milk": carried_milk,
			"player_x": player.position.x, "player_y": player.position.y
		}))

func _load_game() -> void:
	cows.resize(SLOT_COUNT)
	cows.fill(-1)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	coins = int(data.get("coins", 200))
	tank_level = maxi(1, int(data.get("tank_level", 1)))
	stored_milk = maxi(0, int(data.get("stored_milk", 0)))
	carried_milk = maxi(0, int(data.get("carried_milk", 0)))
	player.carrying = carried_milk
	player.position = Vector2(float(data.get("player_x", 650)), float(data.get("player_y", 430)))
	var saved: Array = data.get("cows", [])
	for i in mini(saved.size(), SLOT_COUNT):
		cows[i] = clampi(int(saved[i]), -1, COW_NAMES.size() - 1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and player:
		_save_game()
		get_tree().quit()
