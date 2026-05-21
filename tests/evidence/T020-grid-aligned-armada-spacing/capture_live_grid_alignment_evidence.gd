extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T020-grid-aligned-armada-spacing"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const WIDTH := 540
const HEIGHT := 960
const CAPTURES := [
	{"file": "grid-aligned-armada.png", "time": 20.0},
	{"file": "stagger-detail.png", "time": 20.0, "crop": Rect2i(20, 0, 500, 300), "scale": 2},
]

var _main: Node


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	if main_scene == null:
		push_error("Unable to load %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	_main = main_scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	await process_frame
	_disable_non_armada_motion()

	var current_time := 0.0
	for capture in CAPTURES:
		var target_time := float(capture["time"])
		while current_time < target_time:
			await physics_frame
			await process_frame
			current_time += root.get_process_delta_time()

		await _save_capture(capture)

	print("Saved live T020 grid-alignment evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _disable_non_armada_motion() -> void:
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
