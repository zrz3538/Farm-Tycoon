extends PanelContainer

signal cow_dropped(from_index: int, to_index: int)

var slot_index := -1
var cow_level := -1
var atlas_texture: Texture2D
var game: Node
var image: TextureRect
var label: Label
var grass_left: ColorRect
var grass_right: ColorRect
var anim_time := 0.0

func setup(index: int, texture: Texture2D, owner_game: Node) -> void:
	slot_index = index
	atlas_texture = texture
	game = owner_game
	custom_minimum_size = Vector2(170, 100)
	size = custom_minimum_size
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(stack)
	image = TextureRect.new()
	image.custom_minimum_size = Vector2(94, 72)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(image)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#342b22"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(label)
	grass_left = _grass(Vector2(44, 69))
	grass_right = _grass(Vector2(119, 72))

func _grass(pos: Vector2) -> ColorRect:
	var blade := ColorRect.new()
	blade.color = Color("#477c35")
	blade.position = pos
	blade.size = Vector2(4, 15)
	blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blade)
	return blade

func set_cow(level: int, names: Array, incomes: Array) -> void:
	cow_level = level
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#86c266", 0.78) if level < 0 else Color("#d7c986", 0.92)
	style.border_color = Color("#4f813f") if level < 0 else Color("#756039")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	if level < 0:
		image.texture = null
		label.text = "空草地"
		grass_left.show()
		grass_right.show()
	else:
		image.texture = _sprite_for_level(level)
		label.text = "%s  Lv.%d  +%d奶/秒" % [names[level], level + 1, incomes[level]]
		grass_left.show()
		grass_right.show()

func _process(delta: float) -> void:
	anim_time += delta
	if cow_level >= 0:
		# Slow head-down grazing rhythm with tiny grass movement.
		var phase := anim_time * 2.2 + slot_index * 0.7
		image.position.y = 3.0 + maxf(0.0, sin(phase)) * 4.0
		image.rotation = sin(phase * 0.5) * 0.012
	grass_left.rotation = sin(anim_time * 2.0 + slot_index) * 0.16
	grass_right.rotation = -sin(anim_time * 1.7 + slot_index) * 0.14

func _sprite_for_level(level: int) -> AtlasTexture:
	var sprite := AtlasTexture.new()
	sprite.atlas = atlas_texture
	sprite.region = Rect2((level % 4) * 128, floori(level / 4.0) * 128, 128, 128)
	return sprite

func _get_drag_data(_position: Vector2) -> Variant:
	if cow_level < 0:
		return null
	if not game.can_manage_cows():
		game.show_message("先让牛仔走到牧场入口的蓝色交互点附近")
		return null
	var preview := TextureRect.new()
	preview.texture = _sprite_for_level(cow_level)
	preview.custom_minimum_size = Vector2(110, 110)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_drag_preview(preview)
	return {"kind": "cow", "from": slot_index}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return game.can_manage_cows() and typeof(data) == TYPE_DICTIONARY and data.get("kind", "") == "cow" and int(data.get("from", -1)) != slot_index

func _drop_data(_position: Vector2, data: Variant) -> void:
	cow_dropped.emit(int(data["from"]), slot_index)
