extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T006-baseline-enemy-and-descending-formation"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const WIDTH := 540
const HEIGHT := 960
const TYPED_FIRE_START_TIME := 3.55
const CAPTURES := [
	{"file": "armada-descent-01-entering.png", "time": 1.2},
	{"file": "armada-descent-02-two-blocks.png", "time": 4.3},
	{"file": "armada-descent-03-midfield.png", "time": 10.9},
	{"file": "armada-descent-04-exiting.png", "time": 19.4},
	{"file": "block-formation.png", "time": 4.3},
	{"file": "sway-detail.png", "time": 4.3, "crop": Rect2i(40, 0, 460, 220), "scale": 2},
]

var _main: Node
var _typed_fire_pressed := false


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

	var current_time := 0.0
	for capture in CAPTURES:
		var target_time := float(capture["time"])
		while current_time < target_time:
			await process_frame
			current_time += root.get_process_delta_time()
			if !_typed_fire_pressed and current_time >= TYPED_FIRE_START_TIME:
				Input.action_press("fire_typed")
				_typed_fire_pressed = true

		await _save_capture(capture)

	Input.action_release("fire_typed")
	print("Saved live T006 armada evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


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
