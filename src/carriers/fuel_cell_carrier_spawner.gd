extends Node2D
class_name FuelCellCarrierSpawner

signal fuel_cell_carrier_spawned(position: Vector2)

@export var carrier_scene: PackedScene
@export var spawn_interval_seconds := 15.0
@export var playfield_width := 540.0
@export var playfield_height := 960.0
@export var off_screen_margin := 56.0
@export var bottom_spawn_y := 1016.0
@export var typed_weapon_slot_path: NodePath

var _time_until_next_spawn := 0.0
var _typed_weapon_slot: Node
var _slot_had_weapon_last_tick := false


func _ready() -> void:
	_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)
	_typed_weapon_slot = _resolve_typed_weapon_slot()


func _physics_process(delta: float) -> void:
	if _typed_weapon_slot == null:
		_typed_weapon_slot = _resolve_typed_weapon_slot()

	var has_weapon := _slot_has_weapon()
	if has_weapon and !_slot_had_weapon_last_tick:
		_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)
	_slot_had_weapon_last_tick = has_weapon

	if !has_weapon:
		return

	_time_until_next_spawn -= delta
	if _time_until_next_spawn > 0.0:
		return

	_spawn_carrier()
	_time_until_next_spawn += maxf(spawn_interval_seconds, 0.01)


func _spawn_carrier() -> Node2D:
	if carrier_scene == null:
		push_warning("FuelCellCarrierSpawner has no carrier_scene assigned.")
		return null

	var carrier := carrier_scene.instantiate() as Node2D
	if carrier == null:
		push_warning("FuelCellCarrierSpawner carrier_scene must instantiate a Node2D.")
		return null

	carrier.set("playfield_width", playfield_width)
	carrier.set("playfield_height", playfield_height)
	carrier.set("off_screen_margin", off_screen_margin)
	var spawn_x := randf_range(off_screen_margin, playfield_width - off_screen_margin)
	var spawn_y := bottom_spawn_y
	if spawn_y <= 0.0:
		spawn_y = playfield_height + off_screen_margin
	carrier.position = Vector2(spawn_x, spawn_y)
	add_child(carrier)
	fuel_cell_carrier_spawned.emit(carrier.global_position)
	print("fuel_cell_carrier_spawned position=%s" % carrier.global_position)
	return carrier


func _slot_has_weapon() -> bool:
	if _typed_weapon_slot == null or !_typed_weapon_slot.has_method("has_weapon"):
		return false

	return bool(_typed_weapon_slot.call("has_weapon"))


func _resolve_typed_weapon_slot() -> Node:
	if typed_weapon_slot_path != NodePath() and has_node(typed_weapon_slot_path):
		return get_node(typed_weapon_slot_path)

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("TypedWeaponSlot", true, false)
