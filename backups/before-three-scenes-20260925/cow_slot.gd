extends Control

signal cow_dropped(from_index: int, to_index: int)
var slot_index := -1
var cow_level := -1
var atlas_texture: Texture2D
var game: Node
var phase := 0.0
var grazing := false
var label: Label

func setup(index: int, texture: Texture2D, owner_game: Node) -> void:
	slot_index = index
	atlas_texture = texture
	game = owner_game
	size = Vector2(170, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP
	label = Label.new()
	label.position = Vector2(0, 70)
	label.size = Vector2(170, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#f3eac7"))
	label.add_theme_color_override("font_shadow_color", Color("#33482c"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_cow(level: int, names: Array, traits: Array) -> void:
	cow_level = level
	label.text = "%s · %d\n%s" % [names[level], level + 1, traits[level]] if level >= 0 else ""
	label.tooltip_text = "%s\n%s" % [names[level], traits[level]] if level >= 0 else ""
	queue_redraw()

func _process(delta: float) -> void:
	if not game.playing or game.suspended:
		return
	phase += delta
	var next := fmod(phase + slot_index * 1.3, 5.0) > 2.6
	if grazing != next:
		grazing = next
		queue_redraw()

func _draw() -> void:
	for p in [Vector2(18, 66), Vector2(141, 42), Vector2(118, 76)]:
		draw_rect(Rect2(p, Vector2(2, 7)), Color("#4c763d"))
		draw_rect(Rect2(p + Vector2(4, 3), Vector2(2, 4)), Color("#b5c46a"))
	if cow_level >= 0:
		draw_rect(Rect2(44, 70, 87, 8), Color("#34513c", 0.32))
		var region := Rect2((cow_level % 4) * 128, (floori(cow_level / 4.0) + (8 if grazing else 0)) * 128, 128, 128)
		draw_texture_rect_region(atlas_texture, Rect2(39, -5, 96, 96), region)
	if game.can_manage_cows() and get_rect().has_point(get_parent().get_local_mouse_position()):
		draw_rect(Rect2(7, 5, 156, 88), Color("#efe0a6"), false, 2)

func _get_drag_data(_position: Vector2) -> Variant:
	if cow_level < 0 or not game.can_manage_cows():
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

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return game.can_manage_cows() and data is Dictionary and data.get("kind") == "cow" and data.get("from", -1) != slot_index

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
