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
	game.coins=3000000
	game._switch_scene(2,game.HouseWorld.ARMORY_POINT); game._try_interact(true)
	check(game.suspended and game.menu.visible,"Indoor armory interaction")
	game._buy_weapon("ar15")
	check(game.owned_weapons.ar15 and game.weapon_id=="ar15" and game.player.weapon_id=="ar15","AR15 purchase and equip")
	game._equip_weapon("shotgun")
	var number_key:=InputEventKey.new(); number_key.keycode=KEY_2; number_key.pressed=true
	game._input(number_key)
	check(game.weapon_id=="shotgun","Number keys cannot switch weapons outside the armory")
	var wheel:=InputEventMouseButton.new(); wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN; wheel.pressed=true
	game._input(wheel)
	check(game.weapon_id=="shotgun","Mouse wheel cannot switch weapons outside the armory")
	game._bullet_tracer(Vector2(640,360),Vector2(700,360))
	var ray_line: Line2D
	for child in game.effects_layer.get_children():
		if child is Line2D: ray_line=child
	check(is_instance_valid(ray_line) and ray_line.points[1].x>=1280.0,"Bullet visual is a ray to the screen edge")
	game._buy_weapon("m1911")
	check(game.owned_weapons.m1911,"1911 purchase")
	check(game.WEAPON_ORDER.size()==3 and game.owned_weapons.shotgun,"Three-weapon armory with starting shotgun")
	game._resume()
	game._equip_weapon("shotgun"); game.weapon_ammo.shotgun=2; game._switch_scene(2,Vector2(600,450))
	game.last_shot_msec=-10000; check(game._fire_weapon(Vector2(900,400)),"First shotgun shell fires")
	game.last_shot_msec=-10000; game._fire_weapon(Vector2(900,400)); game.last_shot_msec=-10000
	check(not game._fire_weapon(Vector2(900,400)) and "按 R" in game.message_label.text,"Empty magazine blocks fire and prompts reload")
	game._start_reload(); game._finish_reload(); check(game.weapon_ammo.shotgun==5,"Five-shell pump shotgun reloads from infinite reserve")
	game._equip_weapon("ar15"); game._cycle_fire_mode(); check(game.weapon_modes.ar15=="burst","B cycles AR15 to burst")
	game._equip_weapon("m1911")
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
	await create_timer(0.8).timeout
	check(game.suspended and game.menu.visible,"Destroying the heart opens the full completion screen")
	game._enter_free_mode(); check(game.free_mode and game._parasite_count()==0 and game._skeleton_count()==0,"Completion can enter parasite-free mode")
	check(game._save_game(),"Campaign save writes successfully")
	game.weapon_id="shotgun"; game.campaign_progress=0; game.parasite_heart_destroyed=false; game._continue_game(1)
	check(game.weapon_id=="m1911" and game.campaign_progress==6 and game.parasite_heart_destroyed,"Campaign and weapons persist in save")
	game._resume()
	game.free_mode=false; game.day_count=4; game.day4_wave_spawned=false; game.first_skeleton_encounter_completed=false; game.cows[0]=0; game.cow_states[0]="skeleton"; game._switch_scene(2,Vector2(600,600)); game._switch_scene(1,Vector2(700,500))
	check(game.day4_wave_spawned and not game.corn_world.enemies.is_empty(),"Day four house exit spawns the one-time skeleton wave")
	while not game.corn_world.enemies.is_empty(): game.corn_world.shoot_at(game.corn_world.enemies[0])
	check(game.first_skeleton_encounter_completed,"Surviving the first skeleton wave is remembered")
	game._switch_scene(2,Vector2(600,600)); game._switch_scene(1,Vector2(700,500)); check(game.corn_world.enemies.is_empty(),"Cleared day-four wave never respawns")
	game.take_damage(70,"test"); var hurt: float=game.health; game._process(2.0); check(game.health>hurt,"Fast breathing regeneration restores health")
	game.coins=10000; game._switch_scene(5,Vector2(500,500)); game.combat_defeat("test")
	check(game.scene_id==2 and game.player.position==game.HouseWorld.WAKE_POINT and game.coins<10000,"Later combat death respawns in bed")
	game._switch_scene(6,Vector2(500,500)); game._quick_home()
	check(game.scene_id==2 and game.player.position==game.HouseWorld.WAKE_POINT+Vector2(0,46),"H fast travel returns to the house and bed area")
	var tab_key:=InputEventKey.new(); tab_key.keycode=KEY_TAB; tab_key.pressed=true
	game._input(tab_key); check(game.suspended and game.menu.visible,"Pressing TAB opens tester panel immediately")
	game._spawn_tester_target()
	check(game.scene_id==3 and game.campaign_worlds[0].enemies.size()==1 and int(game.campaign_worlds[0].enemies[0].hp)==1600,"Tester panel summons a high-health hit-effect target")
	print("FAILURES: ",failures)
	quit(failures)
