extends Area2D
class_name FuelCellCarrier

signal fuel_cell_collected(spawn_position: Vector2)

enum TravelState { ASCENT, DESCENT }

@export var ascent_speed := 220.0
@export var descent_speed := 50.0
@export var apex_y_min := 360.0
@export var apex_y_max := 440.0
@export var sway_amplitude := 22.0
@export var sway_period := 1.9
@export var playfield_width := 540.0
@export var playfield_height := 960.0
@export var off_screen_margin := 56.0
@export var half_width := 24.0
@export var pickup_burst_scene: PackedScene

var _state := TravelState.ASCENT
var _apex_y := 400.0
var _descent_anchor_x := 0.0
var _sway_phase := 0.0
var _descent_age := 0.0
var _collected := false


func _ready() -> void:
	_apex_y = randf_range(minf(apex_y_min, apex_y_max), maxf(apex_y_min, apex_y_max))
	_sway_phase = randf_range(0.0, TAU)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	# Intentionally no take_damage method: projectiles pass through harmlessly per T012.


func _physics_process(delta: float) -> void:
	if _collected:
		return

	if _state == TravelState.ASCENT:
		_process_ascent(delta)
	else:
		_process_descent(delta)


func is_descending() -> bool:
	return _state == TravelState.DESCENT


func _process_ascent(delta: float) -> void:
	position.y -= ascent_speed * delta
	position.x = clampf(position.x, half_width, playfield_width - half_width)
	if position.y > _apex_y:
		return

	position.y = _apex_y
	_descent_anchor_x = position.x
	_descent_age = 0.0
	_state = TravelState.DESCENT


func _process_descent(delta: float) -> void:
	_descent_age += delta
	position.y += descent_speed * delta
	var period := maxf(sway_period, 0.01)
	var swayed_x := _descent_anchor_x + sin((_descent_age / period) * TAU + _sway_phase) * sway_amplitude
	position.x = clampf(swayed_x, half_width, playfield_width - half_width)

	if position.y > playfield_height + off_screen_margin:
		print("fuel_cell_carrier_exited position=%s" % global_position)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	_try_collect_from(area)


func _on_body_entered(body: Node) -> void:
	_try_collect_from(body)


func _try_collect_from(other: Node) -> void:
	if _collected or other == null:
		return

	if _state != TravelState.DESCENT:
		return

	if _resolve_typed_weapon_slot(other) == null:
		return

	_collected = true
	var collection_position := global_position
	fuel_cell_collected.emit(collection_position)
	print("fuel_cell_collected position=%s" % collection_position)
	_spawn_pickup_burst(collection_position)
	queue_free()


func _resolve_typed_weapon_slot(start: Node) -> Node:
	var current := start
	while current != null:
		var slot := current.get_node_or_null("TypedWeaponSlot")
		if slot != null:
			return slot
		current = current.get_parent()

	return null


func _spawn_pickup_burst(spawn_position: Vector2) -> void:
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
		(burst as Node2D).global_position = spawn_position
