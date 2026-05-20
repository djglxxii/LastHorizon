extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const STEP_COUNT := 140
const STEP_DELTA := 1.0 / 60.0


func _init() -> void:
	var failures: Array[String] = []

	_verify_action("ui_left", "built-in left action", -1.0, failures)
	_verify_action("ui_right", "built-in right action", 1.0, failures)
	_verify_key(KEY_A, "A key", -1.0, failures)
	_verify_key(KEY_D, "D key", 1.0, failures)

	if failures.is_empty():
		print("PLAYER_MOVEMENT_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _verify_action(action: StringName, label: String, direction: float, failures: Array[String]) -> void:
	var player := _new_centered_player()
	Input.action_press(action)
	_step_player(player)
	Input.action_release(action)
	_check_bounds(player, label, direction, failures)
	player.free()


func _verify_key(keycode: Key, label: String, direction: float, failures: Array[String]) -> void:
	var player := _new_centered_player()
	_send_key(keycode, true)
	_step_player(player)
	_send_key(keycode, false)
	_check_bounds(player, label, direction, failures)
	player.free()


func _new_centered_player() -> Node2D:
	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(270.0, 850.0)
	player.fixed_y = 850.0
	player.clamp_to_playfield()
	return player


func _step_player(player: Node2D) -> void:
	for index in STEP_COUNT:
		player._physics_process(STEP_DELTA)


func _check_bounds(player: Node2D, label: String, direction: float, failures: Array[String]) -> void:
	var expected_x: float = player.right_bound_x() if direction > 0.0 else player.left_bound_x()
	if !is_equal_approx(player.position.x, expected_x):
		failures.append("%s expected x=%s, got x=%s" % [label, expected_x, player.position.x])
	if !is_equal_approx(player.position.y, player.fixed_y):
		failures.append("%s expected y=%s, got y=%s" % [label, player.fixed_y, player.position.y])


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
