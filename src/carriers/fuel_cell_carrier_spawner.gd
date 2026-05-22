extends Node2D
class_name FuelCellCarrierSpawner

signal fuel_cell_carrier_spawned(position: Vector2)

@export var carrier_scene: PackedScene
@export var spawn_interval_seconds := 30.0
@export var playfield_width := 540.0
@export var playfield_height := 960.0
@export var off_screen_margin := 56.0
@export var bottom_spawn_y := 1016.0

var _time_until_next_spawn := 0.0


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
