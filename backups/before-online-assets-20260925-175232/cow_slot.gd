extends Control

signal cow_dropped(from_index: int, to_index: int)
var slot_index := -1
var cow_level := -1
var atlas_texture: Texture2D
var game: Node
var phase := 0.0
var grazing := false
var label: Label
var milk_rate := 0
var cow_trait: Dictionary = {}
var hovered := false
var cow_state := "empty"

func setup(index: int, texture: Texture2D, owner_game: Node) -> void:
	slot_index = index
	atlas_texture = texture
	game = owner_game
	size = Vector2(170, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP
	label = Label.new()
	label.position = Vector2(0, 78)
	label.size = Vector2(170, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#f3eac7"))
	label.add_theme_color_override("font_shadow_color", Color("#33482c"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_cow(level: int, names: Array, milk_values: Array, individual_trait: Dictionary, state: String) -> void:
	cow_level = level
	cow_state = state
	cow_trait = individual_trait.duplicate(true)
	milk_rate = int(milk_values[level]) if level >= 0 else 0
	if str(cow_trait.get("kind", "")) == "milk":
		milk_rate = roundi(milk_rate * (1.0 + float(cow_trait.get("value", 0.0))))
	_update_label(names)
	queue_redraw()

func _process(delta: float) -> void:
	if not game.playing or game.suspended:
		return
	phase += delta
	var next := fmod(phase + slot_index * 1.3, 5.0) > 2.6
	if grazing != next:
		grazing = next
		queue_redraw()

func _set_hover(value: bool) -> void:
	hovered = value and cow_level >= 0
	_update_label(game.COW_NAMES)
	queue_redraw()

func _update_label(names: Array) -> void:
	if cow_level < 0:
		label.text = ""
		return
	label.position.y = 52 if hovered else 78
	label.size.y = 46 if hovered else 20
	if cow_state == "parasite":
		label.text = "寄生虫牛"
	elif cow_state == "skeleton":
		label.text = "牛骷髅"
	else:
		label.text = "%s · %d" % [names[cow_level], cow_level + 1]
	if hovered:
		if cow_state == "parasite":
			label.text += "\n不产奶\n无属性"
		elif cow_state == "skeleton":
			label.text += "\n已死亡\n无法清理"
		else:
			label.text += "\n产奶 %d/秒\n%s" % [milk_rate, _trait_text()]

func _trait_text() -> String:
	if cow_trait.is_empty():
		return "无特殊属性"
	var kind := str(cow_trait.get("kind", ""))
	var value := float(cow_trait.get("value", 0.0))
	if kind == "prestige":
		return "%s：转生勋章+1" % cow_trait.get("name", "轮回印记")
	var effect_names := {"milk":"产奶", "sale":"售价", "capacity":"容量", "upgrade":"升级费", "lottery":"彩票费", "task":"任务奖励", "recycle":"回收价"}
	var sign := "-" if kind in ["upgrade", "lottery"] else "+"
	return "%s：%s%s%d％" % [cow_trait.get("name", "特性"), effect_names.get(kind, kind), sign, roundi(value * 100.0)]

func _draw() -> void:
	for p in [Vector2(18, 66), Vector2(141, 42), Vector2(118, 76)]:
		draw_rect(Rect2(p, Vector2(2, 7)), Color("#4c763d"))
		draw_rect(Rect2(p + Vector2(4, 3), Vector2(2, 4)), Color("#b5c46a"))
	if cow_level >= 0:
		draw_rect(Rect2(44, 70, 87, 8), Color("#34513c", 0.32))
		if cow_state == "parasite":
			_draw_parasite_cow()
		elif cow_state == "skeleton":
			_draw_skeleton()
		else:
			var region := Rect2((cow_level % 4) * 128, (floori(cow_level / 4.0) + (8 if grazing else 0)) * 128, 128, 128)
			draw_texture_rect_region(atlas_texture, Rect2(39, -5, 96, 96), region)
		if hovered:
			draw_rect(Rect2(12, 50, 146, 49), Color("#21352c", 0.88))
			draw_rect(Rect2(12, 50, 146, 49), Color("#ead58e"), false, 2)
	if game.can_manage_cows() and get_rect().has_point(get_parent().get_local_mouse_position()):
		draw_rect(Rect2(7, 5, 156, 88), Color("#efe0a6"), false, 2)

func _get_drag_data(_position: Vector2) -> Variant:
	if cow_level < 0 or cow_state != "normal" or not game.can_manage_cows():
		return null
	var holder := Control.new()
	var preview := TextureRect.new()
	var sprite := AtlasTexture.new()
	sprite.atlas = atlas_texture
	sprite.region = Rect2((cow_level % 4) * 128, floori(cow_level / 4.0) * 128, 128, 128)
	preview.texture = sprite
	preview.size = Vector2(96, 96)
	preview.position = Vector2(-48, -48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"kind": "cow", "from": slot_index}

func _draw_parasite_cow() -> void:
	var twitch := roundi(sin(phase * 7.0) * 2.0)
	draw_rect(Rect2(42,24+twitch,76,42),Color("#1c1118"))
	draw_rect(Rect2(33,35+twitch,28,34),Color("#351723"))
	draw_rect(Rect2(96,30+twitch,35,31),Color("#2a121d"))
	# Torn flank with exposed ribs and pulsing egg sacs.
	draw_rect(Rect2(55,31+twitch,38,29),Color("#541b2c"))
	for x in range(59,91,8):
		draw_arc(Vector2(x,43+twitch),10,-PI/2.0,PI/2.0,7,Color("#d8ccb0"),3)
	for i in 3:
		var sac := Vector2(48+i*25,25+twitch+sin(phase*5.0+i)*3.0)
		draw_circle(sac,7,Color("#7f2038")); draw_circle(sac+Vector2(2,-2),2,Color("#d9b54f"))
	# Uneven eyes and split jaw.
	draw_rect(Rect2(104,37+twitch,7,7),Color("#f4d25c")); draw_rect(Rect2(121,35+twitch,5,9),Color("#e34e55"))
	draw_rect(Rect2(101,51+twitch,30,6),Color("#0e0b0d"))
	for x in range(104,129,6): draw_colored_polygon(PackedVector2Array([Vector2(x,51+twitch),Vector2(x+4,51+twitch),Vector2(x+2,57+twitch)]),Color("#e7dfc5"))
	for x in [47,67,91,110]: draw_rect(Rect2(x,60+twitch,7,18),Color("#1b1118"))
	for i in 7:
		var start := Vector2(46+i*16,30+twitch)
		var bend := Vector2(start.x-11+(i%2)*20,start.y-15-i%3*5+sin(phase*8+i)*5)
		draw_line(start,bend,Color("#7f1f39"),5)
		draw_line(start,bend,Color("#c03a4e"),2)
		draw_circle(bend,4,Color("#d55258")); draw_circle(bend+Vector2(1,-1),1,Color("#f1d25c"))
	for i in 6:
		var wx := 48.0+i*20.0+sin(phase*5.0+i)*4.0
		draw_arc(Vector2(wx,68),8,0,PI,8,Color("#b93b4e"),3)
	# Falling strands under the body.
	for i in 4:
		var drip_x := 58.0+i*17.0
		draw_line(Vector2(drip_x,59+twitch),Vector2(drip_x+sin(phase*6+i)*4.0,73+twitch+i%2*6),Color("#741b32"),3)

func _draw_skeleton() -> void:
	draw_rect(Rect2(38,58,90,8),Color("#263529",0.45))
	draw_line(Vector2(45,50),Vector2(108,50),Color("#e5dfc1"),7)
	for x in range(54,101,12):
		draw_arc(Vector2(x,52),12,0,PI,8,Color("#d8d0b1"),4)
	draw_rect(Rect2(104,37,29,23),Color("#e8e1c6"))
	draw_rect(Rect2(111,43,5,5),Color("#2b2928")); draw_rect(Rect2(124,43,5,5),Color("#2b2928"))
	for x in [48,78,105]: draw_line(Vector2(x,52),Vector2(x-5,72),Color("#d8d0b1"),5)
	for i in 5:
		var p := Vector2(45+i*19+sin(phase*4+i)*5,72-i%2*9)
		draw_arc(p,7,0,PI,8,Color("#8f2f43"),3)

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return cow_state != "skeleton" and game.can_manage_cows() and data is Dictionary and data.get("kind") == "cow" and data.get("from", -1) != slot_index

func _drop_data(_position: Vector2, data: Variant) -> void:
	cow_dropped.emit(int(data["from"]), slot_index)

func play_merge_animation() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.24, 0.78), 0.08)
	tween.tween_property(self, "scale", Vector2(0.86, 1.22), 0.10)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_delete_animation() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", 0.18, 0.12)
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.12)
	tween.tween_property(self, "modulate", Color("#ffcf91"), 0.12)
	await tween.finished
	var vanish := create_tween()
	vanish.set_parallel(true)
	vanish.tween_property(self, "scale", Vector2(0.05, 0.05), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	vanish.tween_property(self, "modulate:a", 0.0, 0.22)
	await vanish.finished
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
