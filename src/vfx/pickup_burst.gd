extends Node2D

const COLORS := [
	Color(1.0, 0.96, 0.62, 1.0),
	Color(1.0, 0.64, 0.18, 1.0),
	Color(0.22, 0.96, 1.0, 1.0),
	Color(1.0, 1.0, 1.0, 1.0),
]

@export var fragment_count := 9
@export var lifetime := 0.22
@export var min_speed := 90.0
@export var max_speed := 190.0
@export var fragment_size := 4.0

var _fragments: Array[Dictionary] = []
var _age := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var count := clampi(fragment_count, 6, 10)
	for index in count:
		var direction := Vector2.RIGHT.rotated((TAU / count) * index + rng.randf_range(-0.28, 0.28))
		_fragments.append({
			"position": Vector2.ZERO,
			"velocity": direction * rng.randf_range(min_speed, max_speed),
			"color": COLORS[rng.randi_range(0, COLORS.size() - 1)],
			"size": rng.randf_range(fragment_size * 0.75, fragment_size * 1.3),
		})


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	for fragment in _fragments:
		fragment["position"] = (fragment["position"] as Vector2) + (fragment["velocity"] as Vector2) * delta

	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - clampf(_age / lifetime, 0.0, 1.0)
	for fragment in _fragments:
		var size := float(fragment["size"])
		var color := fragment["color"] as Color
		color.a = alpha
		draw_rect(Rect2((fragment["position"] as Vector2) - Vector2(size, size) * 0.5, Vector2(size, size)), color)
