extends SceneTree

const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")

const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const HEAVY_SLUG := preload("res://data/weapons/common_heavy_slug.tres")
const RAPID_STREAM := preload("res://data/weapons/common_rapid_stream.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_verify_first_equip(failures)
	_verify_same_family_refill(failures)
	_verify_different_family_swap(failures)
	_verify_swap_uses_new_family_max(failures)

	if failures.is_empty():
		print("REFILL_SWAP_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_first_equip(failures: Array[String]) -> void:
	var slot := SLOT_SCRIPT.new()
	var chip_events: Array[Dictionary] = []
	var refill_events: Array[String] = []
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		chip_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
	)
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		refill_events.append(family_id)
	)

	slot.apply_chip_pickup(WIDE_SPREAD)
	if slot.active_weapon == null:
		failures.append("expected first pickup to equip Wide Spread")
	elif slot.active_weapon.family != WIDE_SPREAD:
		failures.append("expected first pickup to equip Wide Spread, got %s" % slot.active_weapon.family.family_id)
	elif !is_equal_approx(slot.active_weapon.current_energy, slot.active_weapon.max_energy):
		failures.append("expected first pickup to equip at full energy")

	if chip_events.size() != 1 or str(chip_events[0]["family_id"]) != "common_wide_spread" or !bool(chip_events[0]["granted_new_family"]):
		failures.append("expected first pickup chip event common_wide_spread granted_new_family=true")
	if !refill_events.is_empty():
		failures.append("expected first pickup not to emit typed_weapon_refilled")

	slot.free()


func _verify_same_family_refill(failures: Array[String]) -> void:
	var slot := SLOT_SCRIPT.new()
	var chip_events: Array[Dictionary] = []
	var refill_events: Array[String] = []
	var energy_events: Array[Dictionary] = []
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		chip_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
	)
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		refill_events.append(family_id)
	)
	slot.typed_weapon_energy_changed.connect(func(current_energy: float, max_energy: float) -> void:
		energy_events.append({"current_energy": current_energy, "max_energy": max_energy})
	)

	slot.equip(WIDE_SPREAD)
	var original_weapon := slot.active_weapon
	slot.active_weapon.current_energy = 34.0
	chip_events.clear()
	energy_events.clear()

	slot.apply_chip_pickup(WIDE_SPREAD)
	if slot.active_weapon != original_weapon:
		failures.append("expected same-family refill to preserve the existing TypedWeapon instance")
	if slot.active_weapon.family != WIDE_SPREAD:
		failures.append("expected same-family refill to keep Wide Spread equipped")
	if !is_equal_approx(slot.active_weapon.current_energy, slot.active_weapon.max_energy):
		failures.append("expected same-family refill to set current_energy to max_energy")
	if energy_events.size() != 1 or !is_equal_approx(float(energy_events[0]["current_energy"]), WIDE_SPREAD.normalized_max_energy()):
		failures.append("expected same-family refill to emit one energy-changed event at max")
	if chip_events.size() != 1 or str(chip_events[0]["family_id"]) != "common_wide_spread" or bool(chip_events[0]["granted_new_family"]):
		failures.append("expected same-family chip event common_wide_spread granted_new_family=false")
	if refill_events.size() != 1 or refill_events[0] != "common_wide_spread":
		failures.append("expected same-family refill to emit typed_weapon_refilled(common_wide_spread) once")

	slot.free()


func _verify_different_family_swap(failures: Array[String]) -> void:
	var slot := SLOT_SCRIPT.new()
	var chip_events: Array[Dictionary] = []
	var refill_events: Array[String] = []
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		chip_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
	)
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		refill_events.append(family_id)
	)

	slot.equip(HEAVY_SLUG)
	slot.active_weapon.current_energy = HEAVY_SLUG.normalized_max_energy() * 0.3
	chip_events.clear()

	slot.apply_chip_pickup(RAPID_STREAM)
	if slot.active_weapon.family != RAPID_STREAM:
		failures.append("expected different-family pickup to swap to Rapid Stream")
	if !is_equal_approx(slot.active_weapon.current_energy, RAPID_STREAM.normalized_max_energy()):
		failures.append("expected different-family swap to set energy to the new family's max")
	if chip_events.size() != 1 or str(chip_events[0]["family_id"]) != "common_rapid_stream" or !bool(chip_events[0]["granted_new_family"]):
		failures.append("expected swap chip event common_rapid_stream granted_new_family=true")
	if !refill_events.is_empty():
		failures.append("expected different-family swap not to emit typed_weapon_refilled")

	slot.free()


func _verify_swap_uses_new_family_max(failures: Array[String]) -> void:
	var family_a := TypedWeaponFamily.new()
	family_a.family_id = "verify_family_a"
	family_a.max_energy = 40.0

	var family_b := TypedWeaponFamily.new()
	family_b.family_id = "verify_family_b"
	family_b.max_energy = 125.0

	var slot := SLOT_SCRIPT.new()
	var refill_events: Array[String] = []
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		refill_events.append(family_id)
	)

	slot.equip(family_a)
	slot.active_weapon.current_energy = 12.0
	slot.apply_chip_pickup(family_b)
	if slot.active_weapon.family != family_b:
		failures.append("expected custom different-family pickup to swap to family_b")
	if !is_equal_approx(slot.active_weapon.current_energy, 125.0):
		failures.append("expected custom swap to use family_b max 125.0, got %.2f" % slot.active_weapon.current_energy)
	if !refill_events.is_empty():
		failures.append("expected custom different-family swap not to emit typed_weapon_refilled")

	slot.free()
