extends Node

const TEMPLATES := [
	{"kind": "buy", "title": "购买奶牛", "base": 5, "step": 2, "reward": 3000, "stars": 1},
	{"kind": "merge", "title": "完成合成", "base": 3, "step": 1, "reward": 6000, "stars": 1},
	{"kind": "produce", "title": "生产牛奶", "base": 500, "step": 500, "reward": 10000, "stars": 1},
	{"kind": "sell", "title": "出售牛奶", "base": 400, "step": 400, "reward": 12000, "stars": 1},
	{"kind": "upgrade", "title": "升级奶罐", "base": 2, "step": 1, "reward": 18000, "stars": 2},
	{"kind": "lottery", "title": "购买彩票", "base": 1, "step": 1, "reward": 180000, "stars": 3},
	{"kind": "recycle", "title": "回收奶牛", "base": 2, "step": 1, "reward": 9000, "stars": 1}
]

var tasks: Array[Dictionary] = []
var task_stars := 0
var completed := 0
var prestige_count := 0

func setup(run_prestige: int) -> void:
	prestige_count = run_prestige
	if tasks.is_empty():
		for i in 3:
			tasks.append(_new_task())

func advance(kind: String, amount: int = 1) -> bool:
	var newly_completed := false
	for task in tasks:
		if task.kind == kind and task.progress < task.target:
			var was_complete: bool = task.progress >= task.target
			task.progress = mini(task.target, task.progress + amount)
			if not was_complete and task.progress >= task.target:
				newly_completed = true
	return newly_completed

func claim(index: int) -> Dictionary:
	if index < 0 or index >= tasks.size():
		return {}
	var task := tasks[index]
	if task.progress < task.target:
		return {}
	var result := {"coins": task.reward, "stars": task.stars, "title": task.title}
	task_stars += task.stars
	completed += 1
	tasks[index] = _new_task()
	return result

func reset_run(run_prestige: int) -> void:
	prestige_count = run_prestige
	task_stars = 0
	tasks.clear()
	for i in 3:
		tasks.append(_new_task())

func save_data() -> Dictionary:
	return {"tasks": tasks, "task_stars": task_stars, "completed": completed}

func load_data(data: Dictionary, run_prestige: int) -> void:
	prestige_count = run_prestige
	task_stars = maxi(0, int(data.get("task_stars", 0)))
	completed = maxi(0, int(data.get("completed_tasks", 0)))
	tasks.clear()
	var saved: Array = data.get("tasks", [])
	for item in saved:
		if item is Dictionary and item.has("kind") and item.has("target"):
			tasks.append({
				"kind": str(item.get("kind", "buy")),
				"title": str(item.get("title", "牧场任务")),
				"target": maxi(1, int(item.get("target", 1))),
				"progress": maxi(0, int(item.get("progress", 0))),
				"reward": maxi(1, int(item.get("reward", 1000))),
				"stars": maxi(1, int(item.get("stars", 1)))
			})
	while tasks.size() < 3:
		tasks.append(_new_task())
	if tasks.size() > 3:
		tasks.resize(3)

func _new_task() -> Dictionary:
	var used: Array[String] = []
	for task in tasks:
		used.append(str(task.kind))
	var choices: Array = TEMPLATES.filter(func(template): return not used.has(str(template.kind)))
	if choices.is_empty():
		choices = TEMPLATES.duplicate()
	var template: Dictionary = choices[randi_range(0, choices.size() - 1)]
	var difficulty := mini(prestige_count, 12)
	var target := int(template.base) + int(template.step) * difficulty
	var reward := roundi(float(template.reward) * pow(1.7, difficulty))
	return {
		"kind": template.kind, "title": template.title,
		"target": target, "progress": 0,
		"reward": reward, "stars": int(template.stars)
	}
