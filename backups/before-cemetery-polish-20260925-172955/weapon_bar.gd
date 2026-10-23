extends Control

var game: Node

func _ready() -> void:
	size=Vector2(1256,48)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(game) and game.playing: queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game.playing: return
	if game.scene_id==2 or (game.scene_id==0 and not game.blood_moon.is_active()): return
	var cell:=132.0
	for i in game.WEAPON_ORDER.size():
		var id: String=game.WEAPON_ORDER[i]
		var owned: bool=bool(game.owned_weapons.get(id,false))
		var selected: bool=bool(game.shotgun_equipped) and str(game.weapon_id)==id
		var x: float=float(i)*cell
		draw_rect(Rect2(x,0,124,44),Color("#17231e",0.90))
		draw_rect(Rect2(x,0,124,44),Color("#ffe189") if selected else Color("#52665a"),false,3 if selected else 1)
		draw_rect(Rect2(x+8,11,55 if id not in ["m700","m249"] else 72,5),Color("#c2c8c0") if owned else Color("#4b514d"))
		draw_rect(Rect2(x+17,16,28,7),Color("#765338") if owned else Color("#3c403e"))
		draw_string(ThemeDB.fallback_font,Vector2(x+7,38),"%d %s" % [i+1,game.WEAPONS[id].name],HORIZONTAL_ALIGNMENT_LEFT,112,12,Color("#fff0c2") if owned else Color("#777b75"))
