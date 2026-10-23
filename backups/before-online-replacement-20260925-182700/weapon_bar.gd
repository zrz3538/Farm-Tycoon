extends Control

const WEAPON_TEXTURES := {
	"shotgun":preload("res://assets/third_party/curated/gun_shotgun.png"),
	"m4a1":preload("res://assets/third_party/curated/gun_m4a1.png"),
	"ar15":preload("res://assets/third_party/curated/gun_ar15.png"),
	"m700":preload("res://assets/third_party/curated/gun_m700.png"),
	"ak47":preload("res://assets/third_party/curated/gun_ak47.png"),
	"mp5":preload("res://assets/third_party/curated/gun_mp5.png"),
	"scarh":preload("res://assets/third_party/curated/gun_scarh.png"),
	"deagle":preload("res://assets/third_party/curated/gun_deagle.png"),
	"m249":preload("res://assets/third_party/curated/gun_m249.png")
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
	var texture: Texture2D=WEAPON_TEXTURES.get(id,WEAPON_TEXTURES.shotgun)
	draw_texture_rect(texture,Rect2(5,2,98,44),false)
	draw_string(ThemeDB.fallback_font,Vector2(108,21),str(game.WEAPONS[id].name),HORIZONTAL_ALIGNMENT_LEFT,134,15,Color("#fff0c2"))
	draw_string(ThemeDB.fallback_font,Vector2(108,39),"回家到武器库换枪",HORIZONTAL_ALIGNMENT_LEFT,134,12,Color("#b9cbbd"))
