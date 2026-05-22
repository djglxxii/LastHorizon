extends Node2D
class_name EnemyFormation

const MAX_FORMATION_ENEMY_SPRITE_WIDTH := 60.0
# Kept for the existing T020 verifier; now represents the widest grid enemy.
const BASELINE_ENEMY_SPRITE_WIDTH := MAX_FORMATION_ENEMY_SPRITE_WIDTH
const SWAY_SAFETY_MARGIN := 2.0

@export var enemy_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var rows := 3
@export var cols := 5
@export var cell_size := Vector2(82.0, 66.0)
@export var descent_speed := 32.5
@export var sway_amplitude := 5.0
@export var sway_period := 2.4
@export var playfield_height := 960.0
@export var despawn_margin := 72.0

var elite_chance := 0.0
var elite_chance_run_age := 0.0


func _ready() -> void:
	_spawn_block()


func _physics_process(delta: float) -> void:
	position.y += descent_speed * delta

	if get_child_count() == 0:
		queue_free()
		return

	if _top_edge_y() > playfield_height + despawn_margin:
		queue_free()


func configure(
	block_rows: int,
	block_cols: int,
	block_cell_size: Vector2,
	block_descent_speed: float,
	block_sway_amplitude: float,
	block_sway_period: float,
	block_playfield_height: float,
	block_elite_chance := 0.0,
	block_run_age_seconds := 0.0
) -> void:
	rows = maxi(block_rows, 1)
	cols = maxi(block_cols, 1)
	cell_size = block_cell_size
	descent_speed = maxf(block_descent_speed, 0.0)
	sway_amplitude = maxf(block_sway_amplitude, 0.0)
	sway_period = maxf(block_sway_period, 0.01)
	playfield_height = maxf(block_playfield_height, 1.0)
	elite_chance = clampf(block_elite_chance, 0.0, 1.0)
	elite_chance_run_age = maxf(block_run_age_seconds, 0.0)


func _spawn_block() -> void:
	if enemy_scene == null:
		push_warning("EnemyFormation has no enemy_scene assigned.")
		return

	var effective_sway_amplitude := _clamped_sway_amplitude()
	sway_amplitude = effective_sway_amplitude
	var warned_no_elite_scene := false

	var start_x := -float(cols - 1) * cell_size.x * 0.5
	var start_y := -float(rows - 1) * cell_size.y * 0.5

	for row in rows:
		for col in cols:
			var rolled_elite := elite_chance > 0.0 and randf() < elite_chance
			var scene_to_spawn := enemy_scene
			if rolled_elite:
				if elite_enemy_scene != null:
					scene_to_spawn = elite_enemy_scene
				elif !warned_no_elite_scene:
					warned_no_elite_scene = true
					push_warning("EnemyFormation: elite_chance > 0 but no elite_enemy_scene assigned; spawning baseline.")

			var enemy := scene_to_spawn.instantiate() as Node2D
			if enemy == null:
				push_warning("EnemyFormation enemy_scene must instantiate a Node2D.")
				return

			enemy.position = Vector2(start_x + col * cell_size.x, start_y + row * cell_size.y)
			if enemy.has_method("configure_sway"):
				enemy.configure_sway(effective_sway_amplitude, sway_period)
			add_child(enemy)

			if rolled_elite and scene_to_spawn == elite_enemy_scene:
				print(
					"elite_spawned slot_row=%d slot_col=%d formation_age=%.2f elite_chance=%.2f"
						% [row, col, elite_chance_run_age, elite_chance]
				)


func _top_edge_y() -> float:
	return global_position.y - float(rows - 1) * cell_size.y * 0.5


func _clamped_sway_amplitude() -> float:
	var max_amplitude := maxf((cell_size.x - BASELINE_ENEMY_SPRITE_WIDTH) * 0.5 - SWAY_SAFETY_MARGIN, 0.0)
	if sway_amplitude <= max_amplitude:
		return sway_amplitude

	push_warning(
		"EnemyFormation: sway_amplitude %.1f exceeds safe cap %.1f for cell_size.x %.1f; clamping."
			% [sway_amplitude, max_amplitude, cell_size.x]
	)
	return max_amplitude
