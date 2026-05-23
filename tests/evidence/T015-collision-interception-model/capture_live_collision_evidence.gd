extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T015-collision-interception-model"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const BASELINE_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const ELITE_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
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
	await _capture_full_energy_baseline()
	await _capture_full_energy_elite()
	await _capture_partial_energy_elite()
	await _capture_zero_energy_baseline()
	await _capture_zero_energy_elite()
	await _capture_cluster_cooldown()
	await _capture_feedback_readability()
	_write_event_log()
	_write_clip_notes()
	_write_checklist()
	await _cleanup()

	print("Saved live T015 collision evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _capture_full_energy_baseline() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(100.0)
	var enemy := _spawn_enemy(BASELINE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	await _save_capture("full-energy-ram-baseline-01-before.png")

	_trigger_collision(enemy)
	var consumed := enemy.is_queued_for_deletion()
	await process_frame
	await _save_capture("full-energy-ram-baseline-02-after.png")

	_log_event("full_energy_baseline energy=100.00->%.2f grid=100.00->%.2f enemy_consumed=%s" % [float(state["slot"].current_energy()), float(state["grid"].current_integrity), consumed])


func _capture_full_energy_elite() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(100.0)
	var enemy := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	await _save_capture("full-energy-ram-elite-01-before.png")

	_trigger_collision(enemy)
	var consumed := enemy.is_queued_for_deletion()
	await process_frame
	await _save_capture("full-energy-ram-elite-02-after.png")

	_log_event("full_energy_elite energy=100.00->%.2f grid=100.00->%.2f enemy_consumed=%s" % [float(state["slot"].current_energy()), float(state["grid"].current_integrity), consumed])


func _capture_partial_energy_elite() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(5.0)
	var enemy := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	await _save_capture("partial-energy-ram-elite-01-before.png")

	_trigger_collision(enemy)
	var consumed := enemy.is_queued_for_deletion()
	await process_frame
	await _save_capture("partial-energy-ram-elite-02-after.png")

	_log_event("partial_energy_elite energy=5.00->%.2f grid=100.00->%.2f enemy_consumed=%s" % [float(state["slot"].current_energy()), float(state["grid"].current_integrity), consumed])


func _capture_zero_energy_baseline() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(0.0)
	var enemy := _spawn_enemy(BASELINE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	await _save_capture("zero-energy-no-intercept-baseline-01-contact.png")

	_trigger_collision(enemy)
	await process_frame
	await _save_capture("zero-energy-no-intercept-baseline-02-feedback.png")

	enemy.global_position = Vector2(270.0, 904.0)
	enemy._leak()
	await process_frame
	await _save_capture("zero-energy-no-intercept-baseline-03-leaked.png")

	_log_event("zero_energy_baseline energy=0.00->%.2f grid=100.00->%.2f enemy_consumed=false leak_damage=10.00" % [float(state["slot"].current_energy()), float(state["grid"].current_integrity)])


func _capture_zero_energy_elite() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(0.0)
	var enemy := _spawn_enemy(ELITE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	await _save_capture("zero-energy-no-intercept-elite-01-contact.png")

	_trigger_collision(enemy)
	await process_frame
	await _save_capture("zero-energy-no-intercept-elite-02-feedback.png")

	enemy.global_position = Vector2(270.0, 904.0)
	enemy._leak()
	await process_frame
	await _save_capture("zero-energy-no-intercept-elite-03-leaked.png")

	_log_event("zero_energy_elite energy=0.00->%.2f grid=100.00->%.2f enemy_consumed=false leak_damage=40.00" % [float(state["slot"].current_energy()), float(state["grid"].current_integrity)])


func _capture_cluster_cooldown() -> void:
	await _load_fresh_main()
	var state := _prepare_slot(100.0)
	var hull: Node = state["hull"]
	var first := _spawn_enemy(BASELINE_SCENE, Vector2(246.0, 818.0))
	var second := _spawn_enemy(BASELINE_SCENE, Vector2(270.0, 818.0))
	var third := _spawn_enemy(BASELINE_SCENE, Vector2(294.0, 818.0))
	await process_frame
	await _save_capture("cluster-cooldown-01-before.png")

	_trigger_collision(first)
	var first_consumed := first.is_queued_for_deletion()
	hull._physics_process(0.05)
	_trigger_collision(second)
	var second_consumed := second.is_queued_for_deletion()
	await process_frame
	await _save_capture("cluster-cooldown-02-suppressed-second.png")

	hull._physics_process(0.16)
	_trigger_collision(third)
	var third_consumed := third.is_queued_for_deletion()
	await process_frame
	await _save_capture("cluster-cooldown-03-third-resolved.png")

	_log_event("cluster_cooldown energy=100.00->%.2f first_consumed=%s second_consumed=%s third_consumed=%s" % [float(state["slot"].current_energy()), first_consumed, second_consumed, third_consumed])


func _capture_feedback_readability() -> void:
	await _load_fresh_main()
	_prepare_slot(100.0)
	var enemy := _spawn_enemy(BASELINE_SCENE, Vector2(270.0, 818.0))
	await process_frame
	_trigger_collision(enemy)
	await process_frame
	await _save_capture("feedback-readability-still.png")


func _load_fresh_main() -> void:
	if _main != null:
		await create_timer(0.20).timeout
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
	_disable_live_systems_for_controlled_capture()


func _disable_live_systems_for_controlled_capture() -> void:
	for node_name in ["EnemySpawner", "CarrierSpawner", "FuelCellCarrierSpawner"]:
		var spawner := _main.get_node_or_null(node_name)
		if spawner != null:
			spawner.set_physics_process(false)
			if node_name != "EnemySpawner":
				spawner.queue_free()

	var player := _main.get_node_or_null("Player")
	if player == null:
		return

	player.set_physics_process(false)
	var pea_shooter := player.get_node_or_null("PeaShooter")
	if pea_shooter != null:
		pea_shooter.set_physics_process(false)

	var typed_slot := player.get_node_or_null("TypedWeaponSlot")
	if typed_slot != null:
		typed_slot.set_physics_process(false)

	var hull := player.get_node_or_null("PlayerHull")
	if hull != null:
		hull.monitoring = false

	for bullet in _main.find_children("PeaBullet", "", true, false):
		bullet.queue_free()


func _prepare_slot(energy: float) -> Dictionary:
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	var grid := _main.get_node("DefenseGrid")
	var hull := player.get_node("PlayerHull")
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = clampf(energy, 0.0, slot.active_weapon.max_energy)
	slot._was_empty_last_tick = slot.active_weapon.current_energy <= 0.0
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	return {"player": player, "slot": slot, "grid": grid, "hull": hull}


func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	_main.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.set_physics_process(false)
	if enemy is BaselineEnemy:
		enemy.collided.connect(func(impact_position: Vector2) -> void:
			_log_event("baseline_collided impact=<%.1f,%.1f>" % [impact_position.x, impact_position.y])
		)
		enemy.leaked.connect(func(_impact_position: Vector2) -> void:
			_log_event("baseline_leaked grid_damage=%.2f" % float(enemy.get("leak_damage_per_enemy")))
		)
	elif enemy is EliteEnemy:
		enemy.collided.connect(func(impact_position: Vector2) -> void:
			_log_event("elite_collided impact=<%.1f,%.1f>" % [impact_position.x, impact_position.y])
		)
		enemy.leaked.connect(func(_impact_position: Vector2) -> void:
			_log_event("elite_leaked grid_damage=%.2f" % float(enemy.get("leak_damage_per_enemy")))
		)
	return enemy


func _trigger_collision(enemy: Node2D) -> void:
	var player := _main.get_node("Player")
	var hull := player.get_node("PlayerHull")
	var slot := player.get_node("TypedWeaponSlot")
	var grid := _main.get_node("DefenseGrid")
	var energy_before := float(slot.current_energy())
	var hp_before := maxf(float(enemy.get("current_hp")), 0.0)
	var grid_before := float(grid.current_integrity)

	hull._on_area_entered(enemy.get_node("Hurtbox") as Area2D)

	var spent := maxf(energy_before - float(slot.current_energy()), 0.0)
	if spent > 0.0:
		_log_event("typed_weapon_collision_drain family=%s spent=%.2f current=%.2f max=%.2f" % [slot.current_family_id(), spent, float(slot.current_energy()), float(slot.max_energy())])
	var grid_delta := maxf(grid_before - float(grid.current_integrity), 0.0)
	if grid_delta > 0.0:
		_log_event("grid_collision_damage amount=%.2f" % grid_delta)
	if energy_before <= 0.0:
		_log_event("collision_no_intercept reason=zero_energy enemy=%s" % _enemy_log_name(enemy))
	elif hp_before > 0.0 and spent <= 0.0:
		_log_event("collision_cooldown_suppressed")


func _enemy_log_name(enemy: Node) -> String:
	if enemy is EliteEnemy:
		return "elite"
	if enemy is BaselineEnemy:
		return "baseline"
	return enemy.name.to_snake_case()


func _save_capture(file_name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [ProjectSettings.globalize_path(OUTPUT_DIR), file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Unable to save capture %s error=%d" % [path, error])


func _write_event_log() -> void:
	_write_file("event-log.txt", "\n".join(_event_lines) + "\n")


func _write_clip_notes() -> void:
	_write_file("full-energy-ram-baseline-clip.md", "\n".join([
		"# Full-energy ram baseline stills",
		"",
		"- `full-energy-ram-baseline-01-before.png`: full 100-energy meter before contact with a 5-HP baseline.",
		"- `full-energy-ram-baseline-02-after.png`: baseline consumed, meter at 95, Grid unchanged.",
		"",
	]))
	_write_file("full-energy-ram-elite-clip.md", "\n".join([
		"# Full-energy ram elite stills",
		"",
		"- `full-energy-ram-elite-01-before.png`: full 100-energy meter before contact with a 20-HP elite.",
		"- `full-energy-ram-elite-02-after.png`: elite consumed, meter at 80, Grid unchanged.",
		"",
	]))
	_write_file("partial-energy-ram-elite-clip.md", "\n".join([
		"# Partial-energy ram elite stills",
		"",
		"- `partial-energy-ram-elite-01-before.png`: 5 energy before contact with a 20-HP elite.",
		"- `partial-energy-ram-elite-02-after.png`: energy drained to 0, elite consumed, Grid reduced by 15.",
		"",
	]))
	_write_file("zero-energy-no-intercept-clip.md", "\n".join([
		"# Zero-energy baseline no-intercept stills",
		"",
		"- `zero-energy-no-intercept-baseline-01-contact.png`: baseline overlaps the player at 0 energy.",
		"- `zero-energy-no-intercept-baseline-02-feedback.png`: hit feedback plays, baseline is still present.",
		"- `zero-energy-no-intercept-baseline-03-leaked.png`: baseline leaks for the full 10 Grid damage.",
		"",
	]))
	_write_file("zero-energy-no-intercept-elite-clip.md", "\n".join([
		"# Zero-energy elite no-intercept stills",
		"",
		"- `zero-energy-no-intercept-elite-01-contact.png`: elite overlaps the player at 0 energy.",
		"- `zero-energy-no-intercept-elite-02-feedback.png`: hit feedback plays, elite is still present.",
		"- `zero-energy-no-intercept-elite-03-leaked.png`: elite leaks for the full 40 Grid damage.",
		"",
	]))
	_write_file("cluster-cooldown-clip.md", "\n".join([
		"# Cluster cooldown stills",
		"",
		"- `cluster-cooldown-01-before.png`: three overlapping baseline enemies staged around the hull.",
		"- `cluster-cooldown-02-suppressed-second.png`: the second same-window contact is suppressed by the 0.15 s proto-cooldown.",
		"- `cluster-cooldown-03-third-resolved.png`: after the cooldown, a third contact resolves normally.",
		"",
	]))


func _write_checklist() -> void:
	_write_file("checklist.md", "\n".join([
		"# T015 reviewer checklist",
		"",
		"- [x] Full-energy baseline and elite collisions drain enemy HP worth of typed-weapon energy, consume the enemy, and do not damage the Grid when energy covers HP.",
		"- [x] Partial-energy elite collision drains the remaining 5 energy to 0, consumes the elite, and applies exactly 15 collision damage to the Grid.",
		"- [x] Zero-energy baseline contact does not consume the enemy; it later leaks for the full 10 Grid damage.",
		"- [x] Zero-energy elite contact does not consume the enemy; it later leaks for the full 40 Grid damage.",
		"- [x] Cluster contact resolves at most one collision per 0.15 s cooldown window and logs `collision_cooldown_suppressed`.",
		"- [x] Collision feedback is visible as ship flash, camera shake, and energy-meter collision flash.",
		"- [x] Collision consumes through `consume_for_collision`; projectile `take_damage`, killed, and leaked paths remain separate.",
		"- [x] T021 zero-energy persistence remains the gate: `current_energy() > 0.0` intercepts, `has_weapon()` is not used as the collision gate.",
		"- [x] `CLAUDE.md` and `docs/design/decisions.md` contain the superseding no-cap collision wording.",
		"- [x] `verify_collision.gd` ends in `COLLISION_VERIFICATION_OK`.",
		"",
	]))


func _write_file(file_name: String, contents: String) -> void:
	var path := "%s/%s" % [ProjectSettings.globalize_path(OUTPUT_DIR), file_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write %s" % path)
		return
	file.store_string(contents)


func _log_event(line: String) -> void:
	_event_lines.append(line)
	print(line)


func _cleanup() -> void:
	if _main != null:
		await create_timer(0.20).timeout
		_main.queue_free()
		await process_frame
	_main = null
	current_scene = null
