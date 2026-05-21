extends Node2D

signal typed_weapon_fired(bullet: Node2D, current_energy: float, max_energy: float)
signal typed_weapon_energy_changed(current_energy: float, max_energy: float)
signal typed_weapon_expired(family_id: String)
signal chip_pickup_applied(family_id: String, granted_new_family: bool)

@export var projectile_scene: PackedScene
@export var bullet_parent_path: NodePath
@export var fire_action := "fire_typed"

var active_weapon: TypedWeapon
var _time_until_next_shot := 0.0


func _physics_process(delta: float) -> void:
	if active_weapon == null:
		return

	_time_until_next_shot = maxf(_time_until_next_shot - delta, 0.0)
	if !Input.is_action_pressed(fire_action):
		return

	if _time_until_next_shot > 0.0 or !_fire_once():
		return

	if active_weapon != null:
		_time_until_next_shot = active_weapon.family.normalized_fire_interval()


func equip(family: TypedWeaponFamily) -> void:
	if family == null:
		clear()
		return

	active_weapon = TypedWeapon.new(family)
	_time_until_next_shot = 0.0
	typed_weapon_energy_changed.emit(active_weapon.current_energy, active_weapon.max_energy)


func clear() -> void:
	active_weapon = null
	_time_until_next_shot = 0.0
	typed_weapon_energy_changed.emit(0.0, 0.0)


func apply_chip_pickup(family: TypedWeaponFamily) -> void:
	if family == null:
		push_warning("TypedWeaponSlot received a weapon chip with no family.")
		return

	if active_weapon == null:
		equip(family)
		chip_pickup_applied.emit(family.family_id, true)
		return

	active_weapon.current_energy = active_weapon.max_energy
	typed_weapon_energy_changed.emit(active_weapon.current_energy, active_weapon.max_energy)
	chip_pickup_applied.emit(active_weapon.family.family_id, false)


func has_weapon() -> bool:
	return active_weapon != null


func current_family_id() -> String:
	if active_weapon == null or active_weapon.family == null:
		return ""
	return active_weapon.family.family_id


func current_energy() -> float:
	if active_weapon == null:
		return 0.0
	return active_weapon.current_energy


func max_energy() -> float:
	if active_weapon == null:
		return 0.0
	return active_weapon.max_energy


func _fire_once() -> bool:
	if active_weapon == null:
		return false

	var family := active_weapon.family
	if projectile_scene == null:
		push_warning("TypedWeaponSlot has no projectile_scene assigned.")
		return false

	if !active_weapon.try_fire():
		_expire_active_weapon(family.family_id)
		return false

	var bullet_parent := _resolve_bullet_parent()
	var fired_projectiles := _spawn_projectiles_for_family(family, bullet_parent)
	if fired_projectiles.is_empty():
		return false

	typed_weapon_fired.emit(fired_projectiles[0], active_weapon.current_energy, active_weapon.max_energy)
	typed_weapon_energy_changed.emit(active_weapon.current_energy, active_weapon.max_energy)

	if active_weapon.is_expired():
		_expire_active_weapon(family.family_id)

	return true


func _spawn_projectiles_for_family(family: TypedWeaponFamily, bullet_parent: Node) -> Array[Node2D]:
	var projectiles: Array[Node2D] = []
	var count := 1
	var spread_angle := 0.0
	if family.archetype == TypedWeaponFamily.WeaponArchetype.SPREAD:
		count = family.normalized_spread_count()
		spread_angle = family.spread_angle_degrees

	var half_angle := spread_angle * 0.5
	var step := 0.0
	if count > 1:
		step = spread_angle / float(count - 1)

	for index in range(count):
		var projectile := _instantiate_projectile(family)
		if projectile == null:
			continue

		var angle_degrees := 0.0
		if count > 1:
			angle_degrees = -half_angle + step * float(index)
		var direction := Vector2.UP.rotated(deg_to_rad(angle_degrees))
		projectile.set("direction", direction)
		projectile.rotation = direction.angle() - Vector2.UP.angle()

		bullet_parent.add_child(projectile)
		projectile.global_position = global_position
		projectiles.append(projectile)

	return projectiles


func _instantiate_projectile(family: TypedWeaponFamily) -> Node2D:
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		push_warning("TypedWeaponSlot projectile_scene must instantiate a Node2D.")
		return null

	if projectile.has_method("configure_from_family"):
		projectile.configure_from_family(family)

	return projectile


func _expire_active_weapon(family_id: String) -> void:
	clear()
	typed_weapon_expired.emit(family_id)


func _resolve_bullet_parent() -> Node:
	if bullet_parent_path != NodePath() and has_node(bullet_parent_path):
		return get_node(bullet_parent_path)

	var current_scene := get_tree().current_scene
	if current_scene != null:
		return current_scene

	return get_tree().root
