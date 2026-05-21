extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T010-common-tier-weapon-families"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const CARRIER_SCENE := preload("res://scenes/enemies/WeaponChipCarrier.tscn")
const CHIP_SCENE := preload("res://scenes/pickups/WeaponChip.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const WIDTH := 540
const HEIGHT := 960

const FAMILIES := [
	preload("res://data/weapons/debug_plasma.tres"),
	preload("res://data/weapons/common_wide_spread.tres"),
	preload("res://data/weapons/common_piercing_lance.tres"),
	preload("res://data/weapons/common_heavy_slug.tres"),
	preload("res://data/weapons/common_rapid_stream.tres"),
]

var _main: Node


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _capture_carrier_and_chip_tints()
	await _capture_wide_spread()
	await _capture_piercing_lance()
	await _capture_heavy_slug()
	await _capture_rapid_stream()

	print("Saved live T010 weapon-pool evidence from %s." % MAIN_SCENE_PATH)
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


func _capture_carrier_and_chip_tints() -> void:
	await _load_fresh_main()

	var xs := [78.0, 174.0, 270.0, 366.0, 462.0]
	for index in range(FAMILIES.size()):
		var carrier := CARRIER_SCENE.instantiate()
		carrier.set_family(FAMILIES[index])
		carrier.global_position = Vector2(xs[index], 240.0)
		_main.add_child(carrier)
		carrier.set_physics_process(false)

		var chip := CHIP_SCENE.instantiate()
		chip.set_family(FAMILIES[index])
		chip.global_position = Vector2(xs[index], 330.0)
		_main.add_child(chip)
		chip.set_physics_process(false)

	await _save_capture({"file": "carrier-tint-readout.png"})
	await _save_capture({"file": "chip-color-roster.png", "crop": Rect2i(40, 280, 460, 110), "scale": 2})


func _capture_wide_spread() -> void:
	await _load_fresh_main()
	await _equip_and_fire(_family("common_wide_spread"), 1, 0.18)
	await _save_capture({"file": "wide-spread-clip.png"})


func _capture_piercing_lance() -> void:
	await _load_fresh_main()
	for y in [365.0, 285.0, 205.0]:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.global_position = Vector2(270.0, y)
		_main.add_child(enemy)
		enemy.set_physics_process(false)

	await _equip_and_fire(_family("common_piercing_lance"), 1, 0.62)
	await _save_capture({"file": "piercing-lance-clip.png"})


func _capture_heavy_slug() -> void:
	await _load_fresh_main()
	await _equip_and_fire(_family("common_heavy_slug"), 1, 0.32)
	await _save_capture({"file": "heavy-slug-clip.png"})


func _capture_rapid_stream() -> void:
	await _load_fresh_main()
	await _equip_and_fire(_family("common_rapid_stream"), 8, 0.045)
	await _save_capture({"file": "rapid-stream-clip.png"})


func _equip_and_fire(family: TypedWeaponFamily, shot_count: int, advance_per_shot: float) -> void:
	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(family)
	await process_frame

	for _index in range(shot_count):
		slot._fire_once()
		await _advance_seconds(advance_per_shot)


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

	for bullet in _main.find_children("PeaBullet", "", true, false):
		bullet.queue_free()


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


func _family(family_id: String) -> TypedWeaponFamily:
	for family in FAMILIES:
		if family.family_id == family_id:
			return family

	return null
