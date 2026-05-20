extends Node2D

signal bullet_fired(bullet: Node2D)

const MIN_FIRE_INTERVAL := 0.01
const MAX_CATCHUP_SHOTS := 4

@export var bullet_scene: PackedScene
@export var fire_interval := 0.125
@export var bullet_speed := 960.0
@export var bullet_parent_path: NodePath

var _time_until_next_shot := 0.0


func _ready() -> void:
	_time_until_next_shot = 0.0


func _physics_process(delta: float) -> void:
	var interval := maxf(fire_interval, MIN_FIRE_INTERVAL)
	_time_until_next_shot -= delta

	var shots_fired := 0
	while _time_until_next_shot <= 0.0 and shots_fired < MAX_CATCHUP_SHOTS:
		fire_once()
		_time_until_next_shot += interval
		shots_fired += 1


func fire_once() -> Node2D:
	if bullet_scene == null:
		push_warning("PeaShooter has no bullet_scene assigned.")
		return null

	var bullet := bullet_scene.instantiate() as Node2D
	if bullet == null:
		push_warning("PeaShooter bullet_scene must instantiate a Node2D.")
		return null

	bullet.set_speed(bullet_speed)

	var bullet_parent := _resolve_bullet_parent()
	var spawn_position := _spawn_position()
	bullet_parent.add_child(bullet)
	bullet.position = spawn_position

	bullet_fired.emit(bullet)
	return bullet


func _resolve_bullet_parent() -> Node:
	if bullet_parent_path != NodePath() and has_node(bullet_parent_path):
		return get_node(bullet_parent_path)

	var current_scene := get_tree().current_scene
	if current_scene != null:
		return current_scene

	return get_tree().root


func _spawn_position() -> Vector2:
	if is_inside_tree():
		return global_position

	var resolved_position := position
	var current := get_parent()
	while current != null:
		if current is Node2D:
			resolved_position += (current as Node2D).position
		current = current.get_parent()

	return resolved_position
