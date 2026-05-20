extends Node2D

@export var speed := 960.0
@export var playfield_width := 540.0
@export var despawn_margin := 32.0


func _physics_process(delta: float) -> void:
	global_position += velocity() * delta

	if _is_outside_playfield():
		queue_free()


func set_speed(value: float) -> void:
	speed = value


func velocity() -> Vector2:
	return Vector2.UP * speed


func _is_outside_playfield() -> bool:
	return (
		global_position.y < -despawn_margin
		or global_position.x < -despawn_margin
		or global_position.x > playfield_width + despawn_margin
	)
