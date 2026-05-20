extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T007-pea-shooter-and-typed-weapon-damage-to-enemies"
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"
const ENEMY_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const PEA_BULLET_SCENE := preload("res://scenes/projectiles/PeaBullet.tscn")
const TYPED_PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const DEBUG_FAMILY := preload("res://data/weapons/debug_plasma.tres")
const WIDTH := 540
const HEIGHT := 960
const HIT_POSITION := Vector2(270.0, 430.0)

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
	_disable_live_spawner_for_controlled_capture()

	await process_frame
	await _capture_pea_sequence()
	await _capture_typed_sequence()

	print("Saved live T007 damage evidence from %s." % MAIN_SCENE_PATH)
	quit(0)


func _capture_pea_sequence() -> void:
	var enemy := _spawn_enemy(HIT_POSITION)
	await process_frame

	await _fire_projectile_into_enemy(PEA_BULLET_SCENE, enemy)
	await _save_capture({"file": "damage-exchange-01-pea-hit.png"})
	await _save_capture({"file": "hit-feedback-detail.png", "crop": Rect2i(170, 330, 200, 180), "scale": 3})

	for _index in 4:
		await _fire_projectile_into_enemy(PEA_BULLET_SCENE, enemy)

	await _advance_frames(3)
	await _save_capture({"file": "damage-exchange-02-pea-kill.png"})
	await _save_capture({"file": "kill-burst-detail.png", "crop": Rect2i(170, 330, 200, 200), "scale": 3})


func _capture_typed_sequence() -> void:
	await _drain_feedback_frames()
	var enemy := _spawn_enemy(HIT_POSITION + Vector2(0.0, 140.0))
	await process_frame

	await _fire_projectile_into_enemy(TYPED_PROJECTILE_SCENE, enemy, DEBUG_FAMILY)
	await _advance_frames(2)
	await _save_capture({"file": "damage-exchange-03-typed-hit.png"})
	await _fire_projectile_into_enemy(TYPED_PROJECTILE_SCENE, enemy, DEBUG_FAMILY)
	await _advance_frames(3)
	await _save_capture({"file": "damage-exchange-04-typed-kill.png"})


func _spawn_enemy(spawn_position: Vector2) -> Node2D:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.global_position = spawn_position
	_main.add_child(enemy)
	return enemy


func _fire_projectile_into_enemy(projectile_scene: PackedScene, enemy: Node2D, family: TypedWeaponFamily = null) -> void:
	if enemy == null or enemy.is_queued_for_deletion():
		return

	var projectile := projectile_scene.instantiate() as Node2D
	_main.add_child(projectile)
	projectile.global_position = enemy.global_position + Vector2(0.0, 18.0)
	if family != null and projectile.has_method("configure_from_family"):
		projectile.configure_from_family(family)

	for _frame in 16:
		await physics_frame
		if projectile == null or projectile.is_queued_for_deletion():
			return


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


func _drain_feedback_frames() -> void:
	await _advance_frames(30)


func _advance_frames(count: int) -> void:
	for _frame in count:
		await process_frame


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
