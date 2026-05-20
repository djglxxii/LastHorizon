extends Node2D
class_name EnemySpawner

@export var formation_scene: PackedScene
@export var rows := 3
@export var cols := 5
@export var cell_size := Vector2(82.0, 66.0)
@export var descent_speed := 65.0
@export var sway_amplitude := 5.0
@export var sway_period := 2.4
@export var spawn_interval_seconds := 2.35
@export var playfield_width := 540.0
@export var playfield_height := 960.0
@export var spawn_y := -160.0

var _time_until_next_spawn := 0.0


func _ready() -> void:
	_spawn_formation()
	_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)


func _physics_process(delta: float) -> void:
	_time_until_next_spawn -= delta
	if _time_until_next_spawn > 0.0:
		return

	_spawn_formation()
	_time_until_next_spawn += maxf(spawn_interval_seconds, 0.01)


func _spawn_formation() -> Node2D:
	if formation_scene == null:
		push_warning("EnemySpawner has no formation_scene assigned.")
		return null

	var formation := formation_scene.instantiate() as Node2D
	if formation == null:
		push_warning("EnemySpawner formation_scene must instantiate a Node2D.")
		return null

	if formation.has_method("configure"):
		formation.configure(rows, cols, cell_size, descent_speed, sway_amplitude, sway_period, playfield_height)

	var spawn_x := playfield_width * 0.5
	formation.position = Vector2(spawn_x, spawn_y)
	add_child(formation)
	return formation
