extends SceneTree
var game: Node
var failures := 0
const TEST_ROOT := "C:/Users/Administrator/Documents/Codex/2026-09-24/kai/work/verify-saves/"
func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error(what)
	else:
		print("PASS: " + what)

func _initialize() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(TEST_ROOT + filename)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	game = load("res://main.tscn").instantiate()
	game.save_root = TEST_ROOT
	root.add_child(game)
	await process_frame
	check(not game.playing and game.menu.visible, "Title menu before gameplay")
	check(game.sounds.bgm.stream != null and game.sounds.sounds.size() >= 11, "BGM and sound effects generated")
	await capture("title.png")
	game._show_new(3)
	game.name_input.text = "青禾牧场"
	game._start_new()
	check(game.playing and game.farm_name == "青禾牧场", "Named new save")
	check(game.coins == 500 and game.cows.count(-1) == 12, "Fresh economy")
	game.player.position = Vector2(815, 430)
	game._buy_cow()
	check(game.coins == 500, "Purchasing blocked away from truck")
	game.player.position = Vector2(1015, 492)
	game.player.facing = Vector2.UP
	game._try_interact(true)
	await mouse_button(Vector2(900, 450), true)
	await mouse_button(Vector2(900, 450), false)
	check(game.coins == 400 and game.cows[0] == 0 and game.cows[1] == 0, "Truck buys twice at fixed 50")
	check(game.player.position.distance_to(game.FarmWorld.TRUCK_POINT) > 130, "Enlarged interaction range")
	game.player.position = Vector2(50, 650)
	game._on_cow_dropped(0, 1)
	check(game.cows[0] == -1 and game.cows[1] == 1, "Cow merge works anywhere")
	game.cows[0] = 1
	game.cow_states[0] = "normal"
	game._refresh_all()
	await mouse_button(Vector2(130, 115), true)
	await mouse_move(Vector2(160, 125))
	await mouse_move(Vector2(320, 115))
	await mouse_button(Vector2(320, 115), false)
	check(game.cows[0] == -1 and game.cows[1] == 2, "Actual pointer drag merges cows")
	check(game.effects_layer.get_child_count() > 0, "Merge celebration appears")
	game.cows[0] = 5
	game.cows[1] = 2
	game.cow_states[0] = "normal"
	game.cow_states[1] = "normal"
	game._on_cow_dropped(0, 1)
	check(game.cows[0] == 2 and game.cows[1] == 5, "Different cow levels swap positions")
	game.player.position = Vector2(1000, 400)
	game._on_cow_dropped(1, 2)
	check(game.cows[1] == -1 and game.cows[2] == 5, "Remote cow move works")
	game.stored_milk = game._tank_capacity() - 1
	game._produce_milk()
	game._produce_milk()
	check(game.stored_milk == game._tank_capacity(), "Tank full does not overflow")
	game.player.position = Vector2(628, 650)
	game.player.facing = Vector2.UP
	game._try_interact(true)
	check(game.carried_milk == 100 and game.stored_milk == 0, "Take all milk")
	game.player.position = Vector2(1090, 678)
	var before_sale: int = game.coins
	game._try_interact(false)
	var after_sale: int = game.coins
	check(game.carried_milk == 0 and after_sale > before_sale, "Sell all milk with restrained economy")
	game.player.position = Vector2(198, 685)
	game.player.facing = Vector2.DOWN
	var upgrade_cost: int = game._tank_upgrade_cost()
	game._try_interact(true)
	check(game.tank_level == 2 and game.coins == after_sale - upgrade_cost, "Barn upgrade uses scaling cost")
	var saved_coins: int = game.coins
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	var before: int = game.stored_milk
	game._produce_milk()
	check(game.stored_milk == before and not game.player.is_physics_processing(), "Pause stops game")
	await capture("pause.png")
	game._resume()
	check(game._save_game(), "Save succeeds")
	game.coins = 999
	game._continue_game(3)
	check(game.coins == saved_coins and game.tank_level == 2 and game.farm_name == "青禾牧场", "Reload restores independent slot")
	game._show_new(2)
	game.name_input.text = "第二牧场"
	game._start_new()
	check(game.coins == 500 and game.cows.count(-1) == 12, "Second slot is independent")
	game._continue_game(3)
	check(game.coins == saved_coins, "First slot preserved")
	game.coins = int(game.LOTTERY_TIERS[0].price)
	game.cows.fill(-1)
	game.player.position = game.FarmWorld.LOTTERY_POINT + Vector2(0, 40)
	game._show_lottery()
	await capture("lottery.png")
	check(game.suspended and game.menu.visible, "Lottery interaction opens the three-tier ticket menu")
	game._play_lottery(0)
	var prize_index: int = game.cows.find_custom(func(level): return level > 0)
	check(game.coins == 0 and prize_index >= 0 and game.cows[prize_index] >= 1 and game.cows[prize_index] <= 7, "Basic ticket uses its own prize pool")
	game._resume()
	var prize_level: int = game.cows[prize_index]
	var expected_refund := roundi(game.BUY_PRICE * pow(1.72, prize_level) * 0.30 * (1.0 + game._cow_bonus("recycle")))
	game._toggle_shotgun()
	check(game.shotgun_equipped and game.player.shotgun_equipped, "X-mode equips shotgun")
	for child in game.effects_layer.get_children():
		child.queue_free()
	game.message_label.hide()
	game.player.position = Vector2(800, 450)
	game.player.fire_toward(Vector2(1040, 420))
	await capture("gun.png")
	var cow_point: Vector2 = game.slots[prize_index].global_position + Vector2(80, 50)
	await mouse_button(cow_point, true)
	await mouse_button(cow_point, false)
	await create_timer(0.7).timeout
	check(game.cows[prize_index] == -1 and game.coins == expected_refund, "Shotgun recycles cow for 30 percent")
	game._toggle_shotgun()
	for i in range(12):
		game.cows[i] = i
		game.cow_states[i] = "normal"
	game.player.position = Vector2(815, 420)
	game.stored_milk = game._tank_capacity() / 2
	game._refresh_all()
	await process_frame
	await process_frame
	check(game.get_node("FarmWorld/TankLiquid").last_amount == game.stored_milk, "Tank liquid follows stored milk")
	game.message_label.hide()
	await capture("game.png")
	for i in range(12):
		game.cows[i] = 17 + i if 17 + i < game.COW_NAMES.size() else -1
		game.cow_states[i] = "normal" if game.cows[i] >= 0 else "empty"
	game._refresh_all()
	await process_frame
	await process_frame
	await capture("new-cows.png")
	check(game.COW_NAMES.size() == 29 and game.COW_MILK.size() == 29 and game.TRAIT_TEMPLATES.size() == 8, "Ten more cows and individual trait pool are available")
	game.cow_traits[0] = {"kind":"milk", "name":"高产", "value":0.12}
	game.cow_traits[1] = {}
	game._refresh_all()
	await mouse_move(Vector2(130,115))
	check("产奶" in game.slots[0].label.text and "高产" in game.slots[0].label.text, "Milk speed and individual trait appear only on hover")
	await mouse_move(Vector2(900,450))
	check(not "产奶" in game.slots[0].label.text and not "产量" in game.tank_label.text, "Cow details and HUD production stay hidden otherwise")
	await mouse_move(Vector2(130,115))
	await capture("cow-hover.png")
	game._save_game()
	game.cow_traits[0] = {}
	game._continue_game(3)
	check(str(game.cow_traits[0].get("name", "")) == "高产", "Individual cow traits persist in the save")
	game._switch_scene(0,Vector2(1256,420))
	await process_frame
	await process_frame
	check(game.scene_id == 1 and not game.slots[0].visible, "Walking through the farm right edge enters the cornfield")
	await capture("cornfield.png")
	game.player.position = game.CornWorld.HOUSE_POINT + Vector2(0,80)
	game.player.facing = Vector2.UP
	game._try_interact(false)
	check(game.scene_id == 2, "House door interaction enters the interior")
	await capture("house.png")
	game._try_interact(false)
	check(game.scene_id == 1, "Interior door interaction returns outside")
	game._switch_scene(0,Vector2(800,430))
	var rolls_valid := true
	for tier_index in game.LOTTERY_TIERS.size():
		var tier: Dictionary = game.LOTTERY_TIERS[tier_index]
		for i in 500:
			var rolled: int = game._roll_lottery_level(tier_index)
			if rolled < int(tier.min) or rolled > int(tier.max):
				rolls_valid = false
				break
	check(rolls_valid, "All three weighted lottery pools stay within their tier ranges")
	game.cows.fill(-1)
	for i in game.SLOT_COUNT:
		game.cow_traits[i] = {}
		game.cow_states[i] = "empty"
	game.task_system.tasks.clear()
	game.task_system.tasks.append({"kind":"buy", "title":"测试任务", "target":1, "progress":0, "reward":321, "stars":2})
	game.task_system.tasks.append({"kind":"merge", "title":"合成", "target":2, "progress":0, "reward":10, "stars":1})
	game.task_system.tasks.append({"kind":"sell", "title":"出售", "target":2, "progress":0, "reward":10, "stars":1})
	game._advance_task("buy")
	var task_coins: int = game.coins
	game._claim_task(0)
	check(game.coins == task_coins + 321 and game.task_system.task_stars == 2, "Task progress and claim rewards work")
	await capture("tasks.png")
	game.cows.fill(-1)
	game.cows[0] = game.COW_NAMES.size() - 1
	game.cow_states[0] = "normal"
	game.coins = 200000000
	game.task_system.task_stars = 5
	var reward: int = game._prestige_reward()
	game._show_prestige()
	await capture("prestige.png")
	game._do_prestige()
	check(game.prestige_count == 1 and game.prestige_medals == reward and game.cows.count(-1) == 12, "Prestige resets the run and awards permanent medals")
	game.cows[0] = 0
	game.cow_states[0] = "normal"
	check(game._milk_per_second() == roundi(game.COW_MILK[0] * (1.0 + reward * 0.12)), "Prestige medal production bonus applies")
	var max_task_reward := 0
	for template in game.task_system.TEMPLATES:
		max_task_reward = maxi(max_task_reward, int(template.reward))
	check(max_task_reward <= 12000, "Base task rewards are capped at 12000")
	game.cows.fill(-1)
	for i in game.SLOT_COUNT:
		game.cow_traits[i] = {}
		game.cow_states[i] = "empty"
	game.day_count = 3
	game.time_of_day = 20.0
	game.night_warning_shown = false
	game.parasite_purchase_count = 0
	game.parasite_purchase_target = 3
	game.coins = 1000
	game._switch_scene(0,game.FarmWorld.TRUCK_POINT)
	for i in 3:
		game._buy_cow()
	check(game._parasite_count() == 1 and game.cow_traits[game.cow_states.find("parasite")].is_empty(), "From day three, the third-to-sixth cat-cow purchase guarantees a traitless parasite cow")
	game.stored_milk = 50
	game.milk_contaminated = true
	game._take_milk()
	game._sell_milk()
	check(game.market_closed_day == 4, "Selling parasite milk schedules the market to close the next day")
	game._process(0.0)
	check(game.night_overlay.color.a > 0.0 and "DAY 3" in game.day_label.text, "Night darkness and DAY counter are visible")
	for child in game.effects_layer.get_children(): child.queue_free()
	game.message_label.hide()
	game._refresh_all()
	await process_frame
	await capture("parasite-night.png")
	for i in range(3,6):
		game.cows[i] = 1
		game.cow_states[i] = "normal"
	game._switch_scene(2,game.HouseWorld.BED_POINT)
	game._try_interact(false)
	check(game.day_count == 4 and game.time_of_day == 6.0 and game.scene_id == 2 and game.player.position == game.HouseWorld.WAKE_POINT, "Sleeping advances the day and wakes the cowboy beside the bed")
	check(game._skeleton_count() >= 1 and game._skeleton_count() <= 3, "An untreated parasite creates one to three permanent cow skeletons overnight")
	game.carried_milk = 10
	game.player.carrying = 10
	game._switch_scene(0,game.FarmWorld.MARKET_POINT)
	var closed_market_coins: int = game.coins
	game._try_interact(false)
	check(game.coins == closed_market_coins and game.message_label.text == "关门了", "The market refuses interaction throughout the day after parasite milk is sold")
	var skeleton_index: int = game.cow_states.find("skeleton")
	var skeleton_level: int = game.cows[skeleton_index]
	game._on_cow_dropped(skeleton_index,11)
	check(game.cows[skeleton_index] == skeleton_level and game.cow_states[skeleton_index] == "skeleton", "Cow skeletons cannot be moved or merged")
	for i in range(5):
		game.cows[i] = maxi(0,game.cows[i])
		game.cow_states[i] = "skeleton"
		game.cow_traits[i] = {}
	game._refresh_all()
	for child in game.effects_layer.get_children(): child.queue_free()
	game.stored_milk = 50
	game._switch_scene(0,Vector2(700,500))
	await process_frame
	await capture("parasite-tank.png")
	game._switch_scene(1,Vector2(900,500))
	await process_frame
	await capture("infested-house.png")
	check(game._skeleton_count() >= 5, "Five skeletons trigger the giant house infestation")
	var legacy := FileAccess.open(TEST_ROOT + "farm_slot_1.json", FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"farm_name":"旧经济", "coins":600000000, "tank_level":1, "stored_milk":5000, "carried_milk":5000, "cows":[]}))
	legacy.close()
	game._continue_game(1)
	check(game.coins == 6000000 and game.stored_milk <= game._tank_capacity() and game.carried_milk == 100, "Old saves receive the one-time economy conversion")
	for i in range(5):
		game.cows[i] = 0
		game.cow_states[i] = "skeleton"
	game.day_count = 4
	game.playing = true
	game.suspended = false
	game.active_slot = 2
	game._save_game()
	game._switch_scene(2,game.HouseWorld.EXIT_POINT)
	game._switch_scene(1,game.CornWorld.HOUSE_POINT+Vector2(0,80))
	check(game.corn_world.enemies.size() >= 3, "Leaving an infested house spawns several pursuing parasite skeletons")
	game.shotgun_equipped = true
	var enemy_count: int = game.corn_world.enemies.size()
	game._try_shoot_cow(game.corn_world.enemies[0])
	check(game.corn_world.enemies.size() == enemy_count-1, "Shotgun destroys pursuing parasite skeletons")
	game.corn_world.enemies[0] = game.player.position
	game.corn_world._process(0.0)
	check(game.game_over and not FileAccess.file_exists(game._slot_path(2)), "Enemy contact shows game over and deletes the active save")
	await capture("game-over.png")
	# Grass is drawn, not a container-managed ColorRect.
	check(game.slots[0].get_child_count() == 1, "No stretched grass controls")
	game._show_start()
	await capture("slots.png")
	print("FAILURES: ", failures)
	quit(failures)

func mouse_button(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event)
	await process_frame

func mouse_move(pos: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.relative = Vector2(30, 10)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)
	await process_frame
