extends Node2D
class_name WeaponChipCarrier

signal damaged(amount: float, hit_position: Vector2)
signal killed
signal carrier_killed(death_position: Vector2)

const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/DamageNumber.tscn")
const PIXEL_BURST_SCENE := preload("res://scenes/vfx/PixelBurst.tscn")

@export var max_hp := 2.0
@export var sweep_speed := 110.0
@export var sway_amplitude := 24.0
@export var sway_period := 1.8
@export var playfield_width := 540.0
@export var off_screen_margin := 56.0
@export var direction := 1.0
@export var chip_scene: PackedScene

var family: TypedWeaponFamily
var current_hp := 0.0

var _anchor_y := 0.0
var _sway_phase := 0.0
var _age := 0.0
var _dead := false


func _ready() -> void:
	current_hp = max_hp
	_anchor_y = position.y
	_sway_phase = randf_range(0.0, TAU)
	direction = 1.0 if direction >= 0.0 else -1.0
	_apply_family_tint()


func set_family(weapon_family: TypedWeaponFamily) -> void:
	family = weapon_family
	_apply_family_tint()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_age += delta
	var period := maxf(sway_period, 0.01)
	position.x += direction * sweep_speed * delta
	position.y = _anchor_y + sin((_age / period) * TAU + _sway_phase) * sway_amplitude

	if _has_cleared_opposite_side():
		queue_free()


func take_damage(amount: float, hit_position := Vector2.INF) -> void:
	if _dead:
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
	if _dead:
		return

	_dead = true
	var death_position := global_position
	killed.emit()
	carrier_killed.emit(death_position)
	_spawn_chip(death_position)
	_spawn_pixel_burst(death_position)
	queue_free()


func _spawn_chip(spawn_position: Vector2) -> void:
	if chip_scene == null:
		push_warning("WeaponChipCarrier has no chip_scene assigned.")
		return

	var chip := chip_scene.instantiate()
	if chip == null:
		return

	_add_feedback_child(chip)
	if chip.has_method("set_family"):
		chip.set_family(family)
	if chip is Node2D:
		(chip as Node2D).global_position = spawn_position
	if chip.has_method("reset_sway_anchor"):
		chip.reset_sway_anchor()


func _spawn_damage_number(amount: float, spawn_position: Vector2) -> void:
	var damage_number := DAMAGE_NUMBER_SCENE.instantiate()
	if damage_number == null:
		return

	_add_feedback_child(damage_number)
	if damage_number is Node2D:
		(damage_number as Node2D).global_position = spawn_position
	if damage_number.has_method("set_damage"):
		damage_number.set_damage(amount)


func _spawn_pixel_burst(spawn_position: Vector2) -> void:
	var burst := PIXEL_BURST_SCENE.instantiate()
	if burst == null:
		return

	_add_feedback_child(burst)
	if burst is Node2D:
		(burst as Node2D).global_position = spawn_position


func _has_cleared_opposite_side() -> bool:
	if direction > 0.0:
		return global_position.x > playfield_width + off_screen_margin

	return global_position.x < -off_screen_margin


func _add_feedback_child(node: Node) -> void:
	var feedback_parent := get_tree().current_scene if is_inside_tree() else null
	if feedback_parent == null:
		feedback_parent = get_parent()

	if feedback_parent == null:
		node.queue_free()
		return

	feedback_parent.add_child(node)


func _apply_family_tint() -> void:
	if family == null or !has_node("Sprite2D"):
		return

	var sprite := get_node("Sprite2D") as Sprite2D
	sprite.modulate = family.tint_color
