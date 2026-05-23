extends Area2D
class_name WeaponChip

@export var drift_speed := 60.0
@export var sway_amplitude := 90.0
@export var sway_period := 1.6
@export var planet_line_y := 900.0
@export var playfield_width := 540.0
@export var half_width := 12.0
@export var pickup_burst_scene: PackedScene

var family: TypedWeaponFamily

var _anchor_x := 0.0
var _sway_phase := 0.0
var _age := 0.0
var _collected := false


func _ready() -> void:
	reset_sway_anchor()
	_sway_phase = randf_range(0.0, TAU)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_apply_family_identity()


func set_family(weapon_family: TypedWeaponFamily) -> void:
	family = weapon_family
	_apply_family_identity()


func reset_sway_anchor() -> void:
	_anchor_x = global_position.x


func _physics_process(delta: float) -> void:
	if _collected:
		return

	_age += delta
	var period := maxf(sway_period, 0.01)
	var swayed_x := _anchor_x + sin((_age / period) * TAU + _sway_phase) * sway_amplitude
	global_position = Vector2(clampf(swayed_x, half_width, playfield_width - half_width), global_position.y + drift_speed * delta)

	if global_position.y >= planet_line_y:
		print("chip_expired_at_planet_line position=%s" % global_position)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	_try_collect_from(area)


func _on_body_entered(body: Node) -> void:
	_try_collect_from(body)


func _try_collect_from(other: Node) -> void:
	if _collected or other == null:
		return

	var slot := _resolve_typed_weapon_slot(other)
	if slot == null or !slot.has_method("apply_chip_pickup"):
		return

	_collected = true
	slot.apply_chip_pickup(family)
	_spawn_pickup_burst()
	queue_free()


func _resolve_typed_weapon_slot(start: Node) -> Node:
	var current := start
	while current != null:
		var slot := current.get_node_or_null("TypedWeaponSlot")
		if slot != null:
			return slot
		current = current.get_parent()

	return null


func _spawn_pickup_burst() -> void:
	if pickup_burst_scene == null:
		return

	var burst := pickup_burst_scene.instantiate()
	if burst == null:
		return

	var feedback_parent := get_tree().current_scene if is_inside_tree() else null
	if feedback_parent == null:
		feedback_parent = get_parent()

	if feedback_parent == null:
		burst.queue_free()
		return

	feedback_parent.add_child(burst)
	if burst is Node2D:
		(burst as Node2D).global_position = global_position


func _apply_family_identity() -> void:
	var label := get_node_or_null("LetterGlyph") as Label
	if label != null:
		label.visible = false
		label.text = ""
		label.modulate = Color.WHITE

	if family == null:
		return

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = family.tint_color

	if label == null:
		return

	label.text = family.letter_glyph
	label.visible = !family.letter_glyph.is_empty()
