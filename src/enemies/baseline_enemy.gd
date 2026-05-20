extends Node2D
class_name BaselineEnemy

signal damaged(amount: float, hit_position: Vector2)
signal killed
signal leaked(impact_position: Vector2)

const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/DamageNumber.tscn")
const PIXEL_BURST_SCENE := preload("res://scenes/vfx/PixelBurst.tscn")
const PLANET_IMPACT_SCENE := preload("res://scenes/vfx/PlanetImpact.tscn")

@export var max_hp := 5.0
@export var sway_amplitude := 5.0
@export var sway_period := 2.4
@export var planet_line_y := 900.0
@export var leak_damage_per_enemy := 10.0

var current_hp := 0.0

var _slot_position := Vector2.ZERO
var _sway_phase := 0.0
var _age := 0.0
var _dead := false
var _leaked := false
var _defense_grid: Node


func _ready() -> void:
	current_hp = max_hp
	_slot_position = position
	_sway_phase = randf_range(0.0, TAU)
	_defense_grid = _resolve_defense_grid()


func _physics_process(delta: float) -> void:
	if _dead or _leaked:
		return

	_age += delta
	var period := maxf(sway_period, 0.01)
	position = _slot_position + Vector2(sin((_age / period) * TAU + _sway_phase) * sway_amplitude, 0.0)

	if global_position.y >= planet_line_y:
		_leak()


func configure_sway(amplitude: float, period: float) -> void:
	sway_amplitude = maxf(amplitude, 0.0)
	sway_period = maxf(period, 0.01)


func take_damage(amount: float, hit_position := Vector2.INF) -> void:
	if _dead or _leaked:
		return

	var applied_damage := maxf(amount, 0.0)
	if applied_damage <= 0.0:
		return

	var resolved_hit_position := hit_position
	if resolved_hit_position == Vector2.INF:
		resolved_hit_position = global_position

	current_hp = maxf(current_hp - applied_damage, 0.0)
	damaged.emit(applied_damage, resolved_hit_position)
	_spawn_damage_number(applied_damage, resolved_hit_position)

	if current_hp <= 0.0:
		_kill()


func _kill() -> void:
	if _dead or _leaked:
		return

	_dead = true
	killed.emit()
	_spawn_pixel_burst()
	queue_free()


func _leak() -> void:
	if _dead or _leaked:
		return

	_leaked = true
	var impact_position := global_position
	if _defense_grid != null and _defense_grid.has_method("apply_leak_damage"):
		_defense_grid.apply_leak_damage(leak_damage_per_enemy, impact_position)
	leaked.emit(impact_position)
	_spawn_planet_impact(impact_position)
	queue_free()


func _spawn_damage_number(amount: float, spawn_position: Vector2) -> void:
	var damage_number := DAMAGE_NUMBER_SCENE.instantiate()
	if damage_number == null:
		return

	_add_feedback_child(damage_number)
	if damage_number is Node2D:
		(damage_number as Node2D).global_position = spawn_position
	if damage_number.has_method("set_damage"):
		damage_number.set_damage(amount)


func _spawn_pixel_burst() -> void:
	var burst := PIXEL_BURST_SCENE.instantiate()
	if burst == null:
		return

	_add_feedback_child(burst)
	if burst is Node2D:
		(burst as Node2D).global_position = global_position


func _spawn_planet_impact(impact_position: Vector2) -> void:
	var impact := PLANET_IMPACT_SCENE.instantiate()
	if impact == null:
		return

	_add_feedback_child(impact)
	if impact is Node2D:
		(impact as Node2D).global_position = impact_position


func _resolve_defense_grid() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	var current_scene := tree.current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("DefenseGrid", true, false)


func _add_feedback_child(node: Node) -> void:
	var feedback_parent := get_tree().current_scene if is_inside_tree() else null
	if feedback_parent == null:
		feedback_parent = get_parent()

	if feedback_parent == null:
		node.queue_free()
		return

	feedback_parent.add_child(node)
