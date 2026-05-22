extends SceneTree

const CARRIER_SCENE := preload("res://scenes/carriers/FuelCellCarrier.tscn")
const SPAWNER_SCRIPT := preload("res://src/carriers/fuel_cell_carrier_spawner.gd")
const DEFENSE_GRID_SCRIPT := preload("res://src/grid/defense_grid.gd")
const PEA_BULLET_SCENE := preload("res://scenes/projectiles/PeaBullet.tscn")
const TYPED_PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const TYPED_SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_spawner_cadence()
	await _verify_two_phase_traversal()
	await _verify_exit_does_not_damage_grid()
	await _verify_collection_signal_without_energy_change()
	await _verify_projectile_pass_through()

	if !failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("FUEL_CELL_VERIFICATION_OK")
	quit(0)


func _verify_spawner_cadence() -> void:
	var spawner := SPAWNER_SCRIPT.new()
	spawner.carrier_scene = CARRIER_SCENE
	spawner.spawn_interval_seconds = 30.0
	root.add_child(spawner)
	await process_frame

	for index in range(29):
		spawner._physics_process(1.0)

	if spawner.get_child_count() != 0:
		failures.append("fuel spawner produced a carrier before the first 30 s interval elapsed")

	spawner._physics_process(1.0)
	if spawner.get_child_count() != 1:
		failures.append("fuel spawner did not produce exactly one carrier at the 30 s interval")

	spawner.queue_free()
	await process_frame


func _verify_two_phase_traversal() -> void:
	var carrier := _new_carrier()
	carrier.position = Vector2(270.0, 1016.0)
	carrier.apex_y_min = 400.0
	carrier.apex_y_max = 400.0
	carrier.ascent_speed = 220.0
	carrier.descent_speed = 50.0
	carrier.sway_amplitude = 22.0
	carrier.sway_period = 1.9
	root.add_child(carrier)
	await process_frame

	var elapsed := 0.0
	while !carrier.is_descending() and elapsed < 3.2:
		carrier._physics_process(0.1)
		elapsed += 0.1

	if !carrier.is_descending():
		failures.append("fuel carrier did not enter descent state after reaching its apex")
	if carrier.position.y > 400.01:
		failures.append("fuel carrier did not snap to the configured apex y")

	var anchor_x := carrier.position.x
	carrier._sway_phase = 0.0
	carrier._descent_age = 0.0
	carrier._physics_process(0.5)
	var offset := carrier.position.x - anchor_x
	if absf(offset) > carrier.sway_amplitude + 0.1:
		failures.append("fuel carrier descent sway exceeded the configured amplitude")
	if carrier.position.y <= 400.0:
		failures.append("fuel carrier did not descend after switching to descent state")

	carrier.queue_free()
	await process_frame


func _verify_exit_does_not_damage_grid() -> void:
	var grid := DEFENSE_GRID_SCRIPT.new()
	root.add_child(grid)
	await process_frame
	var before := grid.current_integrity
	var leak_events := [0]
	grid.leak_registered.connect(func(_amount: float, _position: Vector2) -> void:
		leak_events[0] += 1
	)

	var carrier := _new_carrier()
	carrier.playfield_height = 960.0
	carrier.off_screen_margin = 56.0
	carrier.position = Vector2(270.0, 1015.0)
	root.add_child(carrier)
	await process_frame
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = 270.0
	carrier._physics_process(1.0)

	if !carrier.is_queued_for_deletion():
		failures.append("fuel carrier did not queue_free after exiting below the playfield")
	if !is_equal_approx(grid.current_integrity, before):
		failures.append("fuel carrier exit changed Defense Grid Integrity")
	if leak_events[0] != 0:
		failures.append("fuel carrier exit emitted a Defense Grid leak event")

	carrier.queue_free()
	grid.queue_free()
	await process_frame


func _verify_collection_signal_without_energy_change() -> void:
	var player := Node2D.new()
	player.name = "Player"
	var slot := TYPED_SLOT_SCRIPT.new()
	slot.name = "TypedWeaponSlot"
	player.add_child(slot)
	root.add_child(player)
	await process_frame
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = 42.0
	var before_energy := slot.current_energy()

	var collector := Area2D.new()
	collector.name = "PickupCollector"
	player.add_child(collector)

	var carrier := _new_carrier()
	root.add_child(carrier)
	await process_frame
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	var collected_count := [0]
	carrier.fuel_cell_collected.connect(func(_position: Vector2) -> void:
		collected_count[0] += 1
	)

	carrier._on_area_entered(collector)
	carrier._on_area_entered(collector)

	if collected_count[0] != 1:
		failures.append("fuel carrier collection did not emit fuel_cell_collected exactly once")
	if !carrier.is_queued_for_deletion():
		failures.append("fuel carrier did not queue_free after collection")
	if !is_equal_approx(slot.current_energy(), before_energy):
		failures.append("fuel carrier collection changed typed-weapon energy in T012")

	carrier.queue_free()
	player.queue_free()
	await process_frame


func _verify_projectile_pass_through() -> void:
	var carrier := _new_carrier()
	root.add_child(carrier)
	await process_frame

	if carrier.has_method("take_damage"):
		failures.append("fuel carrier exposes take_damage even though projectiles should pass through")
	if carrier.collision_layer & 4 != 0:
		failures.append("fuel carrier is on the projectile target collision layer")
	if carrier.collision_mask & 8 != 0:
		failures.append("fuel carrier collision mask watches projectile bodies")

	var pea := PEA_BULLET_SCENE.instantiate()
	var typed := TYPED_PROJECTILE_SCENE.instantiate()
	root.add_child(pea)
	root.add_child(typed)
	await process_frame

	pea._on_hitbox_area_entered(carrier)
	typed._on_hitbox_area_entered(carrier)
	if pea.is_queued_for_deletion():
		failures.append("pea bullet was destroyed by fuel carrier overlap")
	if typed.is_queued_for_deletion():
		failures.append("typed projectile was destroyed by fuel carrier overlap")

	pea.global_position = Vector2(270.0, -40.0)
	typed.global_position = Vector2(270.0, -40.0)
	pea._physics_process(0.01)
	typed._physics_process(0.01)
	if !pea.is_queued_for_deletion():
		failures.append("pea bullet did not complete normal out-of-playfield lifetime")
	if !typed.is_queued_for_deletion():
		failures.append("typed projectile did not complete normal out-of-playfield lifetime")

	carrier.queue_free()
	pea.queue_free()
	typed.queue_free()
	await process_frame


func _new_carrier() -> FuelCellCarrier:
	var carrier := CARRIER_SCENE.instantiate() as FuelCellCarrier
	carrier.pickup_burst_scene = null
	return carrier
