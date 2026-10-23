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
	size = Vector2(145, 74)
	mouse_filter = Control.MOUSE_FILTER_STOP
	label = Label.new()
	label.position = Vector2(0, 56)
	label.size = Vector2(145, 17)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
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
	label.position.y = 32 if hovered else 56
	label.size.y = 40 if hovered else 17
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
	for p in [Vector2(12, 62), Vector2(132, 39), Vector2(112, 68)]:
		draw_rect(Rect2(p, Vector2(2, 7)), Color("#4c763d"))
		draw_rect(Rect2(p + Vector2(4, 3), Vector2(2, 4)), Color("#b5c46a"))
	if cow_level >= 0:
		draw_rect(Rect2(34, 62, 78, 7), Color("#34513c", 0.32))
		if cow_state == "parasite":
			_draw_parasite_cow()
		elif cow_state == "skeleton":
			_draw_skeleton()
		else:
			var sprite_index:=cow_level%11
			var region:=Rect2((sprite_index%4)*256,floori(sprite_index/4.0)*256,256,256)
			var chew:=sin(phase*3.2+slot_index)*2.0 if grazing else 0.0
			draw_set_transform(Vector2(72,30+chew),sin(phase*2.1+slot_index)*0.012,Vector2(1.0,0.97 if grazing else 1.0))
			draw_texture_rect_region(atlas_texture,Rect2(-48,-42,96,84),region)
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		if hovered:
			draw_rect(Rect2(4, 30, 137, 42), Color("#21352c", 0.92))
			draw_rect(Rect2(4, 30, 137, 42), Color("#ead58e"), false, 2)
	if game.can_manage_cows() and get_rect().has_point(get_parent().get_local_mouse_position()):
		draw_rect(Rect2(2, 2, 141, 70), Color("#efe0a6"), false, 2)

func _get_drag_data(_position: Vector2) -> Variant:
	if cow_level < 0 or cow_state != "normal" or not game.can_manage_cows():
		return null
	var holder := Control.new()
	var preview := TextureRect.new()
	var sprite := AtlasTexture.new()
	sprite.atlas = atlas_texture
	var sprite_index:=cow_level%11
	sprite.region = Rect2((sprite_index%4)*256,floori(sprite_index/4.0)*256,256,256)
	preview.texture = sprite
	preview.size = Vector2(96, 96)
	preview.position = Vector2(-48, -48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"kind": "cow", "from": slot_index}

func _draw_parasite_cow() -> void:
	var twitch:=sin(phase*8.0)*2.0
	var pulse:=1.0+sin(phase*5.0)*0.035
	draw_set_transform(Vector2(72,30+twitch),sin(phase*9.0)*0.025,Vector2(pulse,2.0-pulse))
	draw_texture_rect_region(atlas_texture,Rect2(-48,-42,96,84),Rect2(768,512,256,256))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

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
