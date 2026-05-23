extends Node
class_name DefenseGrid

signal integrity_changed(current: float, max: float)
signal leak_registered(amount: float, impact_position: Vector2)
signal collision_registered(amount: float, impact_position: Vector2)
signal grid_failed

@export var max_integrity := 100.0
@export var leak_damage_default := 10.0

var current_integrity := 0.0

var _failed := false


func _ready() -> void:
	max_integrity = maxf(max_integrity, 0.0)
	current_integrity = max_integrity
	integrity_changed.emit(current_integrity, max_integrity)


func apply_leak_damage(amount: float, impact_position: Vector2) -> void:
	if _failed:
		return

	var damage := maxf(amount, 0.0)
	if damage <= 0.0:
		return

	current_integrity = clampf(current_integrity - damage, 0.0, max_integrity)
	integrity_changed.emit(current_integrity, max_integrity)
	leak_registered.emit(damage, impact_position)

	if current_integrity <= 0.0 and !_failed:
		_failed = true
		grid_failed.emit()


func apply_collision_damage(amount: float, impact_position: Vector2) -> void:
	if _failed:
		return

	var damage := maxf(amount, 0.0)
	if damage <= 0.0:
		return

	current_integrity = clampf(current_integrity - damage, 0.0, max_integrity)
	integrity_changed.emit(current_integrity, max_integrity)
	collision_registered.emit(damage, impact_position)
	print("grid_collision_damage amount=%.2f" % damage)

	if current_integrity <= 0.0 and !_failed:
		_failed = true
		grid_failed.emit()


func integrity_ratio() -> float:
	if max_integrity <= 0.0:
		return 0.0

	return clampf(current_integrity / max_integrity, 0.0, 1.0)
