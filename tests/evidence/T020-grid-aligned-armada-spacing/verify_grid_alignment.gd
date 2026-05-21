extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T020-grid-aligned-armada-spacing"
const ENEMY_SPAWNER_SCRIPT := preload("res://src/enemies/enemy_spawner.gd")
const ENEMY_FORMATION_SCRIPT := preload("res://src/enemies/enemy_formation.gd")
const FORMATION_SCENE := preload("res://scenes/enemies/EnemyFormation.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_verify_grid_interval(failures)
	_verify_half_cell_stagger(failures)
	_verify_sway_clamp(failures)
	_verify_grid_warning_path(failures)

	if failures.is_empty():
		print("GRID_ALIGNED_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_grid_interval(failures: Array[String]) -> void:
	var spawner := ENEMY_SPAWNER_SCRIPT.new()
	var expected_pixels := float(spawner.rows) * spawner.cell_size.y
	var actual_pixels := spawner.spawn_interval_seconds * spawner.descent_speed
	if absf(actual_pixels - expected_pixels) > 0.5:
		failures.append(
			"expected spawn interval to move %.2f px, got %.2f px"
				% [expected_pixels, actual_pixels]
		)
	spawner.free()


func _verify_half_cell_stagger(failures: Array[String]) -> void:
	var spawner := ENEMY_SPAWNER_SCRIPT.new()
	spawner.formation_scene = FORMATION_SCENE

	var first := spawner._spawn_formation()
	var second := spawner._spawn_formation()
	if first == null or second == null:
		failures.append("expected two spawned formations for stagger verification")
		spawner.free()
		return

	var expected_offset := spawner.cell_size.x * 0.5
	var actual_offset := second.position.x - first.position.x
	if !is_equal_approx(actual_offset, expected_offset):
		failures.append(
			"expected second formation x offset %.2f, got %.2f"
				% [expected_offset, actual_offset]
		)

	first.queue_free()
	second.queue_free()
	spawner.free()


func _verify_sway_clamp(failures: Array[String]) -> void:
	var formation := ENEMY_FORMATION_SCRIPT.new()
	formation.enemy_scene = ENEMY_SCENE
	formation.cell_size = Vector2(82.0, 66.0)
	formation.rows = 1
	formation.cols = 2
	formation.sway_amplitude = 50.0
	formation.sway_period = 2.4
	formation._spawn_block()

	var expected_cap := (formation.cell_size.x - ENEMY_FORMATION_SCRIPT.BASELINE_ENEMY_SPRITE_WIDTH) * 0.5 - ENEMY_FORMATION_SCRIPT.SWAY_SAFETY_MARGIN
	var effective := formation.sway_amplitude
	if effective > expected_cap:
		failures.append("expected formation sway amplitude <= %.2f, got %.2f" % [expected_cap, effective])

	if formation.get_child_count() == 0:
		failures.append("expected sway-clamp formation to spawn child enemies")
	else:
		var child := formation.get_child(0)
		var child_amplitude := float(child.get("sway_amplitude"))
		if child_amplitude > expected_cap:
			failures.append("expected child sway amplitude <= %.2f, got %.2f" % [expected_cap, child_amplitude])

	_write_text(
		"sway-cap-warning.txt",
		"\n".join([
			"Scenario: EnemyFormation.sway_amplitude set to 50.0 with cell_size.x = 82.0.",
			"Expected warning: EnemyFormation sway_amplitude exceeds the safe cap and clamps.",
			"Safe cap: %.2f px." % expected_cap,
			"Effective formation amplitude: %.2f px." % effective,
			"Effective first-child amplitude: %.2f px." % (float(formation.get_child(0).get("sway_amplitude")) if formation.get_child_count() > 0 else -1.0),
		])
	)

	formation.free()


func _verify_grid_warning_path(failures: Array[String]) -> void:
	var spawner := ENEMY_SPAWNER_SCRIPT.new()
	spawner.spawn_interval_seconds = 3.0
	var expected_pixels := float(spawner.rows) * spawner.cell_size.y
	var actual_pixels := spawner.spawn_interval_seconds * spawner.descent_speed
	if absf(actual_pixels - expected_pixels) <= 0.5:
		failures.append("expected mismatched interval to diverge from grid spacing")

	spawner._validate_grid_aligned_interval()
	_write_text(
		"grid-invariant-warning.txt",
		"\n".join([
			"Scenario: EnemySpawner.spawn_interval_seconds set to 3.0 with default rows/cell_size/descent_speed.",
			"Expected warning: EnemySpawner spawn interval moves the wrong pixel distance for grid-aligned armada spacing.",
			"Actual movement: %.2f px." % actual_pixels,
			"Expected movement: %.2f px." % expected_pixels,
			"Expected grid-aligned interval: %.2f s." % (expected_pixels / maxf(spawner.descent_speed, 0.01)),
		])
	)

	spawner.free()


func _write_text(file_name: String, text: String) -> void:
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write %s: %s" % [path, FileAccess.get_open_error()])
		quit(1)
		return

	file.store_string(text + "\n")
