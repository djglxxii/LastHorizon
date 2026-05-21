extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const PEA_BULLET_SCENE := preload("res://scenes/projectiles/PeaBullet.tscn")
const TYPED_PROJECTILE_SCENE := preload("res://scenes/projectiles/TypedProjectile.tscn")
const DEBUG_FAMILY := preload("res://data/weapons/debug_plasma.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	var pea_result := _simulate_projectile_hit(PEA_BULLET_SCENE)
	var typed_result := _simulate_projectile_hit(TYPED_PROJECTILE_SCENE, DEBUG_FAMILY)
	var kill_result := _simulate_killing_hit()

	_verify_pea_hit(pea_result, failures)
	_verify_typed_hit(typed_result, failures)
	_verify_killing_hit(kill_result, failures)

	print("Baseline max HP: %.1f" % pea_result["max_hp"])
	print("Pea hit: %.1f -> %.1f, bullet queued=%s" % [pea_result["start_hp"], pea_result["end_hp"], pea_result["projectile_queued"]])
	print("Typed hit: %.1f -> %.1f, projectile queued=%s" % [typed_result["start_hp"], typed_result["end_hp"], typed_result["projectile_queued"]])
	print("Kill hit: killed_signal=%s, enemy queued=%s, burst spawned=%s" % [kill_result["killed_signal"], kill_result["enemy_queued"], kill_result["burst_spawned"]])
	print("Debug plasma projectile damage: %.1f" % DEBUG_FAMILY.projectile_damage)

	if failures.is_empty():
		print("DAMAGE_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _simulate_projectile_hit(projectile_scene: PackedScene, family: TypedWeaponFamily = null) -> Dictionary:
	var container := Node2D.new()
	root.add_child(container)

	var enemy := ENEMY_SCENE.instantiate()
	container.add_child(enemy)
	enemy.global_position = Vector2(270.0, 420.0)

	var projectile := projectile_scene.instantiate()
	container.add_child(projectile)
	projectile.global_position = enemy.global_position
	if family != null and projectile.has_method("configure_from_family"):
		projectile.configure_from_family(family)

	var start_hp: float = enemy.current_hp
	_emit_projectile_area_signal(projectile, enemy)
	var end_hp: float = enemy.current_hp

	var result := {
		"max_hp": enemy.max_hp,
		"start_hp": start_hp,
		"end_hp": end_hp,
		"projectile_damage": projectile.damage,
		"projectile_queued": projectile.is_queued_for_deletion(),
		"damage_number_spawned": _has_child_named(container, "DamageNumber"),
	}

	container.queue_free()
	return result


func _simulate_killing_hit() -> Dictionary:
	var container := Node2D.new()
	root.add_child(container)

	var enemy := ENEMY_SCENE.instantiate()
	container.add_child(enemy)
	enemy.global_position = Vector2(270.0, 420.0)
	enemy.current_hp = 1.0

	var killed_signal := [false]
	enemy.killed.connect(func() -> void:
		killed_signal[0] = true
	)

	var projectile := PEA_BULLET_SCENE.instantiate()
	container.add_child(projectile)
	projectile.global_position = enemy.global_position

	_emit_projectile_area_signal(projectile, enemy)

	var result := {
		"killed_signal": killed_signal[0],
		"enemy_queued": enemy.is_queued_for_deletion(),
		"projectile_queued": projectile.is_queued_for_deletion(),
		"burst_spawned": _has_child_named(container, "PixelBurst"),
	}

	container.queue_free()
	return result


func _emit_projectile_area_signal(projectile: Node, enemy: Node) -> void:
	var hurtbox := enemy.get_node("Hurtbox") as Area2D
	projectile._on_hitbox_area_entered(hurtbox)


func _verify_pea_hit(result: Dictionary, failures: Array[String]) -> void:
	if !is_equal_approx(float(result["max_hp"]), 2.5):
		failures.append("expected BaselineEnemy.max_hp = 2.5, got %.1f" % result["max_hp"])
	if !is_equal_approx(float(result["projectile_damage"]), 1.0):
		failures.append("expected pea bullet damage = 1.0, got %.1f" % result["projectile_damage"])
	if !is_equal_approx(float(result["start_hp"]), 2.5) or !is_equal_approx(float(result["end_hp"]), 1.5):
		failures.append("expected pea hit to move HP 2.5 -> 1.5, got %.1f -> %.1f" % [result["start_hp"], result["end_hp"]])
	if !bool(result["projectile_queued"]):
		failures.append("expected pea bullet to be queued for free after hit")
	if !bool(result["damage_number_spawned"]):
		failures.append("expected pea hit to spawn a damage number")


func _verify_typed_hit(result: Dictionary, failures: Array[String]) -> void:
	if !is_equal_approx(DEBUG_FAMILY.projectile_damage, 3.0):
		failures.append("expected debug plasma projectile_damage = 3.0, got %.1f" % DEBUG_FAMILY.projectile_damage)
	if !is_equal_approx(float(result["projectile_damage"]), 3.0):
		failures.append("expected typed projectile damage = 3.0, got %.1f" % result["projectile_damage"])
	if !is_equal_approx(float(result["start_hp"]), 2.5) or !is_equal_approx(float(result["end_hp"]), 0.0):
		failures.append("expected typed hit to kill HP 2.5 -> 0.0, got %.1f -> %.1f" % [result["start_hp"], result["end_hp"]])
	if !bool(result["projectile_queued"]):
		failures.append("expected typed projectile to be queued for free after hit")


func _verify_killing_hit(result: Dictionary, failures: Array[String]) -> void:
	if !bool(result["killed_signal"]):
		failures.append("expected enemy killed signal on lethal hit")
	if !bool(result["enemy_queued"]):
		failures.append("expected enemy to be queued for free on lethal hit")
	if !bool(result["projectile_queued"]):
		failures.append("expected lethal pea bullet to be queued for free")
	if !bool(result["burst_spawned"]):
		failures.append("expected lethal hit to spawn a pixel burst")


func _has_child_named(parent: Node, child_name: String) -> bool:
	for child in parent.get_children():
		if child.name == child_name:
			return true
	return false
