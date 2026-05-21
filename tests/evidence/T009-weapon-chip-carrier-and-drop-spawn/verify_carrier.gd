extends SceneTree

const CARRIER_SCENE := preload("res://scenes/enemies/WeaponChipCarrier.tscn")
const CHIP_SCENE := preload("res://scenes/pickups/WeaponChip.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")
const DEFENSE_GRID_SCRIPT := preload("res://src/grid/defense_grid.gd")
const DEBUG_FAMILY := preload("res://data/weapons/debug_plasma.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	await _verify_carrier_damage_and_chip_drop(failures)
	await _verify_chip_expiry_no_grid_debit(failures)
	await _verify_chip_collects_player_overlap(failures)
	_verify_chip_pickup_slot_semantics(failures)

	if failures.is_empty():
		print("CARRIER_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_carrier_damage_and_chip_drop(failures: Array[String]) -> void:
	var container := Node2D.new()
	root.add_child(container)

	var carrier := CARRIER_SCENE.instantiate()
	container.add_child(carrier)
	carrier.global_position = Vector2(270.0, 360.0)
	carrier.set("max_hp", 2.0)
	await process_frame

	var killed_count := [0]
	carrier.carrier_killed.connect(func(_death_position: Vector2) -> void:
		killed_count[0] += 1
	)

	if !is_equal_approx(carrier.current_hp, 2.0):
		failures.append("expected carrier current_hp to initialize to 2.0, got %.1f" % carrier.current_hp)

	carrier.take_damage(1.0, carrier.global_position)
	if !is_equal_approx(carrier.current_hp, 1.0):
		failures.append("expected first pea hit to leave carrier at 1.0 HP, got %.1f" % carrier.current_hp)
	if int(killed_count[0]) != 0:
		failures.append("expected first pea hit not to emit carrier_killed, got %d" % killed_count[0])

	carrier.take_damage(1.0, carrier.global_position)
	if int(killed_count[0]) != 1:
		failures.append("expected lethal second pea hit to emit carrier_killed exactly once, got %d" % killed_count[0])
	if !carrier.is_queued_for_deletion():
		failures.append("expected carrier to queue_free after lethal hit")
	if !_has_child_named(container, "WeaponChip"):
		failures.append("expected lethal carrier hit to spawn WeaponChip")
	if !_has_child_named(container, "PixelBurst"):
		failures.append("expected lethal carrier hit to spawn PixelBurst")

	container.queue_free()
	await process_frame


func _verify_chip_expiry_no_grid_debit(failures: Array[String]) -> void:
	var container := Node2D.new()
	root.add_child(container)

	var grid := DEFENSE_GRID_SCRIPT.new()
	container.add_child(grid)
	await process_frame

	var chip := CHIP_SCENE.instantiate()
	container.add_child(chip)
	chip.global_position = Vector2(270.0, 100.0)
	chip.set("drift_speed", 40.0)
	chip.set("planet_line_y", 120.0)
	await process_frame

	chip._physics_process(0.6)
	if !chip.is_queued_for_deletion():
		failures.append("expected chip to queue_free when crossing planet line")
	if !is_equal_approx(grid.current_integrity, grid.max_integrity):
		failures.append("expected chip expiry not to debit Grid, got %.1f / %.1f" % [grid.current_integrity, grid.max_integrity])

	container.queue_free()
	await process_frame


func _verify_chip_collects_player_overlap(failures: Array[String]) -> void:
	var container := Node2D.new()
	root.add_child(container)

	var player := PLAYER_SCENE.instantiate()
	container.add_child(player)
	player.global_position = Vector2(270.0, 850.0)
	await process_frame

	var typed_slot := player.get_node("TypedWeaponSlot")
	var chip := CHIP_SCENE.instantiate()
	chip.global_position = Vector2(270.0, 780.0)
	chip.set("drift_speed", 140.0)
	chip.set("sway_amplitude", 0.0)
	container.add_child(chip)
	if chip.has_method("reset_sway_anchor"):
		chip.reset_sway_anchor()

	for _frame in 45:
		await physics_frame
		await process_frame
		if typed_slot.active_weapon != null:
			break

	if typed_slot.active_weapon == null:
		failures.append("expected drifting chip to equip the player's TypedWeaponSlot through Area2D collision")
	if is_instance_valid(chip) and !chip.is_queued_for_deletion():
		failures.append("expected collected overlapping chip to queue_free")

	container.queue_free()
	await process_frame


func _verify_chip_pickup_slot_semantics(failures: Array[String]) -> void:
	var slot := SLOT_SCRIPT.new()
	slot.default_pickup_family = DEBUG_FAMILY

	var events: Array[Dictionary] = []
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		events.append({
			"family_id": family_id,
			"granted_new_family": granted_new_family,
		})
	)

	slot.apply_chip_pickup()
	if slot.active_weapon == null:
		failures.append("expected first chip pickup to equip a weapon from empty state")
		return
	if slot.active_weapon.family != DEBUG_FAMILY:
		failures.append("expected first chip pickup to equip debug_plasma")
	if events.size() != 1 or !bool(events[0]["granted_new_family"]):
		failures.append("expected first chip pickup event to grant a new family")
	if !is_equal_approx(slot.active_weapon.current_energy, slot.active_weapon.max_energy):
		failures.append("expected first chip pickup to equip at full energy")

	slot.active_weapon.current_energy = 10.0
	slot.apply_chip_pickup()
	if !is_equal_approx(slot.active_weapon.current_energy, slot.active_weapon.max_energy):
		failures.append("expected second chip pickup to refill energy to max")
	if events.size() != 2 or bool(events[1]["granted_new_family"]):
		failures.append("expected second chip pickup event to report refill, not new family")
	if str(events[1]["family_id"]) != "debug_plasma":
		failures.append("expected refill event family_id debug_plasma, got %s" % events[1]["family_id"])

	slot.free()


func _has_child_named(parent: Node, child_name: String) -> bool:
	for child in parent.get_children():
		if child.name == child_name:
			return true
	return false
