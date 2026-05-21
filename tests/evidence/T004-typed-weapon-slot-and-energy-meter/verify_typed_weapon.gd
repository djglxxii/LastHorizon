extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const DEBUG_FAMILY := preload("res://data/weapons/debug_plasma.tres")
const STEP_DELTA := 1.0 / 60.0
const SIM_SECONDS := 12.25
const SIM_STEPS := int(SIM_SECONDS / STEP_DELTA)


func _init() -> void:
	var failures: Array[String] = []
	var result := _run_held_fire_simulation()

	_verify_energy_drain(result, failures)
	_verify_expiry(result, failures)
	_verify_pea_shooter_continues(result, failures)

	print("Family: %s" % result["family_id"])
	print("Start energy: %.1f / %.1f" % [result["start_energy"], result["max_energy"]])
	print("Typed shots before expiry: %s" % result["typed_count"])
	print("Pea shots total: %s" % result["pea_count"])
	print("Expiry time: %.2fs" % result["expiry_time"])
	print("Typed shots after expiry: %s" % result["typed_after_expiry"])
	print("Pea shots after expiry: %s" % result["pea_after_expiry"])
	print("Energy samples:")
	for sample in result["energy_samples"]:
		print("  t=%.2fs energy=%.1f" % [sample["time"], sample["energy"]])

	if failures.is_empty():
		print("TYPED_WEAPON_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_held_fire_simulation() -> Dictionary:
	_release_test_inputs()

	var container := Node2D.new()
	root.add_child(container)

	var bullet_parent := Node2D.new()
	bullet_parent.name = "BulletParent"
	container.add_child(bullet_parent)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(270.0, 850.0)
	player.fixed_y = 850.0
	container.add_child(player)
	player.clamp_to_playfield()

	var pea_shooter := player.get_node("PeaShooter")
	var typed_slot := player.get_node("TypedWeaponSlot")
	pea_shooter.bullet_parent_path = pea_shooter.get_path_to(bullet_parent)
	typed_slot.bullet_parent_path = typed_slot.get_path_to(bullet_parent)

	if !typed_slot.has_weapon():
		typed_slot.equip(DEBUG_FAMILY)

	var family_id: String = typed_slot.current_family_id()
	var start_energy: float = typed_slot.current_energy()
	var max_energy: float = typed_slot.max_energy()
	var energy_samples: Array[Dictionary] = []
	var pea_count := [0]
	var typed_count := [0]
	var typed_count_at_expiry := -1
	var pea_count_at_expiry := -1
	var expiry_step := -1

	pea_shooter.bullet_fired.connect(func(_bullet: Node2D) -> void:
		pea_count[0] += 1
	)
	typed_slot.typed_weapon_fired.connect(func(_bullet: Node2D, _current_energy: float, _max_energy: float) -> void:
		typed_count[0] += 1
	)

	_send_key(KEY_SPACE, true)
	for step in range(SIM_STEPS):
		player._physics_process(STEP_DELTA)
		pea_shooter._physics_process(STEP_DELTA)
		typed_slot._physics_process(STEP_DELTA)

		for bullet in bullet_parent.get_children():
			if bullet.has_method("_physics_process"):
				bullet._physics_process(STEP_DELTA)

		if step % 30 == 0:
			energy_samples.append({
				"time": step * STEP_DELTA,
				"energy": typed_slot.current_energy(),
			})

		if expiry_step == -1 and !typed_slot.has_weapon():
			expiry_step = step
			typed_count_at_expiry = typed_count[0]
			pea_count_at_expiry = pea_count[0]

	_send_key(KEY_SPACE, false)
	_release_test_inputs()

	var result := {
		"family_id": family_id,
		"start_energy": start_energy,
		"max_energy": max_energy,
		"energy_samples": energy_samples,
		"typed_count": typed_count[0],
		"pea_count": pea_count[0],
		"expiry_step": expiry_step,
		"expiry_time": expiry_step * STEP_DELTA if expiry_step >= 0 else -1.0,
		"typed_at_expiry": typed_count_at_expiry,
		"pea_at_expiry": pea_count_at_expiry,
		"typed_after_expiry": typed_count[0] - typed_count_at_expiry if typed_count_at_expiry >= 0 else -1,
		"pea_after_expiry": pea_count[0] - pea_count_at_expiry if pea_count_at_expiry >= 0 else -1,
		"expected_shots_to_empty": int(round(max_energy / DEBUG_FAMILY.firing_cost)),
	}

	container.queue_free()
	return result


func _verify_energy_drain(result: Dictionary, failures: Array[String]) -> void:
	if !is_equal_approx(float(result["start_energy"]), float(result["max_energy"])):
		failures.append("expected debug weapon to start full, got %.1f / %.1f" % [result["start_energy"], result["max_energy"]])

	var samples := result["energy_samples"] as Array
	if samples.size() < 3:
		failures.append("expected multiple energy samples")
		return

	var first := samples[0] as Dictionary
	var middle := samples[min(2, samples.size() - 1)] as Dictionary
	var last := samples[samples.size() - 1] as Dictionary

	if float(middle["energy"]) >= float(first["energy"]):
		failures.append("expected held fire to reduce energy, samples were %.1f then %.1f" % [first["energy"], middle["energy"]])

	if float(last["energy"]) != 0.0:
		failures.append("expected expired slot to report 0 energy, got %.1f" % last["energy"])


func _verify_expiry(result: Dictionary, failures: Array[String]) -> void:
	if int(result["expiry_step"]) < 0:
		failures.append("expected typed weapon to expire during held fire")

	if int(result["typed_count"]) != int(result["expected_shots_to_empty"]):
		failures.append("expected %s typed shots before empty, got %s" % [result["expected_shots_to_empty"], result["typed_count"]])

	if int(result["typed_after_expiry"]) != 0:
		failures.append("expected no typed shots after expiry, got %s" % result["typed_after_expiry"])


func _verify_pea_shooter_continues(result: Dictionary, failures: Array[String]) -> void:
	if int(result["pea_count"]) <= 0:
		failures.append("expected pea shooter to continue throughout simulation")

	if int(result["pea_after_expiry"]) <= 0:
		failures.append("expected pea shooter shots after typed weapon expiry")


func _release_test_inputs() -> void:
	Input.action_release("fire_typed")
	_send_key(KEY_SPACE, false)
	Input.flush_buffered_events()


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
