extends SceneTree

var failures := 0
var game
var test_root := "C:/Users/Administrator/Documents/Codex/2026-09-24/kai/work/campaign-test-saves/"

func _init() -> void:
	call_deferred("run")

func check(value: bool, text: String) -> void:
	if value: print("PASS: ",text)
	else:
		failures += 1
		push_error(text)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	game=load("res://main.tscn").instantiate()
	game.save_root=test_root
	root.add_child(game)
	await process_frame
	game._show_new(1); game.name_input.text="战役测试"; game._start_new()
	game.coins=500000
	game._switch_scene(1,game.CornWorld.ARMORY_POINT); game._try_interact(true)
	check(game.suspended and game.menu.visible,"Cornfield armory interaction")
	game._buy_weapon("m4a1")
	check(game.owned_weapons.m4a1 and game.weapon_id=="m4a1" and game.player.weapon_id=="m4a1","M4A1 purchase and equip")
	game._buy_weapon("ar15"); game._buy_weapon("m700")
	check(game.owned_weapons.ar15 and game.owned_weapons.m700,"AR-15 and M700 purchase")
	game._resume()
	game.day_count=6; game._switch_scene(0,Vector2(650,430)); await process_frame
	check(game.blood_moon.is_active() and game.blood_moon.boss_hp>0,"Day six blood moon boss")
	game.blood_moon.boss_hp=1
	var boss_hit=game.blood_moon.shoot_at(game.blood_moon.boss_position,260)
	game._handle_combat_hit(boss_hit)
	check(game.blood_moon_defeated and game.coins>=100000,"Blood moon defeat unlock and reward")
	game._switch_scene(3,Vector2(180,625)); await process_frame
	check(game.campaign_worlds[0].enemies.size()==4 and game.scene_id==3,"First new campaign scene")
	for stage in 6:
		game._switch_scene(stage+3,Vector2(250,620)); await process_frame
		var world=game.campaign_worlds[stage]
		check(world.stage_index==stage and not world.enemies.is_empty(),"Unique stage %d combat wave" % (stage+1))
		while not world.enemies.is_empty():
			var pos: Vector2=world.enemies[0].pos
			var hit=world.shoot_at(pos,9999)
			game._handle_combat_hit(hit)
	check(game.campaign_progress==6 and game.dynamite_owned,"Six stages and dynamite reward")
	game._switch_scene(8,game.CampaignWorld.HEART_POINT+Vector2(0,80))
	game.player.position=game.CampaignWorld.HEART_POINT
	game._try_interact(true)
	check(game.parasite_heart_destroyed,"Dynamite destroys parasite heart")
	check(game._save_game(),"Campaign save writes successfully")
	game.weapon_id="shotgun"; game.campaign_progress=0; game.parasite_heart_destroyed=false; game._continue_game(1)
	check(game.weapon_id=="m700" and game.campaign_progress==6 and game.parasite_heart_destroyed,"Campaign and weapons persist in save")
	game._resume()
	game._switch_scene(1,Vector2(700,500)); game.corn_world.enemies.clear(); game.first_skeleton_encounter_completed=false; game.corn_world.spawn_attackers()
	while not game.corn_world.enemies.is_empty(): game.corn_world.shoot_at(game.corn_world.enemies[0])
	check(game.first_skeleton_encounter_completed,"Surviving the first skeleton wave is remembered")
	game.corn_world.spawn_attackers(); game.corn_world.enemies[0]=game.player.position; game.corn_world._process(0.0)
	check(game.scene_id==2 and game.player.position==game.HouseWorld.WAKE_POINT,"Later skeleton contact respawns in bed")
	game.coins=10000; game._switch_scene(5,Vector2(500,500)); game.combat_defeat("test")
	check(game.scene_id==2 and game.player.position==game.HouseWorld.WAKE_POINT and game.coins<10000,"Later combat death respawns in bed")
	print("FAILURES: ",failures)
	quit(failures)
