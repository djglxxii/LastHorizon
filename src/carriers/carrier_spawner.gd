extends Node2D
class_name CarrierSpawner

@export var carrier_scene: PackedScene
@export var spawn_interval_seconds := 8.0
@export var spawn_y_min := 200.0
@export var spawn_y_max := 500.0
@export var playfield_width := 540.0
@export var off_screen_margin := 56.0

var _time_until_next_spawn := 0.0
var _next_direction := 1.0


func _ready() -> void:
	_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)


func _physics_process(delta: float) -> void:
	_time_until_next_spawn -= delta
	if _time_until_next_spawn > 0.0:
		return

	_spawn_carrier()
	_time_until_next_spawn += maxf(spawn_interval_seconds, 0.01)


func _spawn_carrier() -> Node2D:
	if carrier_scene == null:
		push_warning("CarrierSpawner has no carrier_scene assigned.")
		return null

	var carrier := carrier_scene.instantiate() as Node2D
	if carrier == null:
		push_warning("CarrierSpawner carrier_scene must instantiate a Node2D.")
		return null

	var direction := _next_direction
	_next_direction *= -1.0

	carrier.set("direction", direction)
	carrier.set("playfield_width", playfield_width)
	carrier.set("off_screen_margin", off_screen_margin)
	var spawn_x := -off_screen_margin if direction > 0.0 else playfield_width + off_screen_margin
	carrier.position = Vector2(spawn_x, randf_range(spawn_y_min, spawn_y_max))
	add_child(carrier)
	return carrier
