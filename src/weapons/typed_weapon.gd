extends RefCounted
class_name TypedWeapon

var family: TypedWeaponFamily
var max_energy := 0.0
var current_energy := 0.0


func _init(weapon_family: TypedWeaponFamily) -> void:
	family = weapon_family
	if family == null:
		return

	max_energy = family.normalized_max_energy()
	current_energy = max_energy


func try_fire() -> bool:
	if family == null:
		return false

	var cost := family.normalized_firing_cost()
	if current_energy < cost or is_zero_approx(current_energy):
		current_energy = 0.0
		return false

	current_energy = maxf(current_energy - cost, 0.0)
	return true


func is_expired() -> bool:
	return current_energy <= 0.0
