extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T013-partial-energy-refill-on-fuel-cell-pickup"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const WIDTH := 540
const HEIGHT := 960
const EMPTY_SLOT_MULTIPLIER := 2.0

const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")

var _main: Node
var _event_lines: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _capture_partial_refill()
	await _capture_cap_at_max()
	await _capture_actual_collection_event_log()
	await _capture_flash_vocabulary()
	await _write_no_spawn_without_weapon_note()
	await _write_equip_edge_reset_note()
	await _write_in_flight_empty_slot_note()
	_write_event_log()
	_write_checklist()
	await _cleanup()

	print("Saved live T013 partial-refill evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _capture_partial_refill() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	var max_energy := float(slot.max_energy())
	slot.active_weapon.current_energy = max_energy * 0.40
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	var family_before := str(slot.current_family_id())
	var before_energy := float(slot.current_energy())
	await process_frame

	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 790.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	await process_frame
	await _save_capture("fuel-cell-partial-refill-01-before.png")

	slot.apply_fuel_cell_pickup()
	carrier.visible = false
	await process_frame
	await _save_capture("fuel-cell-partial-refill-02-after.png")

	var after_energy := float(slot.current_energy())
	var family_after := str(slot.current_family_id())
	_log_event("partial_refill energy=%.2f->%.2f max=%.2f family=%s->%s" % [before_energy, after_energy, max_energy, family_before, family_after])


func _capture_cap_at_max() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	var max_energy := float(slot.max_energy())
	slot.active_weapon.current_energy = max_energy * 0.85
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	var before_energy := float(slot.current_energy())
	await process_frame

	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 790.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	await process_frame
	await _save_capture("fuel-cell-cap-at-max-01-before.png")

	slot.apply_fuel_cell_pickup()
	carrier.visible = false
	await process_frame
	await _save_capture("fuel-cell-cap-at-max-02-after.png")

	_log_event("cap_at_max energy=%.2f->%.2f max=%.2f" % [before_energy, float(slot.current_energy()), max_energy])


func _capture_actual_collection_event_log() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = float(slot.max_energy()) * 0.40
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)

	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 846.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	await process_frame
	carrier._on_area_entered(player.get_node("PickupCollector") as Area2D)
	await process_frame


func _capture_flash_vocabulary() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = float(slot.max_energy()) * 0.38
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	await process_frame
	slot.apply_chip_pickup(WIDE_SPREAD)
	await process_frame
	await _save_capture("flash-full-refill.png")

	await _load_fresh_main()
	player = _main.get_node("Player") as Node2D
	slot = player.get_node("TypedWeaponSlot")
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = float(slot.max_energy()) * 0.40
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	await process_frame
	slot.apply_fuel_cell_pickup()
	await process_frame
	await _save_capture("flash-partial-refill.png")

	_write_file("flash-vocabulary-comparison.md", "\n".join([
		"# Flash vocabulary comparison",
		"",
		"- `flash-full-refill.png` captures the T011 same-family chip full-refill flash.",
		"- `flash-partial-refill.png` captures the T013 fuel-cell partial-refill flash.",
		"- The partial flash uses a softer cyan fill/border and a shorter 0.16 s duration; the full refill remains brighter and lasts 0.25 s.",
		"",
	]))


func _write_no_spawn_without_weapon_note() -> void:
	await _load_fresh_main()
	var spawner := _main.get_node("FuelCellCarrierSpawner")
	var spawn_count := [0]
	spawner.fuel_cell_carrier_spawned.connect(func(_position: Vector2) -> void:
		spawn_count[0] += 1
	)
	var interval_seconds := int(round(float(spawner.spawn_interval_seconds)))
	var empty_seconds := int(round(float(spawner.spawn_interval_seconds) * EMPTY_SLOT_MULTIPLIER))

	for index in range(empty_seconds):
		spawner._physics_process(1.0)

	_write_file("no-spawn-without-weapon.md", "\n".join([
		"# No spawn without weapon",
		"",
		"Simulated %d.0 s with the typed-weapon slot empty and `spawn_interval_seconds = %.1f`." % [empty_seconds, float(spawner.spawn_interval_seconds)],
		"",
		"Event log snippet:",
		"",
		"```text",
		"fuel_cell_carrier_spawned count=%d" % spawn_count[0],
		"```",
		"",
	]))


func _write_equip_edge_reset_note() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	var slot := player.get_node("TypedWeaponSlot")
	var spawner := _main.get_node("FuelCellCarrierSpawner")
	var spawn_count := [0]
	spawner.fuel_cell_carrier_spawned.connect(func(position: Vector2) -> void:
		spawn_count[0] += 1
		_log_event("equip_edge_reset_spawn position=%s" % position)
	)
	var interval_seconds := int(round(float(spawner.spawn_interval_seconds)))
	var empty_seconds := int(round(float(spawner.spawn_interval_seconds) * EMPTY_SLOT_MULTIPLIER))
	var one_second_before_interval := maxi(interval_seconds - 1, 0)

	for index in range(empty_seconds):
		spawner._physics_process(1.0)
	slot.equip(WIDE_SPREAD)
	spawner._physics_process(0.0)
	var count_at_equip: int = spawn_count[0]
	for index in range(one_second_before_interval):
		spawner._physics_process(1.0)
	var count_before_interval: int = spawn_count[0]
	spawner._physics_process(1.0)
	var count_at_interval: int = spawn_count[0]

	_write_file("equip-edge-reset.md", "\n".join([
		"# Equip-edge reset",
		"",
		"After %d.0 s of empty-slot state, equipping a typed weapon reset the fuel-cell timer to a full interval." % empty_seconds,
		"",
		"```text",
		"spawns_at_equip=%d" % count_at_equip,
		"spawns_after_%ds=%d" % [one_second_before_interval, count_before_interval],
		"spawns_after_%ds=%d" % [interval_seconds, count_at_interval],
		"```",
		"",
	]))


func _write_in_flight_empty_slot_note() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	var slot := player.get_node("TypedWeaponSlot")
	var collector := player.get_node("PickupCollector") as Area2D
	var carrier := _spawn_controlled_fuel_carrier(Vector2(270.0, 846.0))
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	var collected_count := [0]
	carrier.fuel_cell_collected.connect(func(position: Vector2) -> void:
		collected_count[0] += 1
		_log_event("in_flight_empty_slot_collected position=%s" % position)
	)

	carrier._on_area_entered(collector)
	var empty_touch_collected := carrier._collected
	var empty_touch_queued := carrier.is_queued_for_deletion()

	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = float(slot.max_energy()) * 0.40
	carrier._on_area_entered(collector)
	var re_equip_collected := carrier._collected
	var re_equip_queued := carrier.is_queued_for_deletion()

	_write_file("in-flight-empty-slot.md", "\n".join([
		"# In-flight empty slot",
		"",
		"A controlled in-flight carrier remained in descent when touched with an empty slot, then became collectible after re-equip.",
		"",
		"```text",
		"empty_touch_collected=%s" % empty_touch_collected,
		"empty_touch_queued=%s" % empty_touch_queued,
		"re_equip_collected=%s" % re_equip_collected,
		"re_equip_queued=%s" % re_equip_queued,
		"fuel_cell_collected_count=%d" % collected_count[0],
		"```",
		"",
	]))


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


func _spawn_controlled_fuel_carrier(position: Vector2) -> FuelCellCarrier:
	var spawner := _main.get_node("FuelCellCarrierSpawner")
	spawner.fuel_cell_carrier_spawned.connect(_on_fuel_cell_carrier_spawned)
	var carrier := spawner._spawn_carrier() as FuelCellCarrier
	carrier.global_position = position
	carrier.fuel_cell_collected.connect(func(spawn_position: Vector2) -> void:
		_log_event("fuel_cell_collected position=%s" % spawn_position)
	)
	return carrier


func _connect_slot_event_log(slot: Node) -> void:
	slot.typed_weapon_partial_refilled.connect(func(family_id: String, amount_restored: float) -> void:
		_log_event("typed_weapon_partial_refilled family=%s restored=%.2f current=%.2f max=%.2f" % [family_id, amount_restored, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)


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


func _on_fuel_cell_carrier_spawned(position: Vector2) -> void:
	_log_event("fuel_cell_carrier_spawned position=%s" % position)


func _log_event(line: String) -> void:
	_event_lines.append(line)
	print(line)


func _write_event_log() -> void:
	_write_file("event-log.txt", "\n".join(_event_lines) + "\n")


func _write_checklist() -> void:
	_write_file("checklist.md", "\n".join([
		"# T013 reviewer checklist",
		"",
		"- [ ] Fuel-cell pickup at partial energy restores 30% of max energy, capped at max, without changing family or projectile pattern.",
		"- [ ] Fuel-cell pickup near/full energy clamps at max and still fires the partial-refill flash.",
		"- [ ] Partial-refill flash is visibly weaker and shorter than same-family full-refill flash.",
		"- [ ] No fuel-cell carriers spawn while the typed-weapon slot is empty.",
		"- [ ] Equip after an empty-slot stretch waits a full interval before the next fuel-cell spawn.",
		"- [ ] In-flight fuel-cell carrier remains uncollectible while the slot is empty, then is collectible after re-equip.",
		"- [ ] Headless smoke and `verify_partial_refill.gd` pass.",
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
