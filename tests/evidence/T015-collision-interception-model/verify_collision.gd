extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const BASELINE_SCENE := preload("res://scenes/enemies/BaselineEnemy.tscn")
const ELITE_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const SLOT_SCRIPT := preload("res://src/player/typed_weapon_slot.gd")

var failures: Array[String] = []


class DummyHud:
	extends Node

	func flash_collision() -> void:
		pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_full_energy_baseline_collision()
	await _verify_partial_energy_elite_collision()
	await _verify_zero_energy_no_intercept()
	await _verify_collision_cooldown()
	await _verify_defense_grid_collision_damage()
	await _verify_typed_weapon_collision_drain()
	_verify_decision_log_entry()
	_verify_claude_damage_hierarchy()

	if failures.is_empty():
		print("COLLISION_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_full_energy_baseline_collision() -> void:
	var harness := await _new_collision_harness(100.0)
	var slot: Node = harness["slot"]
	var grid: DefenseGrid = harness["grid"]
	var hull: Node = harness["hull"]
	var enemy := await _spawn_enemy(BASELINE_SCENE, harness["root"], Vector2(270.0, 600.0))
	var collided_count := [0]
	var killed_count := [0]
	var leaked_count := [0]
	enemy.collided.connect(func(_impact_position: Vector2) -> void:
		collided_count[0] += 1
	)
	enemy.killed.connect(func() -> void:
		killed_count[0] += 1
	)
	enemy.leaked.connect(func(_impact_position: Vector2) -> void:
		leaked_count[0] += 1
	)

	var integrity_before := grid.current_integrity
	hull._on_area_entered(enemy.get_node("Hurtbox") as Area2D)

	if !is_equal_approx(float(slot.current_energy()), 95.0):
		failures.append("expected baseline collision to drain energy to 95.0, got %.2f" % float(slot.current_energy()))
	if !is_equal_approx(grid.current_integrity, integrity_before):
		failures.append("expected full-energy baseline collision to leave Grid unchanged")
	if collided_count[0] != 1:
		failures.append("expected baseline collided signal once, got %d" % collided_count[0])
	if killed_count[0] != 0 or leaked_count[0] != 0:
		failures.append("expected collision path not to emit killed/leaked, got killed=%d leaked=%d" % [killed_count[0], leaked_count[0]])
	if !enemy.is_queued_for_deletion():
		failures.append("expected baseline to queue_free after collision consume")

	await _cleanup_harness(harness)


func _verify_partial_energy_elite_collision() -> void:
	var harness := await _new_collision_harness(5.0)
	var slot: Node = harness["slot"]
	var grid: DefenseGrid = harness["grid"]
	var hull: Node = harness["hull"]
	var enemy := await _spawn_enemy(ELITE_SCENE, harness["root"], Vector2(270.0, 600.0))
	var collided_count := [0]
	var silent_count := [0]
	enemy.collided.connect(func(_impact_position: Vector2) -> void:
		collided_count[0] += 1
	)
	slot.typed_weapon_silent.connect(func(_family_id: String) -> void:
		silent_count[0] += 1
	)

	var integrity_before := grid.current_integrity
	hull._on_area_entered(enemy.get_node("Hurtbox") as Area2D)

	if !is_zero_approx(float(slot.current_energy())):
		failures.append("expected partial elite collision to drain energy to 0.0, got %.2f" % float(slot.current_energy()))
	if !is_equal_approx(grid.current_integrity, integrity_before - 15.0):
		failures.append("expected partial elite collision to deal 15.0 Grid damage, got %.2f" % (integrity_before - grid.current_integrity))
	if collided_count[0] != 1:
		failures.append("expected elite collided signal once, got %d" % collided_count[0])
	if silent_count[0] != 1:
		failures.append("expected typed_weapon_silent exactly once after collision drain to zero, got %d" % silent_count[0])
	if !enemy.is_queued_for_deletion():
		failures.append("expected elite to queue_free after collision consume")

	await _cleanup_harness(harness)


func _verify_zero_energy_no_intercept() -> void:
	var harness := await _new_collision_harness(0.0)
	var slot: Node = harness["slot"]
	var grid: DefenseGrid = harness["grid"]
	var hull: Node = harness["hull"]
	var enemy := await _spawn_enemy(BASELINE_SCENE, harness["root"], Vector2(270.0, 600.0))
	var collided_count := [0]
	enemy.collided.connect(func(_impact_position: Vector2) -> void:
		collided_count[0] += 1
	)

	var integrity_before := grid.current_integrity
	hull._on_area_entered(enemy.get_node("Hurtbox") as Area2D)

	if !is_zero_approx(float(slot.current_energy())):
		failures.append("expected zero-energy collision contact to leave energy at 0.0")
	if !is_equal_approx(grid.current_integrity, integrity_before):
		failures.append("expected zero-energy contact to leave Grid unchanged before leak")
	if collided_count[0] != 0:
		failures.append("expected zero-energy contact not to collide-consume, got %d collided events" % collided_count[0])
	if enemy.is_queued_for_deletion():
		failures.append("expected zero-energy contact not to queue_free enemy")

	await _cleanup_harness(harness)


func _verify_collision_cooldown() -> void:
	var harness := await _new_collision_harness(100.0)
	var slot: Node = harness["slot"]
	var hull: Node = harness["hull"]
	var root_node: Node = harness["root"]
	var first := await _spawn_enemy(BASELINE_SCENE, root_node, Vector2(250.0, 600.0))
	var second := await _spawn_enemy(BASELINE_SCENE, root_node, Vector2(270.0, 600.0))
	var third := await _spawn_enemy(BASELINE_SCENE, root_node, Vector2(290.0, 600.0))
	var collided_counts := [0, 0, 0]
	first.collided.connect(func(_impact_position: Vector2) -> void:
		collided_counts[0] += 1
	)
	second.collided.connect(func(_impact_position: Vector2) -> void:
		collided_counts[1] += 1
	)
	third.collided.connect(func(_impact_position: Vector2) -> void:
		collided_counts[2] += 1
	)

	hull._on_area_entered(first.get_node("Hurtbox") as Area2D)
	hull._physics_process(0.05)
	hull._on_area_entered(second.get_node("Hurtbox") as Area2D)
	hull._physics_process(0.16)
	hull._on_area_entered(third.get_node("Hurtbox") as Area2D)

	if !is_equal_approx(float(slot.current_energy()), 90.0):
		failures.append("expected cooldown test to drain exactly two baselines worth of energy, got %.2f" % float(slot.current_energy()))
	if collided_counts[0] != 1 or collided_counts[1] != 0 or collided_counts[2] != 1:
		failures.append("expected cooldown collision counts [1,0,1], got %s" % str(collided_counts))

	await _cleanup_harness(harness)


func _verify_defense_grid_collision_damage() -> void:
	var scene_root := Node.new()
	root.add_child(scene_root)
	current_scene = scene_root
	var grid := DefenseGrid.new()
	grid.name = "DefenseGrid"
	grid.max_integrity = 20.0
	scene_root.add_child(grid)
	await process_frame

	var integrity_events := [0]
	var collision_events := [0]
	var failed_events := [0]
	grid.integrity_changed.connect(func(_current: float, _max: float) -> void:
		integrity_events[0] += 1
	)
	grid.collision_registered.connect(func(amount: float, impact_position: Vector2) -> void:
		collision_events[0] += 1
		if !is_equal_approx(amount, 15.0) and collision_events[0] == 1:
			failures.append("expected first collision_registered amount 15.0, got %.2f" % amount)
		if impact_position != Vector2.ZERO and collision_events[0] == 1:
			failures.append("expected first collision_registered impact Vector2.ZERO, got %s" % str(impact_position))
	)
	grid.grid_failed.connect(func() -> void:
		failed_events[0] += 1
	)

	grid.apply_collision_damage(15.0, Vector2.ZERO)
	if !is_equal_approx(grid.current_integrity, 5.0):
		failures.append("expected collision damage to reduce Grid to 5.0, got %.2f" % grid.current_integrity)
	if integrity_events[0] != 1 or collision_events[0] != 1:
		failures.append("expected one integrity and collision event, got integrity=%d collision=%d" % [integrity_events[0], collision_events[0]])

	grid.apply_collision_damage(5.0, Vector2(1.0, 2.0))
	grid.apply_collision_damage(1.0, Vector2(1.0, 2.0))
	if failed_events[0] != 1:
		failures.append("expected grid_failed once after collision damage reaches zero, got %d" % failed_events[0])

	scene_root.queue_free()
	current_scene = null
	await process_frame


func _verify_typed_weapon_collision_drain() -> void:
	var slot := SLOT_SCRIPT.new()
	var family := _new_family("collision_family", 10.0, 2.0)
	var energy_events := [0]
	var silent_events := [0]
	slot.typed_weapon_energy_changed.connect(func(_current: float, _max: float) -> void:
		energy_events[0] += 1
	)
	slot.typed_weapon_silent.connect(func(_family_id: String) -> void:
		silent_events[0] += 1
	)

	slot.equip(family)
	energy_events[0] = 0
	var spent := float(slot.drain_for_collision(7.0))
	if !is_equal_approx(spent, 7.0) or !is_equal_approx(slot.current_energy(), 3.0):
		failures.append("expected drain_for_collision(7) to spend 7 and leave 3 energy, spent=%.2f current=%.2f" % [spent, slot.current_energy()])
	if energy_events[0] != 1 or silent_events[0] != 0:
		failures.append("expected first collision drain to emit energy once and silent zero times, got energy=%d silent=%d" % [energy_events[0], silent_events[0]])

	spent = float(slot.drain_for_collision(50.0))
	if !is_equal_approx(spent, 3.0) or !is_zero_approx(slot.current_energy()):
		failures.append("expected drain_for_collision overdraw to spend 3 and clamp at 0, spent=%.2f current=%.2f" % [spent, slot.current_energy()])
	if silent_events[0] != 1:
		failures.append("expected overdraw collision drain to emit typed_weapon_silent once, got %d" % silent_events[0])

	slot.free()


func _verify_decision_log_entry() -> void:
	var text := FileAccess.get_file_as_string("res://docs/design/decisions.md")
	if !text.contains("2026-05-23 — Collision interception math: energy 1:1 versus enemy HP, no shared-shield cap"):
		failures.append("expected new 2026-05-23 collision math decision-log heading")
	if !text.contains("2026-05-14 \"Collision interception spends weapon energy before shared shield\" — superseded for the cap-N shared-shield absorption step"):
		failures.append("expected decision log to explicitly supersede the 2026-05-14 cap-N step")


func _verify_claude_damage_hierarchy() -> void:
	var text := FileAccess.get_file_as_string("res://CLAUDE.md")
	if !text.contains("no cap") or !text.contains("at 0 energy, no interception"):
		failures.append("expected CLAUDE.md damage hierarchy to include no-cap and zero-energy no-interception wording")


func _new_collision_harness(starting_energy: float) -> Dictionary:
	var scene_root := Node.new()
	root.add_child(scene_root)
	current_scene = scene_root

	var grid := DefenseGrid.new()
	grid.name = "DefenseGrid"
	scene_root.add_child(grid)

	var camera := Camera2D.new()
	camera.name = "GameplayCamera"
	camera.position = Vector2(270.0, 480.0)
	camera.enabled = true
	scene_root.add_child(camera)

	var hud := DummyHud.new()
	hud.name = "HUD"
	scene_root.add_child(hud)

	var player := PLAYER_SCENE.instantiate() as Node2D
	scene_root.add_child(player)
	player.global_position = Vector2(270.0, 850.0)
	await process_frame

	var slot := player.get_node("TypedWeaponSlot")
	slot.equip(_new_family("collision_family", 100.0, 2.0))
	slot.active_weapon.current_energy = clampf(starting_energy, 0.0, slot.active_weapon.max_energy)
	slot._was_empty_last_tick = slot.active_weapon.current_energy <= 0.0
	slot.typed_weapon_energy_changed.emit(slot.active_weapon.current_energy, slot.active_weapon.max_energy)

	var hull := player.get_node("PlayerHull")
	return {
		"root": scene_root,
		"grid": grid,
		"player": player,
		"slot": slot,
		"hull": hull,
	}


func _spawn_enemy(scene: PackedScene, parent: Node, spawn_position: Vector2) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	parent.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.set_physics_process(false)
	await process_frame
	return enemy


func _cleanup_harness(harness: Dictionary) -> void:
	var scene_root: Node = harness["root"]
	await create_timer(0.20).timeout
	scene_root.queue_free()
	current_scene = null
	await process_frame


func _new_family(family_id: String, max_energy: float, firing_cost: float) -> TypedWeaponFamily:
	var family := TypedWeaponFamily.new()
	family.family_id = family_id
	family.display_name = family_id
	family.max_energy = max_energy
	family.firing_cost = firing_cost
	family.fire_interval = 0.01
	return family
