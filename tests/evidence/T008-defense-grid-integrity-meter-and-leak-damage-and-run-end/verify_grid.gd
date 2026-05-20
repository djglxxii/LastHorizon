extends SceneTree

const DEFENSE_GRID_SCRIPT := preload("res://src/grid/defense_grid.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var grid := DEFENSE_GRID_SCRIPT.new()
	root.add_child(grid)
	await process_frame

	var failure_count := [0]
	grid.grid_failed.connect(func() -> void:
		failure_count[0] += 1
	)

	for _index in 9:
		grid.apply_leak_damage(10.0, Vector2(270.0, 900.0))

	if !is_equal_approx(grid.current_integrity, 10.0):
		failures.append("expected 9 leaks to leave Grid at 10.0, got %.1f" % grid.current_integrity)
	if int(failure_count[0]) != 0:
		failures.append("expected grid_failed not to fire before zero, got %d" % failure_count[0])

	grid.apply_leak_damage(10.0, Vector2(270.0, 900.0))
	if !is_equal_approx(grid.current_integrity, 0.0):
		failures.append("expected 10th leak to clamp Grid at 0.0, got %.1f" % grid.current_integrity)
	if int(failure_count[0]) != 1:
		failures.append("expected grid_failed to fire exactly once at zero, got %d" % failure_count[0])

	grid.apply_leak_damage(10.0, Vector2(270.0, 900.0))
	if !is_equal_approx(grid.current_integrity, 0.0):
		failures.append("expected extra leak after failure to leave Grid at 0.0, got %.1f" % grid.current_integrity)
	if int(failure_count[0]) != 1:
		failures.append("expected grid_failed not to re-fire after failure, got %d" % failure_count[0])

	print("Initial integrity: %.1f / %.1f" % [grid.max_integrity, grid.max_integrity])
	print("After 9 leaks: %.1f / %.1f, grid_failed count=%d" % [10.0, grid.max_integrity, 0])
	print("After 10 leaks: %.1f / %.1f, grid_failed count=%d" % [grid.current_integrity, grid.max_integrity, failure_count[0]])
	print("After extra leak: %.1f / %.1f, grid_failed count=%d" % [grid.current_integrity, grid.max_integrity, failure_count[0]])

	grid.queue_free()

	if failures.is_empty():
		print("GRID_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
