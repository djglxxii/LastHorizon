extends Node2D

const PLAYFIELD_WIDTH := 540.0
const DEFAULT_Y := 850.0
const HALF_WIDTH := 24.0
const GAMEPAD_DEADZONE := 0.2

@export var move_speed := 360.0
@export var playfield_width := PLAYFIELD_WIDTH
@export var fixed_y := DEFAULT_Y
@export var half_width := HALF_WIDTH
@export var debug_starting_family: TypedWeaponFamily


func _ready() -> void:
	clamp_to_playfield()
	_equip_debug_starting_family()


func _physics_process(delta: float) -> void:
	var horizontal_input := _get_horizontal_input()
	position.x += horizontal_input * move_speed * delta
	clamp_to_playfield()


func clamp_to_playfield() -> void:
	position.x = clampf(position.x, left_bound_x(), right_bound_x())
	position.y = fixed_y


func left_bound_x() -> float:
	return half_width


func right_bound_x() -> float:
	return playfield_width - half_width


func _get_horizontal_input() -> float:
	var axis := Input.get_axis("ui_left", "ui_right")

	if Input.is_key_pressed(KEY_A):
		axis -= 1.0
	if Input.is_key_pressed(KEY_D):
		axis += 1.0

	var gamepad_axis := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(gamepad_axis) > GAMEPAD_DEADZONE:
		axis += gamepad_axis

	return clampf(axis, -1.0, 1.0)


func _equip_debug_starting_family() -> void:
	# T004 debug bootstrap. T009 replaces this with weapon-chip pickup equip flow.
	if debug_starting_family == null or !has_node("TypedWeaponSlot"):
		return

	var typed_weapon_slot := get_node("TypedWeaponSlot")
	if typed_weapon_slot.has_method("equip"):
		typed_weapon_slot.equip(debug_starting_family)
