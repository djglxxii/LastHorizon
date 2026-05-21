extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T009-weapon-chip-carrier-and-drop-spawn"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const CARRIER_SCENE := preload("res://scenes/enemies/WeaponChipCarrier.tscn")
const CHIP_SCENE := preload("res://scenes/pickups/WeaponChip.tscn")
const WIDTH := 540
const HEIGHT := 960

var _main: Node


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _load_fresh_main()
	await _advance_frames(2)
	await _save_capture({"file": "boot-no-weapon.png"})

	await _capture_carrier_sweep()
	await _capture_carrier_kill_and_chip_drop()
	await _capture_chip_collect()
	await _capture_chip_expiry()

	print("Saved live T009 carrier evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


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


func _capture_carrier_sweep() -> void:
	await _load_fresh_main()
	_disable_live_spawners_for_controlled_capture()

	var grid := _main.get_node("%DefenseGrid")
	var before_grid := float(grid.current_integrity)
	var carrier := await _spawn_carrier(Vector2(-56.0, 320.0), 1.0)
	await _save_capture({"file": "carrier-sweep-01-entering.png"})

	await _advance_seconds(2.9)
	await _save_capture({"file": "carrier-sweep-02-midfield.png"})

	while is_instance_valid(carrier) and !carrier.is_queued_for_deletion():
		await physics_frame
		await process_frame
	await _save_capture({"file": "carrier-sweep-03-exited.png"})

	var after_grid := float(grid.current_integrity)
	print("carrier_sweep_grid %.1f -> %.1f, chip_spawned=%s" % [before_grid, after_grid, _main.find_child("WeaponChip", true, false) != null])


func _capture_carrier_kill_and_chip_drop() -> void:
	await _load_fresh_main()
	_disable_live_spawners_for_controlled_capture()

	var carrier := await _spawn_carrier(Vector2(270.0, 340.0), 1.0)
	carrier.set_physics_process(false)
	await _save_capture({"file": "carrier-kill-drops-chip-01-before.png"})

	carrier.take_damage(2.0, carrier.global_position)
	await process_frame
	await _save_capture({"file": "carrier-kill-drops-chip-02-burst-and-chip.png"})

	await _advance_frames(10)
	await _save_capture({"file": "carrier-kill-drops-chip-03-chip-alone.png"})


func _capture_chip_collect() -> void:
	await _load_fresh_main()
	_disable_live_spawners_for_controlled_capture()

	var player := _main.get_node("Player") as Node2D
	player.position.x = 270.0
	var chip := await _spawn_chip(Vector2(270.0, 780.0))
	chip.set("sway_amplitude", 70.0)
	chip.set("sway_period", 1.3)
	await _save_capture({"file": "chip-sweep-and-collect-01-approach.png"})

	await _advance_seconds(0.45)
	if is_instance_valid(chip):
		player.position.x = chip.global_position.x
	await _save_capture({"file": "chip-sweep-and-collect-02-intercept.png"})

	if is_instance_valid(chip) and !chip.is_queued_for_deletion():
		var collector := player.get_node("PickupCollector") as Area2D
		chip._on_area_entered(collector)
	await process_frame
	await _save_capture({"file": "chip-sweep-and-collect-03-energy-full.png"})


func _capture_chip_expiry() -> void:
	await _load_fresh_main()
	_disable_live_spawners_for_controlled_capture()

	var grid := _main.get_node("%DefenseGrid")
	var player := _main.get_node("Player") as Node2D
	player.position.x = 500.0
	var before_grid := float(grid.current_integrity)
	var chip := await _spawn_chip(Vector2(90.0, 830.0))
	chip.set("planet_line_y", 900.0)
	await _save_capture({"file": "chip-expires-at-planet-line-01-before.png"})

	await _advance_seconds(1.0)
	await _save_capture({"file": "chip-expires-at-planet-line-02-near-line.png"})

	while is_instance_valid(chip) and !chip.is_queued_for_deletion():
		await physics_frame
		await process_frame
	await _save_capture({"file": "chip-expires-at-planet-line-03-after.png"})

	var after_grid := float(grid.current_integrity)
	print("chip_expiry_grid %.1f -> %.1f" % [before_grid, after_grid])


func _spawn_carrier(spawn_position: Vector2, direction: float) -> Node:
	var carrier := CARRIER_SCENE.instantiate()
	carrier.global_position = spawn_position
	carrier.set("direction", direction)
	_main.add_child(carrier)
	await process_frame
	return carrier


func _spawn_chip(spawn_position: Vector2) -> Node:
	var chip := CHIP_SCENE.instantiate()
	chip.global_position = spawn_position
	_main.add_child(chip)
	if chip.has_method("reset_sway_anchor"):
		chip.reset_sway_anchor()
	await process_frame
	return chip


func _disable_live_spawners_for_controlled_capture() -> void:
	var enemy_spawner := _main.get_node_or_null("EnemySpawner")
	if enemy_spawner != null:
		enemy_spawner.set_physics_process(false)
		enemy_spawner.queue_free()

	var carrier_spawner := _main.get_node_or_null("CarrierSpawner")
	if carrier_spawner != null:
		carrier_spawner.set_physics_process(false)
		carrier_spawner.queue_free()

	var player := _main.get_node_or_null("Player")
	if player == null:
		return

	var pea_shooter := player.get_node_or_null("PeaShooter")
	if pea_shooter != null:
		pea_shooter.set_physics_process(false)

	var typed_slot := player.get_node_or_null("TypedWeaponSlot")
	if typed_slot != null:
		typed_slot.set_physics_process(false)


func _advance_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _advance_seconds(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await physics_frame
		await process_frame
		elapsed += root.get_process_delta_time()


func _save_capture(capture: Dictionary) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Viewport capture failed for %s" % capture["file"])
		quit(1)
		return

	if capture.has("crop"):
		image = image.get_region(capture["crop"])

	if capture.has("scale"):
		var scale := int(capture["scale"])
		image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)

	var output_path := "%s/%s" % [OUTPUT_DIR, capture["file"]]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [output_path, error])
		quit(1)
