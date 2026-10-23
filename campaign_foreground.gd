extends Node2D

var world: Node2D

func setup(owner_world: Node2D) -> void:
	world=owner_world
	z_index=8
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world) or world.layout.is_empty(): return
	var theme:=str(world.layout.get("theme","grave"))
	for raw in world.layout.get("props",[]):
		var prop:Dictionary=raw
		var p:=Vector2(float(prop.get("x",0)),float(prop.get("y",0)))
		var s:=float(prop.get("scale",1.0))
		match str(prop.get("kind","")):
			"tree": _tree_top(p,s,theme)
			"roof": _roof_top(p,theme)
			"shelf": _shelf_top(p)
			"pillar": _pillar_top(p)

func _tree_top(p:Vector2,s:float,theme:String) -> void:
	var leaf:=Color("#304e3c") if theme not in ["canyon","mine","tunnel"] else Color("#4a3430")
	for item in [[-28.0,-62.0,34.0],[8.0,-78.0,40.0],[36.0,-52.0,32.0],[-4.0,-40.0,40.0]]:
		var c:=p+Vector2(float(item[0]),float(item[1]))*s
		var r:=float(item[2])*s
		draw_rect(Rect2(c-Vector2(r,r),Vector2(r*2,r*2)),Color("#17242a"))
		draw_rect(Rect2(c-Vector2(r-6,r-6),Vector2((r-6)*2,(r-6)*2)),leaf)
		draw_rect(Rect2(c-Vector2(r-14,r-14),Vector2(r*0.9,r*0.55)),leaf.lightened(0.12))

func _roof_top(p:Vector2,theme:String) -> void:
	var roof:=Color("#40505a") if theme in ["greenhouse","canal"] else Color("#573842")
	draw_colored_polygon(PackedVector2Array([p+Vector2(-132,-116),p+Vector2(0,-210),p+Vector2(132,-116)]),Color("#18242b"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-122,-119),p+Vector2(0,-199),p+Vector2(122,-119)]),roof)
	for y in range(-180,-120,16): draw_line(p+Vector2(-80,y),p+Vector2(80,y),roof.lightened(0.1),4)

func _shelf_top(p:Vector2) -> void:
	draw_rect(Rect2(p+Vector2(-58,-112),Vector2(116,22)),Color("#18242b"))
	draw_rect(Rect2(p+Vector2(-52,-106),Vector2(104,15)),Color("#76553b"))

func _pillar_top(p:Vector2) -> void:
	draw_rect(Rect2(p+Vector2(-28,-130),Vector2(56,28)),Color("#1a252d"))
	draw_rect(Rect2(p+Vector2(-22,-124),Vector2(44,20)),Color("#858277"))
