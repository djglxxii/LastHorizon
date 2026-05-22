extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T014-elite-heavy-enemy-type"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const BASELINE_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const ELITE_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const FORMATION_SCENE := preload("res://scenes/enemies/EnemyFormation.tscn")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const HEAVY_SLUG := preload("res://data/weapons/common_heavy_slug.tres")
const WIDTH := 540
const HEIGHT := 960

var _main: Node
var _event_lines: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _capture_silhouette()
	await _capture_pea_shooter_pressure()
	await _capture_typed_weapon_kill()
	await _capture_elite_leak_damage()
	await _capture_ramp_density_notes()
	_write_event_log()
	_write_checklist()
	await _cleanup()

	print("Saved live T014 elite evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _capture_silhouette() -> void:
	await _load_fresh_main()
	_spawn_enemy(BASELINE_SCENE, Vector2(220.0, 270.0), true)
	_spawn_enemy(ELITE_SCENE, Vector2(320.0, 270.0), true)
	await process_frame
	await _save_capture("elite-vs-baseline-silhouette.png")


func _capture_pea_shooter_pressure() -> void:
	await _load_fresh_main()
	var elite := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 270.0), true)
	await process_frame
	await _save_capture("elite-survives-pea-shooter-clip-01-before.png")

	for _index in range(10):
		elite.take_damage(1.0, elite.global_position + Vector2(0.0, 18.0))
	await process_frame
	await _save_capture("elite-survives-pea-shooter-clip-02-after-10-pea-hits.png")

	_write_file("elite-survives-pea-shooter-clip.md", "\n".join([
		"# Elite under pea-shooter pressure",
		"",
		"`elite-survives-pea-shooter-clip-01-before.png` and `elite-survives-pea-shooter-clip-02-after-10-pea-hits.png` show a controlled elite surviving ten pea-shooter damage ticks.",
		"",
		"Important tuning note: with T014's committed `max_hp = 20.0` and the current T003 pea-shooter stream, a single perfectly aligned elite can still be killed before a full playfield descent. The structural pressure this task adds is armada-level target load: elites take 4x as many pea hits as baselines while occupying normal grid slots.",
		"",
	])) 
	_log_event("pea_pressure elite_hp_after_10_pea_hits=%.2f max_hp=%.2f" % [float(elite.get("current_hp")), float(elite.get("max_hp"))])


func _capture_typed_weapon_kill() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(HEAVY_SLUG)
	var elite := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 360.0), true)
	await process_frame
	await _save_capture("elite-killed-by-typed-weapon-clip-01-before.png")

	for _index in range(3):
		elite.take_damage(HEAVY_SLUG.projectile_damage, elite.global_position + Vector2(0.0, 18.0))
	await process_frame
	await _save_capture("elite-killed-by-typed-weapon-clip-02-kill-burst.png")
	_log_event("typed_weapon_kill family=%s damage_per_hit=%.2f hits=3" % [HEAVY_SLUG.family_id, HEAVY_SLUG.projectile_damage])


func _capture_elite_leak_damage() -> void:
	await _load_fresh_main()
	var grid := _main.get_node("DefenseGrid")
	var before := float(grid.current_integrity)
	var elite := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 872.0), false)
	elite.set("planet_line_y", 900.0)
	await process_frame
	await _save_capture("elite-leak-grid-damage-clip-01-before.png")

	elite.global_position = Vector2(270.0, 904.0)
	elite._leak()
	await process_frame
	var after := float(grid.current_integrity)
	await _save_capture("elite-leak-grid-damage-clip-02-after.png")
	_log_event("elite_leak_grid before=%.2f after=%.2f delta=%.2f" % [before, after, before - after])


func _capture_ramp_density_notes() -> void:
	await _load_fresh_main()
	var spawner := _main.get_node("EnemySpawner")
	seed(1414)

	var samples := []
	for seconds in [0.0, 30.0, 60.0, 90.0, 150.0]:
		spawner._run_age_seconds = seconds
		var formation: Node2D = spawner._spawn_formation()
		await process_frame
		var counts := _count_enemy_types(formation)
		var slots := int(counts["baseline"]) + int(counts["elite"])
		var chance := float(spawner.current_elite_chance())
		var density := 0.0 if slots == 0 else float(counts["elite"]) / float(slots)
		samples.append({
			"seconds": seconds,
			"chance": chance,
			"slots": slots,
			"elites": counts["elite"],
			"density": density,
		})
		_log_event("ramp_sample t=%.0f elite_chance=%.2f elites=%d slots=%d density=%.2f" % [seconds, chance, counts["elite"], slots, density])
		for child in formation.get_children():
			if child is EliteEnemy:
				var slot := _slot_for_child(child as Node2D, formation)
				_log_event("elite_spawned slot_row=%d slot_col=%d formation_age=%.2f elite_chance=%.2f" % [slot.y, slot.x, seconds, chance])
		formation.queue_free()
		await process_frame

	_write_ramp_density_curve(samples)
	_write_zero_elites_note(samples)


func _load_fresh_main() -> void:
	if _main != null:
		_main.queue_free()
		await process_frame

	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	if main_scene == null:
		push_error("Unable to load %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	_main = main_scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	await process_frame
	_disable_live_spawners_for_controlled_capture()


func _disable_live_spawners_for_controlled_capture() -> void:
	for node_name in ["EnemySpawner", "CarrierSpawner", "FuelCellCarrierSpawner"]:
		var spawner := _main.get_node_or_null(node_name)
		if spawner != null:
			spawner.set_physics_process(false)
			if node_name != "EnemySpawner":
				spawner.queue_free()

	var player := _main.get_node_or_null("Player")
	if player == null:
		return

	var pea_shooter := player.get_node_or_null("PeaShooter")
	if pea_shooter != null:
		pea_shooter.set_physics_process(false)

	var typed_slot := player.get_node_or_null("TypedWeaponSlot")
	if typed_slot != null:
		typed_slot.set_physics_process(false)

	for bullet in _main.find_children("PeaBullet", "", true, false):
		bullet.queue_free()


func _spawn_enemy(scene: PackedScene, position: Vector2, freeze_physics: bool) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	if enemy == null:
		push_error("Unable to instantiate enemy scene.")
		quit(1)
		return null

	_main.add_child(enemy)
	enemy.global_position = position
	enemy.set_physics_process(!freeze_physics)
	if enemy is EliteEnemy:
		enemy.killed.connect(func() -> void:
			_log_event("elite_killed")
		)
		enemy.leaked.connect(func(_impact_position: Vector2) -> void:
			_log_event("elite_leaked grid_damage=%.2f" % float(enemy.get("leak_damage_per_enemy")))
		)
	return enemy


func _count_enemy_types(formation: Node) -> Dictionary:
	var counts := {"baseline": 0, "elite": 0, "other": 0}
	if formation == null:
		return counts

	for child in formation.get_children():
		if child is EliteEnemy:
			counts["elite"] = int(counts["elite"]) + 1
		elif child is BaselineEnemy:
			counts["baseline"] = int(counts["baseline"]) + 1
		else:
			counts["other"] = int(counts["other"]) + 1
	return counts


func _slot_for_child(child: Node2D, formation: Node) -> Vector2i:
	var cell_size := formation.get("cell_size") as Vector2
	var rows := int(formation.get("rows"))
	var cols := int(formation.get("cols"))
	var start_x := -float(cols - 1) * cell_size.x * 0.5
	var start_y := -float(rows - 1) * cell_size.y * 0.5
	var col := roundi((child.position.x - start_x) / cell_size.x)
	var row := roundi((child.position.y - start_y) / cell_size.y)
	return Vector2i(col, row)


func _write_ramp_density_curve(samples: Array) -> void:
	var lines := [
		"# Ramp density curve",
		"",
		"| t (s) | elite_chance | elites / slots | observed density |",
		"|---:|---:|---:|---:|",
	]
	for sample in samples:
		lines.append(
			"| %.0f | %.2f | %d / %d | %.2f |"
				% [sample["seconds"], sample["chance"], sample["elites"], sample["slots"], sample["density"]]
		)
	lines.append("")
	lines.append("Event-log snippet:")
	lines.append("")
	lines.append("```text")
	for line in _event_lines:
		if line.begins_with("ramp_sample") or line.begins_with("elite_spawned"):
			lines.append(line)
	lines.append("```")
	lines.append("")
	_write_file("ramp-density-curve.md", "\n".join(lines))


func _write_zero_elites_note(samples: Array) -> void:
	var opening = samples[0]
	_write_file("zero-elites-at-run-start.md", "\n".join([
		"# Zero elites at run start",
		"",
		"The t=0 ramp sample uses `EnemySpawner.current_elite_chance()` before any run age has accumulated.",
		"",
		"```text",
		"t=%.0f elite_chance=%.2f elites=%d slots=%d" % [opening["seconds"], opening["chance"], opening["elites"], opening["slots"]],
		"```",
		"",
		"Opening formations therefore spawn as pure baseline blocks until the ramp has a non-zero chance to roll elites.",
		"",
	]))


func _save_capture(file_name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Viewport capture failed for %s" % file_name)
		quit(1)
		return

	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [output_path, error])
		quit(1)


func _log_event(line: String) -> void:
	_event_lines.append(line)
	print(line)


func _write_event_log() -> void:
	_write_file("event-log.txt", "\n".join(_event_lines) + "\n")


func _write_checklist() -> void:
	_write_file("checklist.md", "\n".join([
		"# T014 reviewer checklist",
		"",
		"- [ ] Elite silhouette reads as same coalition palette, distinct/bulkier shape against the baseline grunt.",
		"- [ ] Elite takes 4x baseline pea-shooter hits; note the current 20 HP tuning does not make one perfectly aligned elite survive a full playfield descent by itself.",
		"- [ ] Heavy Slug typed-weapon damage kills an elite in three direct hits.",
		"- [ ] A single elite leak deducts about 40 Defense Grid integrity.",
		"- [ ] The opening ramp sample contains zero elites.",
		"- [ ] By t ~= 90 s the computed chance reaches the 0.20 cap and does not climb further.",
		"- [ ] T020 grid-alignment verifier still passes with elite-bearing formation support.",
		"- [ ] `elite_spawned`, `elite_killed`, and `elite_leaked` event lines appear in captured output/logs.",
		"- [ ] Headless smoke and `verify_elite.gd` pass.",
		"",
	]))


func _write_file(file_name: String, text: String) -> void:
	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % output_path)
		quit(1)
		return

	file.store_string(text)


func _cleanup() -> void:
	var timer := create_timer(0.35)
	await timer.timeout
	if _main != null:
		_main.queue_free()
		_main = null
	current_scene = null
	await process_frame
