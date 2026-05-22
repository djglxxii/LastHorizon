extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T012-coalition-fuel-cell-carrier-approach"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const FUEL_CARRIER_SCENE := preload("res://scenes/carriers/FuelCellCarrier.tscn")
const PEA_BULLET_SCENE := preload("res://scenes/projectiles/PeaBullet.tscn")
const TYPED_PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const FUEL_CARRIER_TEXTURE := preload("res://assets/sprites/carriers/fuel-cell-carrier.png")
const WEAPON_CARRIER_TEXTURE := preload("res://assets/sprites/enemies/weapon-chip-carrier.png")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const RAPID_STREAM := preload("res://data/weapons/common_rapid_stream.tres")
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
	await _capture_traversal_and_exit()
	await _capture_collection()
	await _capture_projectile_pass_through()
	await _capture_visual_distinctness()
	_write_event_log()

	print("Saved live T012 fuel-cell carrier evidence from %s." % MAIN_SCENE_PATH)
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
	_disable_live_spawners_for_controlled_capture()


func _capture_traversal_and_exit() -> void:
	await _load_fresh_main()

	var grid := _main.get_node("DefenseGrid")
	var before_grid := float(grid.current_integrity)
	var grid_damage_events := [0]
	grid.leak_registered.connect(func(_amount: float, _position: Vector2) -> void:
		grid_damage_events[0] += 1
	)

	var spawner := _main.get_node("FuelCellCarrierSpawner")
	spawner.fuel_cell_carrier_spawned.connect(func(position: Vector2) -> void:
		_log_event("fuel_cell_carrier_spawned position=%s" % position)
	)
	var carrier := spawner._spawn_carrier() as FuelCellCarrier
	carrier.position = Vector2(270.0, 1016.0)
	carrier.apex_y_min = 400.0
	carrier.apex_y_max = 400.0
	carrier._apex_y = 400.0
	carrier._sway_phase = 0.0
	await _advance_seconds(1.0)
	await _save_capture("fuel-cell-traversal-01-launch.png")

	while carrier != null and is_instance_valid(carrier) and !carrier.is_descending():
		await _advance_seconds(0.1)
	await _save_capture("fuel-cell-traversal-02-apex.png")

	await _advance_seconds(2.4)
	await _save_capture("fuel-cell-traversal-03-descending-sway.png")

	carrier.position = Vector2(270.0, 1010.0)
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = 270.0
	await _advance_seconds(0.3)
	await _save_capture("fuel-cell-traversal-04-exited.png")
	_log_event("fuel_cell_carrier_exited queued=%s" % (!is_instance_valid(carrier) or carrier.is_queued_for_deletion()))

	var after_grid := float(grid.current_integrity)
	_log_event("fuel_cell_exit_grid %.1f -> %.1f, grid_damage_events=%d" % [before_grid, after_grid, grid_damage_events[0]])


func _capture_collection() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = 42.0
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	var energy_before := float(slot.current_energy())

	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 790.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	carrier.fuel_cell_collected.connect(func(position: Vector2) -> void:
		_log_event("fuel_cell_collected position=%s" % position)
	)
	await process_frame
	await _save_capture("fuel-cell-collected-01-before.png")

	var collector := player.get_node("PickupCollector") as Area2D
	carrier.global_position = Vector2(270.0, 846.0)
	carrier._on_area_entered(collector)
	await process_frame
	await _save_capture("fuel-cell-collected-02-burst.png")

	var energy_after := float(slot.current_energy())
	_log_event("fuel_cell_collection_energy %.1f -> %.1f" % [energy_before, energy_after])


func _capture_projectile_pass_through() -> void:
	await _load_fresh_main()

	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 610.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	carrier._sway_phase = 0.0

	var pea := PEA_BULLET_SCENE.instantiate() as Node2D
	var typed := TYPED_PROJECTILE_SCENE.instantiate() as Node2D
	if typed.has_method("configure_from_family"):
		typed.configure_from_family(RAPID_STREAM)
	_main.add_child(pea)
	_main.add_child(typed)
	pea.global_position = Vector2(252.0, 720.0)
	typed.global_position = Vector2(288.0, 720.0)
	await _advance_seconds(0.12)
	await _save_capture("projectiles-pass-through-clip.png")
	_log_event("projectiles_pass_through pea_queued=%s typed_queued=%s carrier_queued=%s" % [pea.is_queued_for_deletion(), typed.is_queued_for_deletion(), carrier.is_queued_for_deletion()])


func _capture_visual_distinctness() -> void:
	await _load_fresh_main()

	var fuel := Sprite2D.new()
	fuel.texture = FUEL_CARRIER_TEXTURE
	fuel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var weapon := Sprite2D.new()
	weapon.texture = WEAPON_CARRIER_TEXTURE
	weapon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_main.add_child(fuel)
	_main.add_child(weapon)
	fuel.global_position = Vector2(205.0, 480.0)
	weapon.global_position = Vector2(335.0, 480.0)
	await process_frame
	await _save_capture("visual-distinctness-reference.png")
	_log_event("visual_distinctness fuel_sprite=assets/sprites/carriers/fuel-cell-carrier.png weapon_sprite=assets/sprites/enemies/weapon-chip-carrier.png")


func _spawn_controlled_fuel_carrier(position: Vector2) -> FuelCellCarrier:
	var spawner := _main.get_node("FuelCellCarrierSpawner")
	var carrier := spawner._spawn_carrier() as FuelCellCarrier
	carrier.global_position = position
	return carrier


func _disable_live_spawners_for_controlled_capture() -> void:
	var enemy_spawner := _main.get_node_or_null("EnemySpawner")
	if enemy_spawner != null:
		enemy_spawner.set_physics_process(false)
		enemy_spawner.queue_free()

	var carrier_spawner := _main.get_node_or_null("CarrierSpawner")
	if carrier_spawner != null:
		carrier_spawner.set_physics_process(false)
		carrier_spawner.queue_free()

	var fuel_spawner := _main.get_node_or_null("FuelCellCarrierSpawner")
	if fuel_spawner != null:
		fuel_spawner.set_physics_process(false)

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


func _advance_seconds(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await physics_frame
		await process_frame
		elapsed += root.get_process_delta_time()


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
	var output_path := "%s/event-log.txt" % OUTPUT_DIR
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % output_path)
		quit(1)
		return

	for line in _event_lines:
		file.store_line(line)
