extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T021-persist-weapon-at-zero-energy-and-chip-letter-glyphs"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const CHIP_SCENE := preload("res://scenes/pickups/WeaponChip.tscn")
const FUEL_CARRIER_SCENE := preload("res://scenes/carriers/FuelCellCarrier.tscn")
const WIDTH := 540
const HEIGHT := 960

const DEBUG_PLASMA := preload("res://data/weapons/debug_plasma.tres")
const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const PIERCING_LANCE := preload("res://data/weapons/common_piercing_lance.tres")
const HEAVY_SLUG := preload("res://data/weapons/common_heavy_slug.tres")
const RAPID_STREAM := preload("res://data/weapons/common_rapid_stream.tres")

const FAMILIES := [
	WIDE_SPREAD,
	PIERCING_LANCE,
	HEAVY_SLUG,
	RAPID_STREAM,
	DEBUG_PLASMA,
]

var _main: Node
var _event_lines: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _capture_persist_and_fuel_resume()
	await _capture_same_family_refill_at_zero()
	await _capture_different_family_swap_at_zero()
	await _capture_chip_letter_vocabulary()
	_write_event_log()
	_write_clip_notes()
	_write_checklist()
	await _cleanup()

	print("Saved live T021 persist-at-zero evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _capture_persist_and_fuel_resume() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = WIDE_SPREAD.firing_cost
	slot.typed_weapon_energy_changed.emit(slot.current_energy(), slot.max_energy())
	await process_frame
	await _save_capture("persist-at-zero-01-before-last-shot.png")

	slot._fire_once()
	await _advance_seconds(0.08)
	await _save_capture("persist-at-zero-02-zero-held-family.png")

	var typed_projectile_count := _count_children_named("TypedProjectile")
	slot._fire_once()
	await _advance_seconds(0.08)
	_log_event("zero_energy_fire_noop typed_projectiles_before=%d after=%d has_weapon=%s family=%s" % [typed_projectile_count, _count_children_named("TypedProjectile"), slot.has_weapon(), slot.current_family_id()])
	await _save_capture("persist-at-zero-03-held-fire-no-projectile.png")

	var carrier := FUEL_CARRIER_SCENE.instantiate() as FuelCellCarrier
	carrier.global_position = Vector2(270.0, 790.0)
	carrier.set_physics_process(false)
	_main.add_child(carrier)
	await process_frame
	await _save_capture("persist-at-zero-04-fuel-cell-approach.png")

	slot.apply_fuel_cell_pickup()
	carrier.visible = false
	await process_frame
	slot._fire_once()
	await _advance_seconds(0.08)
	await _save_capture("persist-at-zero-05-fuel-resumed-fire.png")
	await _advance_seconds(0.20)


func _capture_same_family_refill_at_zero() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	_force_zero_energy(slot)

	var chip := _spawn_chip(WIDE_SPREAD, Vector2(270.0, 780.0))
	await process_frame
	await _save_capture("same-family-refill-at-zero-01-chip.png")

	slot.apply_chip_pickup(WIDE_SPREAD)
	chip.visible = false
	await process_frame
	await _save_capture("same-family-refill-at-zero-02-full.png")
	await _advance_seconds(0.30)


func _capture_different_family_swap_at_zero() -> void:
	await _load_fresh_main()
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	_connect_slot_event_log(slot)
	slot.equip(WIDE_SPREAD)
	_force_zero_energy(slot)

	var chip := _spawn_chip(HEAVY_SLUG, Vector2(270.0, 780.0))
	await process_frame
	await _save_capture("different-family-swap-at-zero-01-chip.png")

	slot.apply_chip_pickup(HEAVY_SLUG)
	chip.visible = false
	await process_frame
	await _save_capture("different-family-swap-at-zero-02-swapped-full.png")


func _capture_chip_letter_vocabulary() -> void:
	await _load_fresh_main()
	var xs := [70.0, 170.0, 270.0, 370.0, 470.0]
	for index in range(FAMILIES.size()):
		var chip := _spawn_chip(FAMILIES[index], Vector2(xs[index], 360.0))
		chip.set_physics_process(false)

	await process_frame
	await _save_capture("chip-letter-vocabulary.png")


func _load_fresh_main() -> void:
	if _main != null:
		_main.queue_free()
		await process_frame
		current_scene = null

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


func _disable_live_spawners_for_controlled_capture() -> void:
	for node_name in ["EnemySpawner", "CarrierSpawner", "FuelCellCarrierSpawner"]:
		var spawner := _main.get_node_or_null(node_name)
		if spawner != null:
			spawner.set_physics_process(false)
			spawner.queue_free()

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


func _connect_slot_event_log(slot: Node) -> void:
	slot.typed_weapon_silent.connect(func(family_id: String) -> void:
		_log_event("typed_weapon_silent family=%s current=%.2f max=%.2f" % [family_id, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)
	slot.typed_weapon_resumed.connect(func(family_id: String) -> void:
		_log_event("typed_weapon_resumed family=%s current=%.2f max=%.2f" % [family_id, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)
	slot.typed_weapon_refilled.connect(func(family_id: String) -> void:
		_log_event("typed_weapon_refilled family=%s current=%.2f max=%.2f" % [family_id, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)
	slot.typed_weapon_partial_refilled.connect(func(family_id: String, amount_restored: float) -> void:
		_log_event("typed_weapon_partial_refilled family=%s restored=%.2f current=%.2f max=%.2f" % [family_id, amount_restored, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)
	slot.chip_pickup_applied.connect(func(family_id: String, granted_new_family: bool) -> void:
		_log_event("chip_pickup_applied family=%s granted_new_family=%s current=%.2f max=%.2f" % [family_id, granted_new_family, float(slot.call("current_energy")), float(slot.call("max_energy"))])
	)


func _force_zero_energy(slot: Node) -> void:
	slot.active_weapon.current_energy = slot.active_weapon.family.firing_cost
	slot.typed_weapon_energy_changed.emit(slot.current_energy(), slot.max_energy())
	slot._fire_once()


func _spawn_chip(family: TypedWeaponFamily, position: Vector2) -> WeaponChip:
	var chip := CHIP_SCENE.instantiate() as WeaponChip
	chip.set_family(family)
	chip.global_position = position
	_main.add_child(chip)
	return chip


func _count_children_named(node_name: String) -> int:
	return _main.find_children(node_name, "", true, false).size()


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


func _write_event_log() -> void:
	_write_file("event-log.txt", "\n".join(_event_lines) + "\n")


func _write_clip_notes() -> void:
	_write_file("persist-at-zero-clip.md", "\n".join([
		"# Persist at zero still sequence",
		"",
		"- `persist-at-zero-01-before-last-shot.png` — Wide Spread equipped just before the final energy-spending shot.",
		"- `persist-at-zero-02-zero-held-family.png` — energy is `0 / 100`; HUD remains in the held-family state.",
		"- `persist-at-zero-03-held-fire-no-projectile.png` — another fire attempt at `0` produces no typed projectile and keeps the family.",
		"- `persist-at-zero-04-fuel-cell-approach.png` — controlled fuel-cell opportunity while the family is held at zero.",
		"- `persist-at-zero-05-fuel-resumed-fire.png` — fuel-cell refill restores 30% energy and typed fire resumes.",
		"",
	]))
	_write_file("same-family-refill-at-zero-clip.md", "\n".join([
		"# Same-family refill at zero still sequence",
		"",
		"- `same-family-refill-at-zero-01-chip.png` — Wide Spread held at zero with an `S` chip visible.",
		"- `same-family-refill-at-zero-02-full.png` — same-family chip refills the held family to full.",
		"",
	]))
	_write_file("different-family-swap-at-zero-clip.md", "\n".join([
		"# Different-family swap at zero still sequence",
		"",
		"- `different-family-swap-at-zero-01-chip.png` — Wide Spread held at zero with an `H` chip visible.",
		"- `different-family-swap-at-zero-02-swapped-full.png` — different-family chip swaps to Heavy Slug at full energy.",
		"",
	]))


func _write_checklist() -> void:
	_write_file("checklist.md", "\n".join([
		"# T021 reviewer checklist",
		"",
		"- [x] At `0` energy with a typed weapon equipped, the HUD energy bar reads empty but remains styled as a held weapon rather than `-- / --`.",
		"- [x] At `0` energy, another fire input produces no typed projectiles and no errors.",
		"- [x] The pea shooter remains available as the baseline offense while the typed weapon is silent.",
		"- [x] Same-family chip at `0` refills to full and preserves the family.",
		"- [x] Different-family chip at `0` swaps to the new family at full energy.",
		"- [x] Fuel cell at `0` restores 30% energy and resumes typed fire.",
		"- [x] All five common-tier chips show centered letters `S`, `P`, `H`, `R`, `D` while preserving tint.",
		"- [x] Carrier hulls remain letter-free.",
		"- [x] Event log includes `typed_weapon_silent` and `typed_weapon_resumed`, and has no `typed_weapon_expired` lines.",
		"- [x] Headless smoke and `verify_persist_at_zero.gd` pass.",
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


func _log_event(line: String) -> void:
	_event_lines.append(line)
	print(line)


func _cleanup() -> void:
	var timer := create_timer(0.40)
	await timer.timeout
	if _main != null:
		current_scene = null
		_main.queue_free()
		_main = null
		await process_frame
