extends SceneTree

const ENEMY_SPAWNER_SCRIPT := preload("res://src/enemies/enemy_spawner.gd")
const ENEMY_FORMATION_SCRIPT := preload("res://src/enemies/enemy_formation.gd")
const BASELINE_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const ELITE_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const FORMATION_SCENE := preload("res://scenes/enemies/EnemyFormation.tscn")


class DefenseGridStub:
	extends Node

	var calls: Array[Dictionary] = []

	func apply_leak_damage(amount: float, impact_position: Vector2) -> void:
		calls.append({"amount": amount, "impact_position": impact_position})


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	await _verify_elite_defaults_damage_and_kill(failures)
	await _verify_elite_leak_applies_grid_damage(failures)
	await _verify_formation_zero_elites(failures)
	await _verify_formation_all_elites(failures)
	await _verify_formation_statistical_elites(failures)
	_verify_spawner_ramp(failures)
	await _verify_missing_elite_scene_fallback(failures)

	if failures.is_empty():
		print("ELITE_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_elite_defaults_damage_and_kill(failures: Array[String]) -> void:
	var scene_root := Node.new()
	root.add_child(scene_root)
	current_scene = scene_root

	var elite := ELITE_SCENE.instantiate()
	scene_root.add_child(elite)
	await process_frame

	if !is_equal_approx(float(elite.get("max_hp")), 20.0):
		failures.append("expected EliteEnemy max_hp 20.0, got %.2f" % float(elite.get("max_hp")))
	if !is_equal_approx(float(elite.get("leak_damage_per_enemy")), 40.0):
		failures.append("expected EliteEnemy leak_damage_per_enemy 40.0, got %.2f" % float(elite.get("leak_damage_per_enemy")))

	var damaged_events: Array[Dictionary] = []
	var killed_count := [0]
	elite.damaged.connect(func(amount: float, hit_position: Vector2) -> void:
		damaged_events.append({"amount": amount, "hit_position": hit_position})
	)
	elite.killed.connect(func() -> void:
		killed_count[0] += 1
	)

	elite.take_damage(5.0, Vector2(12.0, 34.0))
	if damaged_events.size() != 1:
		failures.append("expected one damaged signal after first elite hit, got %d" % damaged_events.size())
	if !is_equal_approx(float(elite.get("current_hp")), 15.0):
		failures.append("expected elite current_hp 15.0 after 5 damage, got %.2f" % float(elite.get("current_hp")))

	elite.take_damage(15.0, Vector2(12.0, 34.0))
	if killed_count[0] != 1:
		failures.append("expected one killed signal after lethal elite hit, got %d" % killed_count[0])
	if !elite.is_queued_for_deletion():
		failures.append("expected elite to queue_free after lethal damage")

	scene_root.queue_free()
	current_scene = null
	await process_frame


func _verify_elite_leak_applies_grid_damage(failures: Array[String]) -> void:
	var scene_root := Node.new()
	root.add_child(scene_root)
	current_scene = scene_root

	var grid := DefenseGridStub.new()
	grid.name = "DefenseGrid"
	scene_root.add_child(grid)

	var elite := ELITE_SCENE.instantiate()
	elite.set("planet_line_y", 100.0)
	elite.global_position = Vector2(270.0, 120.0)
	scene_root.add_child(elite)
	await process_frame

	var leaked_events: Array[Vector2] = []
	elite.leaked.connect(func(impact_position: Vector2) -> void:
		leaked_events.append(impact_position)
	)
	elite._physics_process(0.016)

	if grid.calls.size() != 1:
		failures.append("expected elite leak to call DefenseGrid once, got %d" % grid.calls.size())
	elif !is_equal_approx(float(grid.calls[0]["amount"]), 40.0):
		failures.append("expected elite leak damage 40.0, got %.2f" % float(grid.calls[0]["amount"]))
	if leaked_events.size() != 1:
		failures.append("expected one leaked signal from elite, got %d" % leaked_events.size())
	if !elite.is_queued_for_deletion():
		failures.append("expected leaked elite to queue_free")

	scene_root.queue_free()
	current_scene = null
	await process_frame


func _verify_formation_zero_elites(failures: Array[String]) -> void:
	seed(1400)
	var formation := _spawn_script_formation(10, 10, 0.0, 0.0)
	var counts := _count_enemy_types(formation)
	if counts["elite"] != 0:
		failures.append("expected elite_chance 0.0 to spawn zero elites, got %d" % counts["elite"])
	if counts["baseline"] != 100:
		failures.append("expected elite_chance 0.0 to spawn 100 baselines, got %d" % counts["baseline"])
	formation.free()
	await process_frame


func _verify_formation_all_elites(failures: Array[String]) -> void:
	seed(1401)
	var formation := _spawn_script_formation(4, 5, 1.0, 90.0)
	var counts := _count_enemy_types(formation)
	if counts["elite"] != 20:
		failures.append("expected elite_chance 1.0 to spawn 20 elites, got %d" % counts["elite"])
	if counts["baseline"] != 0:
		failures.append("expected elite_chance 1.0 to spawn zero baselines, got %d" % counts["baseline"])
	formation.free()
	await process_frame


func _verify_formation_statistical_elites(failures: Array[String]) -> void:
	seed(1402)
	var formation := _spawn_script_formation(15, 20, 0.2, 90.0)
	var counts := _count_enemy_types(formation)
	var total := int(counts["elite"]) + int(counts["baseline"])
	var ratio := float(counts["elite"]) / float(total)
	print("elite_statistical_ratio %.3f elite=%d total=%d" % [ratio, counts["elite"], total])
	if ratio < 0.14 or ratio > 0.26:
		failures.append("expected seeded elite ratio near 0.20, got %.3f" % ratio)
	formation.free()
	await process_frame


func _verify_spawner_ramp(failures: Array[String]) -> void:
	var spawner := ENEMY_SPAWNER_SCRIPT.new()
	spawner.elite_ramp_seconds = 90.0
	spawner.elite_chance_max = 0.20

	spawner._run_age_seconds = 0.0
	if !is_equal_approx(spawner.current_elite_chance(), 0.0):
		failures.append("expected spawner elite chance 0.0 at t=0, got %.4f" % spawner.current_elite_chance())

	spawner._run_age_seconds = spawner.elite_ramp_seconds * 0.5
	if !is_equal_approx(spawner.current_elite_chance(), spawner.elite_chance_max * 0.5):
		failures.append("expected spawner elite chance half max at half ramp, got %.4f" % spawner.current_elite_chance())

	spawner._run_age_seconds = spawner.elite_ramp_seconds
	if !is_equal_approx(spawner.current_elite_chance(), spawner.elite_chance_max):
		failures.append("expected spawner elite chance max at ramp end, got %.4f" % spawner.current_elite_chance())

	spawner._run_age_seconds = spawner.elite_ramp_seconds * 2.0
	if !is_equal_approx(spawner.current_elite_chance(), spawner.elite_chance_max):
		failures.append("expected spawner elite chance to cap at max, got %.4f" % spawner.current_elite_chance())

	spawner.free()


func _verify_missing_elite_scene_fallback(failures: Array[String]) -> void:
	seed(1403)
	var formation := ENEMY_FORMATION_SCRIPT.new()
	formation.enemy_scene = BASELINE_SCENE
	formation.elite_enemy_scene = null
	formation.configure(2, 3, Vector2(82.0, 66.0), 32.5, 5.0, 2.4, 960.0, 1.0, 30.0)
	formation._spawn_block()
	var counts := _count_enemy_types(formation)
	print("missing_elite_scene_fallback spawned_baselines=%d spawned_elites=%d warning_expected_once=true" % [counts["baseline"], counts["elite"]])
	if counts["elite"] != 0:
		failures.append("expected missing elite scene fallback to spawn zero elites, got %d" % counts["elite"])
	if counts["baseline"] != 6:
		failures.append("expected missing elite scene fallback to spawn 6 baselines, got %d" % counts["baseline"])
	formation.free()
	await process_frame


func _spawn_script_formation(rows: int, cols: int, elite_chance: float, run_age: float) -> EnemyFormation:
	var formation := ENEMY_FORMATION_SCRIPT.new()
	formation.enemy_scene = BASELINE_SCENE
	formation.elite_enemy_scene = ELITE_SCENE
	formation.configure(rows, cols, Vector2(82.0, 66.0), 32.5, 5.0, 2.4, 960.0, elite_chance, run_age)
	formation._spawn_block()
	return formation


func _count_enemy_types(formation: Node) -> Dictionary:
	var counts := {"baseline": 0, "elite": 0, "other": 0}
	for child in formation.get_children():
		if child is EliteEnemy:
			counts["elite"] = int(counts["elite"]) + 1
		elif child is BaselineEnemy:
			counts["baseline"] = int(counts["baseline"]) + 1
		else:
			counts["other"] = int(counts["other"]) + 1
	return counts
