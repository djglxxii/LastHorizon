extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T008-defense-grid-integrity-meter-and-leak-damage-and-run-end"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const ENEMY_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const PEA_BULLET_SCENE := preload("res://scenes/projectiles/PeaBullet.tscn")
const WIDTH := 540
const HEIGHT := 960

var _main: Node


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	ProjectSettings.set_setting("last_horizon/evidence_capture", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	call_deferred("_run")


func _run() -> void:
	await _load_fresh_main()
	await _save_capture({"file": "grid-meter-hud.png"})
	await _capture_leak_feedback()
	await _capture_run_end_and_restart()

	print("Saved live T008 Grid evidence from %s." % MAIN_SCENE_PATH)
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


func _capture_leak_feedback() -> void:
	_disable_live_spawner_for_controlled_capture()
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.position = Vector2(270.0, 897.0)
	enemy.set("planet_line_y", 900.0)
	_main.add_child(enemy)
	await process_frame
	await _save_capture({"file": "leak-feedback-01-before.png"})

	enemy.set("planet_line_y", 896.0)
	await physics_frame
	await process_frame
	await _save_capture({"file": "leak-feedback-02-impact.png"})

	await _advance_frames(12)
	await _save_capture({"file": "leak-feedback-03-after-drop.png"})


func _capture_run_end_and_restart() -> void:
	await _load_fresh_main()
	await _advance_seconds(2.5)
	var grid := _main.get_node("%DefenseGrid")
	for _index in 10:
		grid.call("apply_leak_damage", 10.0, Vector2(270.0, 900.0))

	await process_frame
	await _save_capture({"file": "run-end-overlay.png"})

	var overlay := _main.get_node("%RunEndOverlay")
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_R
	overlay._unhandled_input(event)
	await process_frame
	await process_frame
	_main = current_scene
	await _advance_seconds(2.5)
	await _save_capture({"file": "restart-restores-grid.png"})


func _disable_live_spawner_for_controlled_capture() -> void:
	var spawner := _main.get_node_or_null("EnemySpawner")
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


func _advance_frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _advance_seconds(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
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
