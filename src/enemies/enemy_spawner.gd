extends Node2D
class_name EnemySpawner

@export var formation_scene: PackedScene
@export var rows := 3
@export var cols := 5
@export var cell_size := Vector2(82.0, 66.0)
@export var descent_speed := 32.5
@export var sway_amplitude := 5.0
@export var sway_period := 2.4
# spawn_interval_seconds * descent_speed must equal rows * cell_size.y to keep the armada on a continuous grid (T020).
@export var spawn_interval_seconds := 6.09
@export var playfield_width := 540.0
@export var playfield_height := 960.0
@export var spawn_y := -160.0
@export var elite_ramp_seconds := 90.0
@export var elite_chance_max := 0.20

var _time_until_next_spawn := 0.0
var _stagger_index := 0
var _run_age_seconds := 0.0


func _ready() -> void:
	_validate_grid_aligned_interval()
	_spawn_formation()
	_time_until_next_spawn = maxf(spawn_interval_seconds, 0.01)


func _physics_process(delta: float) -> void:
	_run_age_seconds += delta
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
		formation.configure(
			rows,
			cols,
			cell_size,
			descent_speed,
			sway_amplitude,
			sway_period,
			playfield_height,
			current_elite_chance(),
			_run_age_seconds
		)

	var spawn_x := playfield_width * 0.5
	if (_stagger_index % 2) == 1:
		spawn_x += cell_size.x * 0.5

	formation.position = Vector2(spawn_x, spawn_y)
	_stagger_index += 1
	add_child(formation)
	return formation


func current_elite_chance() -> float:
	var ramp_ratio := clampf(_run_age_seconds / maxf(elite_ramp_seconds, 0.01), 0.0, 1.0)
	return ramp_ratio * clampf(elite_chance_max, 0.0, 1.0)


func _validate_grid_aligned_interval() -> void:
	var expected_pixels := float(rows) * cell_size.y
	var actual_pixels := maxf(spawn_interval_seconds, 0.01) * descent_speed
	if absf(actual_pixels - expected_pixels) <= 0.5:
		return

	var expected_interval := expected_pixels / maxf(descent_speed, 0.01)
	push_warning(
		"EnemySpawner: spawn_interval_seconds (%.2f) moves %.2f px, expected %.2f px (%.2f s) for grid-aligned armada spacing."
			% [spawn_interval_seconds, actual_pixels, expected_pixels, expected_interval]
	)
