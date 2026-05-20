extends Node2D
class_name BaselineEnemy

@export var max_hp := 3.0
@export var sway_amplitude := 5.0
@export var sway_period := 2.4

var _slot_position := Vector2.ZERO
var _sway_phase := 0.0
var _age := 0.0


func _ready() -> void:
	_slot_position = position
	_sway_phase = randf_range(0.0, TAU)


func _physics_process(delta: float) -> void:
	_age += delta
	var period := maxf(sway_period, 0.01)
	position = _slot_position + Vector2(sin((_age / period) * TAU + _sway_phase) * sway_amplitude, 0.0)


func configure_sway(amplitude: float, period: float) -> void:
	sway_amplitude = maxf(amplitude, 0.0)
	sway_period = maxf(period, 0.01)
