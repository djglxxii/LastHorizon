extends Area2D

@export var typed_weapon_slot_path: NodePath
@export var defense_grid_path: NodePath
@export var ship_sprite_path: NodePath
@export var camera_path: NodePath
@export var hud_path: NodePath
@export var collision_cooldown_seconds := 0.15
@export var hit_flash_seconds := 0.12
@export var screen_shake_amplitude := 4.0
@export var screen_shake_seconds := 0.15

var _cooldown := 0.0
var _typed_weapon_slot: Node
var _defense_grid: Node
var _ship_sprite: CanvasItem
var _camera: Camera2D
var _hud: Node
var _flash_sequence := 0
var _shake_sequence := 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_typed_weapon_slot = _resolve_node(typed_weapon_slot_path, "TypedWeaponSlot")
	_defense_grid = _resolve_node(defense_grid_path, "DefenseGrid")
	_ship_sprite = _resolve_node(ship_sprite_path, "Sprite2D") as CanvasItem
	_camera = _resolve_node(camera_path, "GameplayCamera") as Camera2D
	_hud = _resolve_node(hud_path, "HUD")

	if _typed_weapon_slot == null:
		push_warning("PlayerHull could not resolve TypedWeaponSlot; collision interception will no-op.")
	if _defense_grid == null:
		push_warning("PlayerHull could not resolve DefenseGrid; leftover collision damage will be skipped.")
	if _ship_sprite == null:
		push_warning("PlayerHull could not resolve ship Sprite2D; hit flash disabled.")
	if _camera == null:
		push_warning("PlayerHull could not resolve GameplayCamera; screen shake disabled.")
	if _hud == null:
		push_warning("PlayerHull could not resolve HUD; energy collision flash disabled.")


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _on_area_entered(area: Area2D) -> void:
	if _cooldown > 0.0:
		print("collision_cooldown_suppressed")
		return

	var enemy := area.get_parent()
	if enemy == null or !enemy.has_method("take_damage") or !enemy.has_method("consume_for_collision"):
		return

	_cooldown = maxf(collision_cooldown_seconds, 0.0)
	_trigger_feedback()

	var current_energy := _current_energy()
	if current_energy <= 0.0:
		print("collision_no_intercept reason=zero_energy enemy=%s" % _enemy_log_name(enemy))
		return

	var enemy_hp := maxf(float(enemy.get("current_hp")), 0.0)
	var requested_spend := minf(current_energy, enemy_hp)
	var spent := _drain_for_collision(requested_spend)
	var leftover_hp := maxf(enemy_hp - spent, 0.0)

	if leftover_hp > 0.0 and _defense_grid != null and _defense_grid.has_method("apply_collision_damage"):
		_defense_grid.apply_collision_damage(leftover_hp, enemy.global_position)

	enemy.consume_for_collision(global_position)


func _current_energy() -> float:
	if _typed_weapon_slot == null or !_typed_weapon_slot.has_method("current_energy"):
		return 0.0
	return float(_typed_weapon_slot.call("current_energy"))


func _drain_for_collision(amount: float) -> float:
	if _typed_weapon_slot == null or !_typed_weapon_slot.has_method("drain_for_collision"):
		return 0.0
	return float(_typed_weapon_slot.call("drain_for_collision", amount))


func _trigger_feedback() -> void:
	_flash_energy_meter()
	_run_hit_flash()
	_run_screen_shake()


func _flash_energy_meter() -> void:
	if _hud != null and _hud.has_method("flash_collision"):
		_hud.flash_collision()


func _run_hit_flash() -> void:
	if _ship_sprite == null or !is_inside_tree():
		return

	_flash_sequence += 1
	var flash_sequence := _flash_sequence
	var original_modulate := _ship_sprite.modulate
	_ship_sprite.modulate = Color(2.0, 2.0, 2.0, original_modulate.a)

	var tree := get_tree()
	if tree == null:
		_ship_sprite.modulate = original_modulate
		return

	await tree.create_timer(maxf(hit_flash_seconds, 0.0)).timeout
	if !is_inside_tree() or _ship_sprite == null:
		return
	if flash_sequence != _flash_sequence:
		return

	_ship_sprite.modulate = original_modulate


func _run_screen_shake() -> void:
	if _camera == null or !is_inside_tree():
		return

	_shake_sequence += 1
	var shake_sequence := _shake_sequence
	var original_offset := _camera.offset
	var duration := maxf(screen_shake_seconds, 0.0)
	var amplitude := maxf(screen_shake_amplitude, 0.0)
	var elapsed := 0.0
	var tree := get_tree()
	if tree == null:
		return

	while elapsed < duration:
		if !is_inside_tree() or _camera == null:
			return
		if shake_sequence != _shake_sequence:
			return

		var falloff := 1.0 - (elapsed / maxf(duration, 0.001))
		_camera.offset = original_offset + Vector2(
			randf_range(-amplitude, amplitude) * falloff,
			randf_range(-amplitude, amplitude) * falloff
		)
		await tree.process_frame
		elapsed += get_process_delta_time()

	if is_inside_tree() and _camera != null and shake_sequence == _shake_sequence:
		_camera.offset = original_offset


func _resolve_node(path: NodePath, fallback_name: String) -> Node:
	if path != NodePath() and has_node(path):
		return get_node(path)

	var current_scene := get_tree().current_scene
	if current_scene != null:
		var found := current_scene.find_child(fallback_name, true, false)
		if found != null:
			return found

	return null


func _enemy_log_name(enemy: Node) -> String:
	if enemy is EliteEnemy:
		return "elite"
	if enemy is BaselineEnemy:
		return "baseline"
	return enemy.name.to_snake_case()
