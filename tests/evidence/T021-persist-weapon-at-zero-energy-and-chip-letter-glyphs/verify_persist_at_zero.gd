extends SceneTree

const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const CHIP_SCENE := preload("res://scenes/pickups/WeaponChip.tscn")

const DEBUG_PLASMA := preload("res://data/weapons/debug_plasma.tres")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const PIERCING_LANCE := preload("res://data/weapons/common_piercing_lance.tres")
const HEAVY_SLUG := preload("res://data/weapons/common_heavy_slug.tres")
const RAPID_STREAM := preload("res://data/weapons/common_rapid_stream.tres")

const FAMILY_GLYPHS := {
	"debug_plasma": "D",
	"common_wide_spread": "S",
	"common_piercing_lance": "P",
	"common_heavy_slug": "H",
	"common_rapid_stream": "R",
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_drain_persists_at_zero()
	await _verify_same_family_refill_at_zero()
	await _verify_different_family_swap_at_zero()
	await _verify_fuel_cell_resume_at_zero()
	_verify_expired_signal_retired()
	await _verify_letter_glyph_resources_and_scene()

	if failures.is_empty():
		print("PERSIST_AT_ZERO_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_drain_persists_at_zero() -> void:
	var harness := _new_slot_harness()
	var slot: Node = harness["slot"]
	var bullets: Node = harness["bullets"]
	var family := _new_family("A", 10.0, 5.0)
	var silent_events: Array[String] = []
	slot.typed_weapon_silent.connect(func(family_id: String) -> void:
		silent_events.append(family_id)
	)

	slot.equip(family)
	while slot.current_energy() > 0.0:
		if !slot._fire_once():
			failures.append("expected equipped slot to fire until energy reaches zero")
			break

	if !slot.has_weapon():
		failures.append("expected slot.has_weapon() to stay true at zero energy")
	if slot.current_family_id() != "A":
		failures.append("expected family A to persist at zero energy, got %s" % slot.current_family_id())
	if silent_events.size() != 1 or silent_events[0] != "A":
		failures.append("expected exactly one typed_weapon_silent(A) after drain, got %s" % str(silent_events))

	var bullet_count_before := bullets.get_child_count()
	if slot._fire_once():
		failures.append("expected _fire_once at zero energy to return false")
	if bullets.get_child_count() != bullet_count_before:
		failures.append("expected _fire_once at zero energy to spawn no projectile")
	if !slot.has_weapon() or slot.current_family_id() != "A":
		failures.append("expected zero-energy fire no-op to preserve family A")
	if silent_events.size() != 1:
		failures.append("expected repeated zero-energy fire to suppress duplicate typed_weapon_silent")

	harness["root"].queue_free()
	await process_frame


func _verify_same_family_refill_at_zero() -> void:
	var harness := _new_slot_harness()
	var slot: Node = harness["slot"]
	var family := _new_family("A", 10.0, 5.0)
	var refill_events: Array[String] = []
	var resumed_events: Array[String] = []
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		refill_events.append(family_id)
	)
	slot.typed_weapon_resumed.connect(func(family_id: String) -> void:
		resumed_events.append(family_id)
	)

	slot.equip(family)
	_drain_to_zero(slot)
	refill_events.clear()
	resumed_events.clear()

	slot.apply_chip_pickup(family)
	if slot.current_family_id() != "A":
		failures.append("expected same-family chip at zero to preserve family A")
	if !is_equal_approx(slot.current_energy(), slot.max_energy()):
		failures.append("expected same-family chip at zero to refill to max")
	if refill_events.size() != 1 or refill_events[0] != "A":
		failures.append("expected typed_weapon_refilled(A) once at zero, got %s" % str(refill_events))
	if resumed_events.size() != 1 or resumed_events[0] != "A":
		failures.append("expected typed_weapon_resumed(A) once after same-family refill, got %s" % str(resumed_events))

	harness["root"].queue_free()
	await process_frame


func _verify_different_family_swap_at_zero() -> void:
	var harness := _new_slot_harness()
	var slot: Node = harness["slot"]
	var family_a := _new_family("A", 10.0, 5.0)
	var family_b := _new_family("B", 16.0, 4.0)
	var chip_events: Array[Dictionary] = []
	var resumed_events: Array[String] = []
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		chip_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
	)
	slot.typed_weapon_resumed.connect(func(family_id: String) -> void:
		resumed_events.append(family_id)
	)

	slot.equip(family_a)
	_drain_to_zero(slot)
	chip_events.clear()
	resumed_events.clear()

	slot.apply_chip_pickup(family_b)
	if slot.current_family_id() != "B":
		failures.append("expected different-family chip at zero to swap to family B")
	if !is_equal_approx(slot.current_energy(), 16.0):
		failures.append("expected different-family swap at zero to fill B to max, got %.2f" % slot.current_energy())
	if chip_events.size() != 1 or str(chip_events[0]["family_id"]) != "B" or !bool(chip_events[0]["granted_new_family"]):
		failures.append("expected chip_pickup_applied(B, true) once at zero, got %s" % str(chip_events))
	if resumed_events.size() != 1 or resumed_events[0] != "B":
		failures.append("expected typed_weapon_resumed(B) once after zero-energy swap, got %s" % str(resumed_events))

	harness["root"].queue_free()
	await process_frame


func _verify_fuel_cell_resume_at_zero() -> void:
	var harness := _new_slot_harness()
	var slot: Node = harness["slot"]
	var family := _new_family("A", 100.0, 50.0)
	var partial_events: Array[Dictionary] = []
	var resumed_events: Array[String] = []
	slot.typed_weapon_partial_refilled.connect(func(family_id: String, amount_restored: float) -> void:
		partial_events.append({"family_id": family_id, "amount_restored": amount_restored})
	)
	slot.typed_weapon_resumed.connect(func(family_id: String) -> void:
		resumed_events.append(family_id)
	)

	slot.equip(family)
	_drain_to_zero(slot)
	partial_events.clear()
	resumed_events.clear()

	slot.apply_fuel_cell_pickup()
	if slot.current_family_id() != "A":
		failures.append("expected fuel-cell refill at zero to preserve family A")
	if !is_equal_approx(slot.current_energy(), 30.0):
		failures.append("expected fuel-cell refill at zero to restore 30.0 energy, got %.2f" % slot.current_energy())
	if partial_events.size() != 1 or str(partial_events[0]["family_id"]) != "A" or !is_equal_approx(float(partial_events[0]["amount_restored"]), 30.0):
		failures.append("expected typed_weapon_partial_refilled(A, 30.0) once at zero, got %s" % str(partial_events))
	if resumed_events.size() != 1 or resumed_events[0] != "A":
		failures.append("expected typed_weapon_resumed(A) once after fuel-cell refill, got %s" % str(resumed_events))

	harness["root"].queue_free()
	await process_frame


func _verify_expired_signal_retired() -> void:
	var slot := SLOT_SCRIPT.new()
	if slot.has_signal("typed_weapon_expired"):
		failures.append("expected typed_weapon_expired signal to be retired")
	slot.free()


func _verify_letter_glyph_resources_and_scene() -> void:
	for family in [DEBUG_PLASMA, WIDE_SPREAD, PIERCING_LANCE, HEAVY_SLUG, RAPID_STREAM]:
		var expected := str(FAMILY_GLYPHS[family.family_id])
		if family.letter_glyph != expected:
			failures.append("expected %s letter_glyph=%s, got %s" % [family.family_id, expected, family.letter_glyph])

		var chip := CHIP_SCENE.instantiate() as WeaponChip
		root.add_child(chip)
		chip.set_family(family)
		await process_frame
		var label := chip.get_node_or_null("LetterGlyph") as Label
		if label == null:
			failures.append("expected WeaponChip to contain LetterGlyph label")
		elif !label.visible or label.text != expected:
			failures.append("expected %s chip LetterGlyph visible with text %s, got visible=%s text=%s" % [family.family_id, expected, label.visible, label.text])
		chip.queue_free()
		await process_frame

	var no_glyph_family := _new_family("no_glyph", 10.0, 1.0)
	var chip := CHIP_SCENE.instantiate() as WeaponChip
	root.add_child(chip)
	chip.set_family(no_glyph_family)
	await process_frame
	var label := chip.get_node_or_null("LetterGlyph") as Label
	if label == null:
		failures.append("expected no-glyph WeaponChip to contain LetterGlyph label")
	elif label.visible:
		failures.append("expected no-glyph WeaponChip LetterGlyph to be hidden")
	chip.queue_free()
	await process_frame

	var empty_chip := CHIP_SCENE.instantiate() as WeaponChip
	root.add_child(empty_chip)
	await process_frame
	label = empty_chip.get_node_or_null("LetterGlyph") as Label
	if label == null:
		failures.append("expected empty WeaponChip to contain LetterGlyph label")
	elif label.visible:
		failures.append("expected empty WeaponChip LetterGlyph to be hidden")
	empty_chip.queue_free()
	await process_frame


func _new_slot_harness() -> Dictionary:
	var harness_root := Node2D.new()
	var bullets := Node2D.new()
	bullets.name = "Bullets"
	var slot := SLOT_SCRIPT.new()
	slot.name = "TypedWeaponSlot"
	slot.projectile_scene = PROJECTILE_SCENE
	slot.bullet_parent_path = NodePath("../Bullets")
	harness_root.add_child(bullets)
	harness_root.add_child(slot)
	root.add_child(harness_root)
	return {"root": harness_root, "slot": slot, "bullets": bullets}


func _drain_to_zero(slot: Node) -> void:
	var guard := 100
	while slot.current_energy() > 0.0 and guard > 0:
		slot._fire_once()
		guard -= 1
	if guard <= 0:
		failures.append("drain-to-zero guard exhausted for %s" % slot.current_family_id())


func _new_family(family_id: String, max_energy: float, firing_cost: float) -> TypedWeaponFamily:
	var family := TypedWeaponFamily.new()
	family.family_id = family_id
	family.display_name = family_id
	family.max_energy = max_energy
	family.firing_cost = firing_cost
	family.fire_interval = 0.01
	return family
