extends Node2D

@export var speed := 760.0
@export var damage := 2.0
@export var pierce := false
@export var direction := Vector2.UP
@export var playfield_width := 540.0
@export var despawn_margin := 32.0

var _hit_targets: Array[int] = []


func _ready() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox != null:
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity() * delta

	if _is_outside_playfield():
		queue_free()


func configure_from_family(family: TypedWeaponFamily) -> void:
	if family == null:
		return

	speed = family.projectile_speed
	damage = family.projectile_damage
	pierce = family.pierce
	set_projectile_sprite(family.projectile_sprite, family.tint_color)


func set_speed(value: float) -> void:
	speed = value


func set_damage(value: float) -> void:
	damage = value


func set_projectile_sprite(texture: Texture2D, tint := Color.WHITE) -> void:
	if !has_node("Sprite2D"):
		return

	var sprite := get_node("Sprite2D") as Sprite2D
	if texture != null:
		sprite.texture = texture
	sprite.modulate = tint


func velocity() -> Vector2:
	if direction.is_zero_approx():
		return Vector2.UP * speed

	return direction.normalized() * speed


func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_queued_for_deletion():
		return

	var target := area.get_parent()
	if target == null or !target.has_method("take_damage"):
		return

	var target_id := target.get_instance_id()
	if pierce and _hit_targets.has(target_id):
		return

	if pierce:
		_hit_targets.append(target_id)

	target.take_damage(damage, global_position)
	if !pierce:
		queue_free()


func _is_outside_playfield() -> bool:
	return (
		global_position.y < -despawn_margin
		or global_position.x < -despawn_margin
		or global_position.x > playfield_width + despawn_margin
	)
