extends CanvasLayer

const EXPIRY_INACTIVE_DELAY := 0.35

@export var typed_weapon_slot_path: NodePath
@export var defense_grid_path: NodePath

@onready var _energy_meter: EnergyMeter = %EnergyMeter
@onready var _grid_meter: GridMeter = %GridMeter

var _typed_weapon_slot: Node
var _last_max_energy := 0.0


func _ready() -> void:
	_grid_meter.bind_defense_grid_node(_resolve_defense_grid())
	_typed_weapon_slot = _resolve_typed_weapon_slot()
	if _typed_weapon_slot == null:
		_energy_meter.set_empty()
		return

	_typed_weapon_slot.connect("typed_weapon_energy_changed", _on_typed_weapon_energy_changed)
	_typed_weapon_slot.connect("typed_weapon_expired", _on_typed_weapon_expired)
	_typed_weapon_slot.connect("typed_weapon_refilled", _on_typed_weapon_refilled)
	_sync_from_slot()


func _resolve_typed_weapon_slot() -> Node:
	if typed_weapon_slot_path != NodePath() and has_node(typed_weapon_slot_path):
		return get_node(typed_weapon_slot_path)

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("TypedWeaponSlot", true, false)


func _resolve_defense_grid() -> Node:
	if defense_grid_path != NodePath() and has_node(defense_grid_path):
		return get_node(defense_grid_path)

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("DefenseGrid", true, false)


func _sync_from_slot() -> void:
	if _typed_weapon_slot == null:
		_energy_meter.set_empty()
		return

	if !_typed_weapon_slot.has_method("current_energy") or !_typed_weapon_slot.has_method("max_energy"):
		_energy_meter.set_empty()
		return

	var current_energy := float(_typed_weapon_slot.call("current_energy"))
	var max_energy := float(_typed_weapon_slot.call("max_energy"))
	_on_typed_weapon_energy_changed(current_energy, max_energy)


func _on_typed_weapon_energy_changed(current_energy: float, max_energy: float) -> void:
	if max_energy <= 0.0:
		_energy_meter.set_empty()
		return

	_last_max_energy = max_energy
	_energy_meter.set_energy(current_energy, max_energy)


func _on_typed_weapon_expired(_family_id: String) -> void:
	_energy_meter.set_energy(0.0, maxf(_last_max_energy, 1.0))
	var tree := get_tree()
	if tree == null:
		_energy_meter.set_empty()
		return

	await tree.create_timer(EXPIRY_INACTIVE_DELAY).timeout
	if _typed_weapon_slot == null or !_typed_weapon_slot.has_method("has_weapon") or !_typed_weapon_slot.call("has_weapon"):
		_energy_meter.set_empty()


func _on_typed_weapon_refilled(_family_id: String) -> void:
	_energy_meter.flash_refill()
