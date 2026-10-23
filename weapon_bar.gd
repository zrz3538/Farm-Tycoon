extends Control

const WEAPON_SHEET := preload("res://assets/weapons/weapon_actions_clean_9x4.png")
const WEAPON_REGIONS := {
	"ar15":Rect2(35,145,189,84),
	"m1911":Rect2(74,588,118,88),
	"shotgun":Rect2(28,820,189,61)
}

var game: Node

func _ready() -> void:
	size=Vector2(248,54)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(game) and game.playing: queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game.playing: return
	if game.scene_id==2 or (game.scene_id==0 and not game.blood_moon.is_active()): return
	var id: String=str(game.weapon_id)
	var selected: bool=bool(game.shotgun_equipped)
	draw_rect(Rect2(0,0,248,48),Color("#17231e",0.94))
	draw_rect(Rect2(0,0,248,48),Color("#ffe189") if selected else Color("#52665a"),false,2)
	var region: Rect2=WEAPON_REGIONS.get(id,WEAPON_REGIONS.shotgun)
	var bounds:=Rect2(5,2,98,44)
	var scale_factor:=minf(bounds.size.x/region.size.x,bounds.size.y/region.size.y)
	if id=="m1911": scale_factor*=0.55
	var fitted_size:=region.size*scale_factor
	var fitted:=Rect2(bounds.position+(bounds.size-fitted_size)*0.5,fitted_size)
	draw_texture_rect_region(WEAPON_SHEET,fitted,region)
	draw_string(ThemeDB.fallback_font,Vector2(108,21),str(game.WEAPONS[id].name),HORIZONTAL_ALIGNMENT_LEFT,134,15,Color("#fff0c2"))
	draw_string(ThemeDB.fallback_font,Vector2(108,39),"回家到武器库换枪",HORIZONTAL_ALIGNMENT_LEFT,134,12,Color("#b9cbbd"))
