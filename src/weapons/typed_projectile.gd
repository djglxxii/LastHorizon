extends Node2D

@export var speed := 760.0
@export var damage := 2.0
@export var playfield_width := 540.0
@export var despawn_margin := 32.0


func _physics_process(delta: float) -> void:
	global_position += velocity() * delta

	if _is_outside_playfield():
		queue_free()


func configure_from_family(family: TypedWeaponFamily) -> void:
	if family == null:
		return

	speed = family.projectile_speed
	damage = family.projectile_damage
	set_projectile_sprite(family.projectile_sprite)


func set_speed(value: float) -> void:
	speed = value


func set_damage(value: float) -> void:
	damage = value


func set_projectile_sprite(texture: Texture2D) -> void:
	if texture == null or !has_node("Sprite2D"):
		return

	var sprite := get_node("Sprite2D") as Sprite2D
	sprite.texture = texture


func velocity() -> Vector2:
	return Vector2.UP * speed


func _is_outside_playfield() -> bool:
	return (
		global_position.y < -despawn_margin
		or global_position.x < -despawn_margin
		or global_position.x > playfield_width + despawn_margin
	)
