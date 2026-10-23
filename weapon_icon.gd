extends Control

const WEAPON_SHEET := preload("res://assets/weapons/weapon_actions_clean_9x4.png")
const WEAPON_REGIONS := {
	"ar15":Rect2(35,145,189,84),
	"m1911":Rect2(74,588,118,88),
	"shotgun":Rect2(28,820,189,61)
}

var weapon_id := "shotgun"

func _ready() -> void:
	size=Vector2(128,46)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var region: Rect2 = WEAPON_REGIONS.get(weapon_id,WEAPON_REGIONS.shotgun)
	var bounds:=Rect2(2,1,124,44)
	var scale_factor:=minf(bounds.size.x/region.size.x,bounds.size.y/region.size.y)
	if weapon_id=="m1911": scale_factor*=0.55
	var fitted_size:=region.size*scale_factor
	var fitted:=Rect2(bounds.position+(bounds.size-fitted_size)*0.5,fitted_size)
	draw_texture_rect_region(WEAPON_SHEET,fitted,region)
