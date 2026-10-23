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

var weapon_id := "shotgun"

func _ready() -> void:
	size=Vector2(128,46)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var texture: Texture2D = WEAPON_TEXTURES.get(weapon_id,WEAPON_TEXTURES.shotgun)
	draw_texture_rect(texture,Rect2(2,1,124,44),false)
