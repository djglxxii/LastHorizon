extends Node2D

@export var speed := 960.0
@export var damage := 1.0
@export var playfield_width := 540.0
@export var despawn_margin := 32.0


func _ready() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox != null:
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity() * delta

	if _is_outside_playfield():
		queue_free()


func set_speed(value: float) -> void:
	speed = value


func velocity() -> Vector2:
	return Vector2.UP * speed


func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_queued_for_deletion():
		return

	var target := area.get_parent()
	if target == null or !target.has_method("take_damage"):
		return

	target.take_damage(damage, global_position)
	queue_free()


func _is_outside_playfield() -> bool:
	return (
		global_position.y < -despawn_margin
		or global_position.x < -despawn_margin
		or global_position.x > playfield_width + despawn_margin
	)
