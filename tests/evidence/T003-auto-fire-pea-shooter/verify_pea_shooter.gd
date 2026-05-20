extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const STEP_DELTA := 1.0 / 60.0
const SIM_SECONDS := 2.0
const SIM_STEPS := int(SIM_SECONDS / STEP_DELTA)


func _init() -> void:
	var failures: Array[String] = []

	var no_input := _run_simulation(false)
	var noisy_input := _run_simulation(true)
	var reposition := _run_reposition_simulation()

	_verify_fire_count(no_input, "no input", failures)
	_verify_fire_count(noisy_input, "synthetic input", failures)
	_verify_matching_fire_rate(no_input, noisy_input, failures)
	_verify_bullet_motion(noisy_input, failures)
	_verify_spawn_positions_follow_player(reposition, failures)

	print("No-input bullets fired: %s" % no_input["count"])
	print("Synthetic-input bullets fired: %s" % noisy_input["count"])
	print("First spawn: %s" % no_input["first_spawn"])
	print("Reposition spawn range x: %s..%s" % [reposition["min_spawn_x"], reposition["max_spawn_x"]])
	print("Sample bullet velocity: %s" % noisy_input["sample_velocity"])

	if failures.is_empty():
		print("PEA_SHOOTER_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_simulation(apply_input: bool) -> Dictionary:
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

	var shooter := player.get_node("PeaShooter")
	shooter.bullet_parent_path = shooter.get_path_to(bullet_parent)

	var spawns: Array[Vector2] = []
	var velocities: Array[Vector2] = []
	shooter.bullet_fired.connect(func(bullet: Node2D) -> void:
		spawns.append(bullet.position)
		if bullet.has_method("velocity"):
			velocities.append(bullet.velocity())
	)

	for step in range(SIM_STEPS):
		if apply_input:
			_apply_synthetic_input(step)

		player._physics_process(STEP_DELTA)
		shooter._physics_process(STEP_DELTA)
		for bullet in bullet_parent.get_children():
			if bullet.has_method("_physics_process"):
				bullet._physics_process(STEP_DELTA)

	_release_test_inputs()

	var live_bullets := bullet_parent.get_child_count()
	var result := {
		"count": spawns.size(),
		"first_spawn": spawns[0] if !spawns.is_empty() else Vector2.ZERO,
		"last_spawn": spawns[spawns.size() - 1] if !spawns.is_empty() else Vector2.ZERO,
		"min_spawn_x": _min_spawn_x(spawns),
		"max_spawn_x": _max_spawn_x(spawns),
		"sample_velocity": velocities[0] if !velocities.is_empty() else Vector2.ZERO,
		"live_bullets": live_bullets,
		"fire_interval": shooter.fire_interval,
		"bullet_speed": shooter.bullet_speed,
	}

	container.queue_free()
	return result


func _run_reposition_simulation() -> Dictionary:
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

	var shooter := player.get_node("PeaShooter")
	shooter.bullet_parent_path = shooter.get_path_to(bullet_parent)

	var spawns: Array[Vector2] = []
	shooter.bullet_fired.connect(func(bullet: Node2D) -> void:
		spawns.append(bullet.position)
	)

	for step in range(SIM_STEPS):
		if step == 40:
			player.position.x = 150.0
			player.clamp_to_playfield()
		if step == 80:
			player.position.x = 390.0
			player.clamp_to_playfield()

		shooter._physics_process(STEP_DELTA)
		for bullet in bullet_parent.get_children():
			if bullet.has_method("_physics_process"):
				bullet._physics_process(STEP_DELTA)

	var result := {
		"first_spawn": spawns[0] if !spawns.is_empty() else Vector2.ZERO,
		"min_spawn_x": _min_spawn_x(spawns),
		"max_spawn_x": _max_spawn_x(spawns),
	}

	container.queue_free()
	return result


func _verify_fire_count(result: Dictionary, label: String, failures: Array[String]) -> void:
	var expected_min := floori(SIM_SECONDS / result["fire_interval"])
	var expected_max := ceili(SIM_SECONDS / result["fire_interval"]) + 1
	var count := int(result["count"])

	if count < expected_min or count > expected_max:
		failures.append("%s expected %s-%s bullets, got %s" % [label, expected_min, expected_max, count])

	if int(result["live_bullets"]) <= 0:
		failures.append("%s expected live bullets during the stream" % label)


func _verify_matching_fire_rate(no_input: Dictionary, noisy_input: Dictionary, failures: Array[String]) -> void:
	if int(no_input["count"]) != int(noisy_input["count"]):
		failures.append(
			"synthetic fire/movement inputs changed fire count: no input=%s, synthetic input=%s"
			% [no_input["count"], noisy_input["count"]]
		)


func _verify_bullet_motion(result: Dictionary, failures: Array[String]) -> void:
	var velocity := result["sample_velocity"] as Vector2
	if !is_equal_approx(velocity.x, 0.0) or velocity.y >= 0.0:
		failures.append("expected upward bullet velocity, got %s" % velocity)

	if !is_equal_approx(absf(velocity.y), float(result["bullet_speed"])):
		failures.append("expected velocity magnitude %s, got %s" % [result["bullet_speed"], velocity])


func _verify_spawn_positions_follow_player(result: Dictionary, failures: Array[String]) -> void:
	var first_spawn := result["first_spawn"] as Vector2

	if !is_equal_approx(first_spawn.y, 804.0):
		failures.append("expected muzzle y=804, got %s" % first_spawn.y)

	if float(result["min_spawn_x"]) >= first_spawn.x and float(result["max_spawn_x"]) <= first_spawn.x:
		failures.append("expected synthetic movement to change bullet x positions")


func _min_spawn_x(spawns: Array[Vector2]) -> float:
	if spawns.is_empty():
		return 0.0

	var minimum := spawns[0].x
	for spawn in spawns:
		minimum = minf(minimum, spawn.x)
	return minimum


func _max_spawn_x(spawns: Array[Vector2]) -> float:
	if spawns.is_empty():
		return 0.0

	var maximum := spawns[0].x
	for spawn in spawns:
		maximum = maxf(maximum, spawn.x)
	return maximum


func _apply_synthetic_input(step: int) -> void:
	if step == 12:
		_send_key(KEY_SPACE, true)
	if step == 24:
		_send_key(KEY_SPACE, false)
	if step == 36:
		_send_mouse_button(MOUSE_BUTTON_LEFT, true)
	if step == 48:
		_send_mouse_button(MOUSE_BUTTON_LEFT, false)
	if step == 60:
		_send_key(KEY_A, true)
	if step == 84:
		_send_key(KEY_A, false)
	if step == 96:
		_send_key(KEY_D, true)
	if step == 119:
		_send_key(KEY_D, false)
	if step == 72:
		_send_joy_button(JOY_BUTTON_A, true)
	if step == 90:
		_send_joy_button(JOY_BUTTON_A, false)


func _release_test_inputs() -> void:
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	_send_key(KEY_A, false)
	_send_key(KEY_D, false)
	_send_key(KEY_SPACE, false)
	_send_mouse_button(MOUSE_BUTTON_LEFT, false)
	_send_joy_button(JOY_BUTTON_A, false)
	Input.flush_buffered_events()


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _send_mouse_button(button_index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _send_joy_button(button_index: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
