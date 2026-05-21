extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T011-same-family-refill-different-family-swap-at-full"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const WIDTH := 540
const HEIGHT := 960

const WIDE_SPREAD := preload("res://data/weapons/common_wide_spread.tres")
const HEAVY_SLUG := preload("res://data/weapons/common_heavy_slug.tres")
const RAPID_STREAM := preload("res://data/weapons/common_rapid_stream.tres")

var _main: Node


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _capture_same_family_refill()
	await _capture_different_family_swap()

	print("Saved live T011 refill/swap evidence from %s." % MAIN_SCENE_PATH)
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


func _capture_same_family_refill() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(WIDE_SPREAD)
	slot.active_weapon.current_energy = 38.0
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	await process_frame

	slot.apply_chip_pickup(WIDE_SPREAD)
	await process_frame
	await _save_capture("same-family-refill-clip.png")


func _capture_different_family_swap() -> void:
	await _load_fresh_main()

	var player := _main.get_node("Player") as Node2D
	player.global_position = Vector2(270.0, 850.0)
	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(HEAVY_SLUG)
	slot.active_weapon.current_energy = 30.0
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)
	await process_frame

	slot.apply_chip_pickup(RAPID_STREAM)
	await process_frame
	slot._fire_once()
	await _advance_seconds(0.12)
	await _save_capture("different-family-swap-clip.png")


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
