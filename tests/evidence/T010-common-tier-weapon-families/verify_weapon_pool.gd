extends SceneTree

const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const CARRIER_SCENE := preload("res://scenes/enemies/WeaponChipCarrier.tscn")
const CARRIER_SPAWNER_SCRIPT := preload("res://src/carriers/carrier_spawner.gd")

const FAMILIES := [
	preload("res://data/weapons/debug_plasma.tres"),
	preload("res://data/weapons/common_wide_spread.tres"),
	preload("res://data/weapons/common_piercing_lance.tres"),
	preload("res://data/weapons/common_heavy_slug.tres"),
	preload("res://data/weapons/common_rapid_stream.tres"),
]

const FAMILY_IDS := [
	"debug_plasma",
	"common_wide_spread",
	"common_piercing_lance",
	"common_heavy_slug",
	"common_rapid_stream",
]


class DamageTarget:
	extends Node2D

	var total_damage := 0.0
	var hit_count := 0

	func take_damage(amount: float, _hit_position := Vector2.INF) -> void:
		total_damage += amount
		hit_count += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_verify_family_resources(failures)
	_verify_pickup_semantics(failures)
	await _verify_pierce_damages_each_target_once(failures)
	await _verify_spread_fires_three_projectiles_for_one_cost(failures)
	await _verify_uniform_carrier_pool_rolls(failures)

	if failures.is_empty():
		print("WEAPON_POOL_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_family_resources(failures: Array[String]) -> void:
	for family in FAMILIES:
		if family == null:
			failures.append("expected family resource to load")
			continue
		if family.family_id.is_empty():
			failures.append("expected family_id to be non-empty")
		if !FAMILY_IDS.has(family.family_id):
			failures.append("unexpected family_id %s" % family.family_id)
		if family.display_name.is_empty():
			failures.append("expected %s display_name to be non-empty" % family.family_id)
		if family.normalized_max_energy() <= 0.0:
			failures.append("expected %s max_energy to be positive" % family.family_id)
		if family.tint_color.a <= 0.0 or family.tint_color.r + family.tint_color.g + family.tint_color.b <= 0.0:
			failures.append("expected %s tint_color to be non-zero" % family.family_id)
		if family.projectile_sprite == null:
			failures.append("expected %s projectile_sprite to load" % family.family_id)


func _verify_pickup_semantics(failures: Array[String]) -> void:
	var heavy := _family("common_heavy_slug")
	var rapid := _family("common_rapid_stream")

	for family in FAMILIES:
		var empty_slot := SLOT_SCRIPT.new()
		var empty_events: Array[Dictionary] = []
		empty_slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
			empty_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
		)
		empty_slot.apply_chip_pickup(family)
		if empty_slot.active_weapon == null:
			failures.append("expected first chip pickup to equip %s" % family.family_id)
		elif empty_slot.active_weapon.family != family:
			failures.append("expected first chip pickup to equip %s" % family.family_id)
		if empty_events.size() != 1 or str(empty_events[0]["family_id"]) != family.family_id or !bool(empty_events[0]["granted_new_family"]):
			failures.append("expected empty-slot chip event %s granted_new_family=true" % family.family_id)
		empty_slot.free()

	var held_slot := SLOT_SCRIPT.new()
	var held_events: Array[Dictionary] = []
	held_slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		held_events.append({"family_id": family_id, "granted_new_family": granted_new_family})
	)
	held_slot.equip(heavy)
	held_slot.active_weapon.current_energy = 10.0
	held_slot.apply_chip_pickup(rapid)
	if held_slot.active_weapon.family != rapid:
		failures.append("expected T011 mismatch pickup to swap to Rapid Stream")
	if !is_equal_approx(held_slot.active_weapon.current_energy, held_slot.active_weapon.max_energy):
		failures.append("expected mismatch pickup to equip swapped family at max")
	if held_events.size() != 1 or str(held_events[0]["family_id"]) != "common_rapid_stream" or !bool(held_events[0]["granted_new_family"]):
		failures.append("expected mismatch pickup event common_rapid_stream granted_new_family=true")
	held_slot.free()


func _verify_pierce_damages_each_target_once(failures: Array[String]) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	root.add_child(projectile)
	projectile.configure_from_family(_family("common_piercing_lance"))

	var target := DamageTarget.new()
	var area := Area2D.new()
	target.add_child(area)
	root.add_child(target)
	await process_frame

	projectile._on_hitbox_area_entered(area)
	projectile._on_hitbox_area_entered(area)
	if target.hit_count != 1:
		failures.append("expected pierce projectile to damage the same target once, got %d" % target.hit_count)
	if projectile.is_queued_for_deletion():
		failures.append("expected pierce projectile to remain alive after hit")

	projectile.queue_free()
	target.queue_free()
	await process_frame


func _verify_spread_fires_three_projectiles_for_one_cost(failures: Array[String]) -> void:
	var container := Node2D.new()
	var bullets := Node2D.new()
	bullets.name = "Bullets"
	root.add_child(container)
	container.add_child(bullets)

	var slot := SLOT_SCRIPT.new()
	slot.projectile_scene = PROJECTILE_SCENE
	slot.bullet_parent_path = NodePath("../Bullets")
	container.add_child(slot)
	slot.equip(_family("common_wide_spread"))
	var before_energy := slot.active_weapon.current_energy

	if !slot._fire_once():
		failures.append("expected Wide Spread _fire_once to return true")

	var fired_count := bullets.get_child_count()
	if fired_count != 3:
		failures.append("expected Wide Spread to spawn 3 projectiles, got %d" % fired_count)
	var expected_energy := before_energy - _family("common_wide_spread").firing_cost
	if !is_equal_approx(slot.active_weapon.current_energy, expected_energy):
		failures.append("expected Wide Spread to deduct one firing_cost, got %.2f expected %.2f" % [slot.active_weapon.current_energy, expected_energy])

	container.queue_free()
	await process_frame


func _verify_uniform_carrier_pool_rolls(failures: Array[String]) -> void:
	seed(12010)
	var spawner := CARRIER_SPAWNER_SCRIPT.new()
	spawner.carrier_scene = CARRIER_SCENE
	spawner.weapon_pool.assign(FAMILIES)
	root.add_child(spawner)

	var counts := {}
	for family in FAMILIES:
		counts[family.family_id] = 0

	for _index in range(100):
		var carrier := spawner._spawn_carrier()
		if carrier == null:
			failures.append("expected carrier pool roll to spawn a carrier")
			continue
		var rolled_family = carrier.get("family")
		if rolled_family == null:
			failures.append("expected spawned carrier to have a rolled family")
		else:
			counts[rolled_family.family_id] = int(counts[rolled_family.family_id]) + 1
		carrier.queue_free()

	for family_id in FAMILY_IDS:
		var count := int(counts[family_id])
		print("carrier_pool_count %s %d" % [family_id, count])
		if count < 10 or count > 30:
			failures.append("expected %s count to land within broad uniform bounds, got %d" % [family_id, count])

	spawner.queue_free()
	await process_frame


func _family(family_id: String) -> TypedWeaponFamily:
	for family in FAMILIES:
		if family.family_id == family_id:
			return family

	return null
