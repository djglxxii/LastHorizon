extends SceneTree

const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")
const SPAWNER_SCRIPT := preload("res://src/carriers/fuel_cell_carrier_spawner.gd")
const CARRIER_SCENE := preload("res://scenes/carriers/FuelCellCarrier.tscn")
const TUNED_SPAWN_INTERVAL_SECONDS := 15.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify_partial_refill_math()
	_verify_cap_at_max()
	_verify_empty_slot_noop()
	await _verify_no_spawn_without_weapon()
	await _verify_equip_edge_reset()
	await _verify_in_flight_empty_slot_collection_gate()

	if !failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("PARTIAL_REFILL_VERIFICATION_OK")
	quit(0)


func _verify_partial_refill_math() -> void:
	var family := _new_family("A", 100.0)
	var slot := SLOT_SCRIPT.new()
	var original_weapon: TypedWeapon
	var energy_events: Array[Dictionary] = []
	var partial_events: Array[Dictionary] = []
	var order: Array[String] = []
	slot.typed_weapon_energy_changed.connect(func(current_energy: float, max_energy: float) -> void:
		energy_events.append({"current_energy": current_energy, "max_energy": max_energy})
		order.append("energy")
	)
	slot.typed_weapon_partial_refilled.connect(func(family_id: String, amount_restored: float) -> void:
		partial_events.append({"family_id": family_id, "amount_restored": amount_restored})
		order.append("partial")
	)

	slot.equip(family)
	original_weapon = slot.active_weapon
	slot.active_weapon.current_energy = 40.0
	energy_events.clear()
	order.clear()

	slot.apply_fuel_cell_pickup()
	if slot.active_weapon != original_weapon:
		failures.append("fuel-cell refill rebuilt the active TypedWeapon instance")
	if slot.active_weapon.family != family:
		failures.append("fuel-cell refill changed the equipped family")
	if !is_equal_approx(slot.active_weapon.current_energy, 70.0):
		failures.append("expected partial fuel refill to restore current_energy to 70.0, got %.2f" % slot.active_weapon.current_energy)
	if energy_events.size() != 1 or !is_equal_approx(float(energy_events[0]["current_energy"]), 70.0):
		failures.append("expected one energy-changed signal with current_energy 70.0")
	if partial_events.size() != 1 or str(partial_events[0]["family_id"]) != "A" or !is_equal_approx(float(partial_events[0]["amount_restored"]), 30.0):
		failures.append("expected typed_weapon_partial_refilled(A, 30.0) once")
	if order.size() != 2 or order[0] != "energy" or order[1] != "partial":
		failures.append("expected energy-changed signal before partial-refilled signal")

	slot.free()


func _verify_cap_at_max() -> void:
	var family := _new_family("A", 100.0)
	var slot := SLOT_SCRIPT.new()
	var partial_events: Array[Dictionary] = []
	slot.typed_weapon_partial_refilled.connect(func(family_id: String, amount_restored: float) -> void:
		partial_events.append({"family_id": family_id, "amount_restored": amount_restored})
	)

	slot.equip(family)
	slot.active_weapon.current_energy = 85.0
	slot.apply_fuel_cell_pickup()
	if !is_equal_approx(slot.active_weapon.current_energy, 100.0):
		failures.append("expected fuel-cell refill to cap current_energy at max_energy")
	if partial_events.size() != 1 or !is_equal_approx(float(partial_events[0]["amount_restored"]), 15.0):
		failures.append("expected at-cap partial refill event to report actual restored amount 15.0")

	partial_events.clear()
	slot.apply_fuel_cell_pickup()
	if !is_equal_approx(slot.active_weapon.current_energy, 100.0):
		failures.append("expected full-meter fuel-cell pickup to remain at max_energy")
	if partial_events.size() != 1 or !is_equal_approx(float(partial_events[0]["amount_restored"]), 0.0):
		failures.append("expected full-meter fuel-cell pickup to emit restored amount 0.0")

	slot.free()


func _verify_empty_slot_noop() -> void:
	var slot := SLOT_SCRIPT.new()
	var energy_events := [0]
	var partial_events := [0]
	slot.typed_weapon_energy_changed.connect(func(_current_energy: float, _max_energy: float) -> void:
		energy_events[0] += 1
	)
	slot.typed_weapon_partial_refilled.connect(func(_family_id: String, _amount_restored: float) -> void:
		partial_events[0] += 1
	)

	slot.apply_fuel_cell_pickup()
	if energy_events[0] != 0 or partial_events[0] != 0:
		failures.append("expected empty-slot fuel-cell pickup to emit no signals")

	slot.free()


func _verify_no_spawn_without_weapon() -> void:
	var scene := Node.new()
	var slot := SLOT_SCRIPT.new()
	slot.name = "TypedWeaponSlot"
	var spawner := SPAWNER_SCRIPT.new()
	spawner.carrier_scene = CARRIER_SCENE
	spawner.spawn_interval_seconds = TUNED_SPAWN_INTERVAL_SECONDS
	spawner.typed_weapon_slot_path = NodePath("../TypedWeaponSlot")
	scene.add_child(slot)
	scene.add_child(spawner)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	for index in range(int(TUNED_SPAWN_INTERVAL_SECONDS * 2.0)):
		spawner._physics_process(1.0)

	if spawner.get_child_count() != 0:
		failures.append("fuel spawner spawned while the typed-weapon slot was empty")

	scene.queue_free()
	await process_frame
	current_scene = null


func _verify_equip_edge_reset() -> void:
	var scene := Node.new()
	var slot := SLOT_SCRIPT.new()
	slot.name = "TypedWeaponSlot"
	var spawner := SPAWNER_SCRIPT.new()
	spawner.carrier_scene = CARRIER_SCENE
	spawner.spawn_interval_seconds = TUNED_SPAWN_INTERVAL_SECONDS
	spawner.typed_weapon_slot_path = NodePath("../TypedWeaponSlot")
	scene.add_child(slot)
	scene.add_child(spawner)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	for index in range(int(TUNED_SPAWN_INTERVAL_SECONDS * 2.0)):
		spawner._physics_process(1.0)
	if spawner.get_child_count() != 0:
		failures.append("fuel spawner spawned during the empty-slot setup window")

	slot.equip(_new_family("A", 100.0))
	spawner._physics_process(0.0)
	if spawner.get_child_count() != 0:
		failures.append("fuel spawner spawned instantly on the equip edge")

	for index in range(int(TUNED_SPAWN_INTERVAL_SECONDS) - 1):
		spawner._physics_process(1.0)
	if spawner.get_child_count() != 0:
		failures.append("fuel spawner spawned before one full interval after equip")

	spawner._physics_process(1.0)
	if spawner.get_child_count() != 1:
		failures.append("fuel spawner did not spawn exactly one carrier one full interval after equip")

	scene.queue_free()
	await process_frame
	current_scene = null


func _verify_in_flight_empty_slot_collection_gate() -> void:
	var player := Node2D.new()
	player.name = "Player"
	var slot := SLOT_SCRIPT.new()
	slot.name = "TypedWeaponSlot"
	player.add_child(slot)
	var collector := Area2D.new()
	collector.name = "PickupCollector"
	player.add_child(collector)
	root.add_child(player)

	var carrier := CARRIER_SCENE.instantiate() as FuelCellCarrier
	carrier.pickup_burst_scene = null
	root.add_child(carrier)
	await process_frame
	carrier._state = FuelCellCarrier.TravelState.DESCENT
	carrier._descent_anchor_x = carrier.position.x
	var collected_count := [0]
	carrier.fuel_cell_collected.connect(func(_position: Vector2) -> void:
		collected_count[0] += 1
	)

	carrier._on_area_entered(collector)
	if collected_count[0] != 0:
		failures.append("fuel carrier emitted collected while slot was empty")
	if carrier._collected or carrier.is_queued_for_deletion():
		failures.append("fuel carrier consumed itself while slot was empty")

	slot.equip(_new_family("A", 100.0))
	slot.active_weapon.current_energy = 40.0
	carrier._on_area_entered(collector)
	if collected_count[0] != 1:
		failures.append("fuel carrier did not emit collected after re-equip")
	if !carrier._collected or !carrier.is_queued_for_deletion():
		failures.append("fuel carrier did not consume itself after re-equip")
	if !is_equal_approx(slot.current_energy(), 70.0):
		failures.append("fuel carrier collection after re-equip did not apply the partial refill")

	carrier.queue_free()
	player.queue_free()
	await process_frame


func _new_family(family_id: String, max_energy: float) -> TypedWeaponFamily:
	var family := TypedWeaponFamily.new()
	family.family_id = family_id
	family.max_energy = max_energy
	return family
