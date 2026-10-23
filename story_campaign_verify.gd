extends SceneTree

var failures:=0
var game
var test_root:="C:/Users/Administrator/Documents/Codex/2026-09-24/kai/work/story-test-saves/"

func check(value:bool,text:String)->void:
	if value:print("PASS: ",text)
	else:failures+=1;push_error(text)

func _init()->void:call_deferred("run")

func run()->void:
	DirAccess.make_dir_recursive_absolute(test_root)
	game=load("res://main.tscn").instantiate();game.save_root=test_root;root.add_child(game)
	await process_frame
	game._show_new(1);game.name_input.text="Story Test";game._start_new()
	game.parasite_ever_discovered=true;game.blood_moon_defeated=true;game.coins=999999
	game._switch_scene(2,game.HouseWorld.ARMORY_POINT);game.house_world.armory_open=true;game.house_world.armory_sprite.texture=game.house_world.ARMORY_FRAMES[-1]
	game._show_armory();game._leave_armory();await create_timer(1.0).timeout
	check(not game.house_world.armory_open and not game.suspended,"Leaving armory plays the close animation")
	check(game.campaign_worlds.size()==30,"Thirty story maps are instantiated")
	var unique_titles:={}
	for stage in 30:
		var world=game.campaign_worlds[stage]
		unique_titles[world.get_title()]=true
		check(is_instance_valid(world.background) and not world.layout.is_empty(),"Map %02d has art and layout"%(stage+1))
		game._switch_scene(stage+3,world.get_entry_point()+Vector2(65,0));await process_frame
		check(game.scene_id==stage+3 and not world.enemies.is_empty(),"Map %02d starts its encounter"%(stage+1))
		while not world.enemies.is_empty():world.shoot_at(Vector2(world.enemies[0].pos),99999)
		check(world.can_exit(),"Map %02d opens after combat"%(stage+1))
	check(unique_titles.size()==30,"Every story map has a unique title")
	check(game.campaign_progress==30 and game.dynamite_owned,"Full campaign progression and eight-stick TNT reward")
	var final_world=game.campaign_worlds[29]
	game._show_story_note(29,final_world);check(29 in game.read_notes and game.suspended,"Readable notes persist");game._resume()
	game._try_destroy_heart(final_world)
	check(final_world.tnt_active and not game.parasite_heart_destroyed,"TNT ignition animation precedes destruction")
	await create_timer(2.6).timeout
	check(game.parasite_heart_destroyed and game.menu.visible,"TNT finishes in the completion screen")
	game._resume();var tab:=InputEventKey.new();tab.keycode=KEY_TAB;tab.pressed=true
	game._input(tab);check(game.tester_panel_open and game.menu.visible,"TAB opens tester menu")
	game._input(tab);check(not game.tester_panel_open and not game.menu.visible,"TAB closes tester menu")
	game.corn_world.enemies.clear();game.corn_world.spawn_attackers()
	check(game.corn_world.enemies.size()==4 and game.corn_world.enemies[0] is Dictionary,"Corn skeletons have animated combat state")
	print("FAILURES: ",failures);quit(failures)
