extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const DEBUG_FAMILY := preload("res://data/weapons/debug_plasma.tres")
const STEP_DELTA := 1.0 / 60.0

var _player: Node2D
var _pea_shooter: Node
var _typed_slot: Node
var _bullet_parent: Node2D
var _bar: ProgressBar
var _label: Label
var _pea_count := 0
var _initial_value := 0.0
var _initial_max := 0.0
var _drained_value := 0.0
var _expired_label := ""
var _inactive_label := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_release_test_inputs()
	_setup_scene()
	await process_frame

	_verify_initial_state(failures)

	_step_simulation(0.75, true)
	_verify_drain_state(failures)

	_step_simulation(12.5, true)
	_verify_expiry_state(failures)

	await create_timer(0.45).timeout
	_verify_inactive_state(failures)
	_verify_pea_shooter_continues(failures)

	_send_key(KEY_SPACE, false)
	_release_test_inputs()

	print("Initial HUD: %.1f / %.1f" % [_initial_value, _initial_max])
	print("HUD after held fire: %.1f / %.1f" % [_drained_value, _initial_max])
	print("HUD expiry label: %s" % _expired_label)
	print("HUD inactive label: %s" % _inactive_label)
	print("Typed slot has weapon after expiry: %s" % _typed_slot.has_weapon())
	print("Pea shots observed: %s" % _pea_count)

	if failures.is_empty():
		print("HUD_BINDING_VERIFICATION_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _setup_scene() -> void:
	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)

	_bullet_parent = Node2D.new()
	_bullet_parent.name = "BulletParent"
	world.add_child(_bullet_parent)

	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(270.0, 850.0)
	world.add_child(_player)

	_pea_shooter = _player.get_node("PeaShooter")
	_typed_slot = _player.get_node("TypedWeaponSlot")
	_pea_shooter.bullet_parent_path = _pea_shooter.get_path_to(_bullet_parent)
	_typed_slot.bullet_parent_path = _typed_slot.get_path_to(_bullet_parent)
	_typed_slot.equip(DEBUG_FAMILY)
	_pea_shooter.bullet_fired.connect(func(_bullet: Node2D) -> void:
		_pea_count += 1
	)

	var hud := HUD_SCENE.instantiate()
	hud.typed_weapon_slot_path = NodePath("../World/Player/TypedWeaponSlot")
	root.add_child(hud)

	_bar = hud.get_node("Root/EnergyMeter/EnergyBar")
	_label = hud.get_node("Root/EnergyMeter/ValueLabel")


func _step_simulation(seconds: float, holding_fire: bool) -> void:
	_send_key(KEY_SPACE, holding_fire)
	var steps := int(seconds / STEP_DELTA)
	for _step in range(steps):
		_player._physics_process(STEP_DELTA)
		_pea_shooter._physics_process(STEP_DELTA)
		_typed_slot._physics_process(STEP_DELTA)
		for bullet in _bullet_parent.get_children():
			if bullet.has_method("_physics_process"):
				bullet._physics_process(STEP_DELTA)


func _verify_initial_state(failures: Array[String]) -> void:
	_initial_value = _bar.value
	_initial_max = _bar.max_value

	if !is_equal_approx(_bar.max_value, 100.0):
		failures.append("expected HUD max energy to read 100, got %.1f" % _bar.max_value)
	if !is_equal_approx(_bar.value, 100.0):
		failures.append("expected HUD energy to start full, got %.1f" % _bar.value)
	if _label.text != "100 / 100":
		failures.append("expected full-energy label, got %s" % _label.text)


func _verify_drain_state(failures: Array[String]) -> void:
	_drained_value = _bar.value

	if _bar.value >= 100.0 or _bar.value <= 0.0:
		failures.append("expected HUD energy to drain while still active, got %.1f" % _bar.value)
	if !is_equal_approx(_bar.value, _typed_slot.current_energy()):
		failures.append("expected HUD value %.1f to match slot %.1f" % [_bar.value, _typed_slot.current_energy()])


func _verify_expiry_state(failures: Array[String]) -> void:
	_expired_label = _label.text

	if _typed_slot.has_weapon():
		failures.append("expected typed slot to expire")
	if !is_zero_approx(_bar.value):
		failures.append("expected HUD bar to reach empty at expiry, got %.1f" % _bar.value)
	if _label.text != "0 / 100":
		failures.append("expected HUD to show active empty state before dimming, got %s" % _label.text)


func _verify_inactive_state(failures: Array[String]) -> void:
	_inactive_label = _label.text

	if _label.text != "-- / --":
		failures.append("expected inactive empty label after expiry delay, got %s" % _label.text)


func _verify_pea_shooter_continues(failures: Array[String]) -> void:
	if _pea_count <= 0:
		failures.append("expected pea shooter to continue firing")


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
