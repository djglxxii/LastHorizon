extends Node2D
class_name EnemyFormation

@export var enemy_scene: PackedScene
@export var rows := 3
@export var cols := 5
@export var cell_size := Vector2(82.0, 66.0)
@export var descent_speed := 32.5
@export var sway_amplitude := 5.0
@export var sway_period := 2.4
@export var playfield_height := 960.0
@export var despawn_margin := 72.0


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
	block_playfield_height: float
) -> void:
	rows = maxi(block_rows, 1)
	cols = maxi(block_cols, 1)
	cell_size = block_cell_size
	descent_speed = maxf(block_descent_speed, 0.0)
	sway_amplitude = maxf(block_sway_amplitude, 0.0)
	sway_period = maxf(block_sway_period, 0.01)
	playfield_height = maxf(block_playfield_height, 1.0)


func _spawn_block() -> void:
	if enemy_scene == null:
		push_warning("EnemyFormation has no enemy_scene assigned.")
		return

	var start_x := -float(cols - 1) * cell_size.x * 0.5
	var start_y := -float(rows - 1) * cell_size.y * 0.5

	for row in rows:
		for col in cols:
			var enemy := enemy_scene.instantiate() as Node2D
			if enemy == null:
				push_warning("EnemyFormation enemy_scene must instantiate a Node2D.")
				return

			enemy.position = Vector2(start_x + col * cell_size.x, start_y + row * cell_size.y)
			if enemy.has_method("configure_sway"):
				enemy.configure_sway(sway_amplitude, sway_period)
			add_child(enemy)


func _top_edge_y() -> float:
	return global_position.y - float(rows - 1) * cell_size.y * 0.5
