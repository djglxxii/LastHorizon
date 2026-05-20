extends Control
class_name GridMeter

const BACKGROUND := Color(0.025, 0.04, 0.075, 0.94)
const BORDER := Color(0.15, 0.62, 1.0, 1.0)
const FILL := Color(0.1, 0.72, 1.0, 1.0)
const LOW_FILL := Color(0.95, 0.2, 0.22, 1.0)
const TEXT := Color(0.88, 0.97, 1.0, 1.0)
const FLASH_FILL := Color(1.0, 0.95, 0.9, 1.0)
const FLASH_BORDER := Color(1.0, 0.2, 0.18, 1.0)
const TWEEN_SECONDS := 0.15

@export var defense_grid_path: NodePath

@onready var _bar: ProgressBar = %GridBar
@onready var _label: Label = %ValueLabel

var _grid: Node
var _value_tween: Tween
var _flash_tween: Tween
var _current_fill := FILL


func _ready() -> void:
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false
	_apply_style(BACKGROUND, BORDER, FILL, TEXT)
	bind_defense_grid(defense_grid_path)


func bind_defense_grid(grid_path: NodePath) -> void:
	_bind_defense_grid_node(null)
	defense_grid_path = grid_path
	_bind_defense_grid_node(_resolve_defense_grid())


func bind_defense_grid_node(grid: Node) -> void:
	_bind_defense_grid_node(grid)


func _bind_defense_grid_node(grid: Node) -> void:
	if _grid != null:
		if _grid.integrity_changed.is_connected(_on_integrity_changed):
			_grid.integrity_changed.disconnect(_on_integrity_changed)
		if _grid.leak_registered.is_connected(_on_leak_registered):
			_grid.leak_registered.disconnect(_on_leak_registered)

	_grid = grid
	if _grid == null:
		set_grid(0.0, 0.0, true)
		return

	_grid.integrity_changed.connect(_on_integrity_changed)
	_grid.leak_registered.connect(_on_leak_registered)
	var current := float(_grid.current_integrity)
	var max_value := float(_grid.max_integrity)
	set_grid(current, max_value, true)


func set_grid(current_integrity: float, max_integrity: float, immediate := false) -> void:
	var normalized_max := maxf(max_integrity, 0.0)
	var normalized_current := clampf(current_integrity, 0.0, normalized_max)

	if is_zero_approx(normalized_max):
		_bar.max_value = 1.0
		_bar.value = 0.0
		_label.text = "GRID -- / --"
		_apply_style(BACKGROUND, BORDER, LOW_FILL, TEXT)
		return

	_bar.max_value = normalized_max
	_label.text = "GRID %d / %d" % [roundi(normalized_current), roundi(normalized_max)]
	_current_fill = LOW_FILL if normalized_current <= 0.0 else FILL
	_apply_style(BACKGROUND, BORDER, _current_fill, TEXT)

	if _value_tween != null:
		_value_tween.kill()

	if immediate:
		_bar.value = normalized_current
		return

	_value_tween = create_tween()
	_value_tween.tween_property(_bar, "value", normalized_current, TWEEN_SECONDS)


func _resolve_defense_grid() -> Node:
	if defense_grid_path != NodePath() and has_node(defense_grid_path):
		return get_node(defense_grid_path)

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("DefenseGrid", true, false)


func _on_integrity_changed(current: float, max_value: float) -> void:
	set_grid(current, max_value)


func _on_leak_registered(_amount: float, _impact_position: Vector2) -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	_apply_style(BACKGROUND, FLASH_BORDER, FLASH_FILL, TEXT)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(TWEEN_SECONDS)
	_flash_tween.tween_callback(func() -> void:
		_apply_style(BACKGROUND, BORDER, _current_fill, TEXT)
	)


func _apply_style(background_color: Color, border_color: Color, fill_color: Color, text_color: Color) -> void:
	_bar.add_theme_stylebox_override("background", _stylebox(background_color, border_color))
	_bar.add_theme_stylebox_override("fill", _stylebox(fill_color, Color.TRANSPARENT))
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)


func _stylebox(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = border_color
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.corner_radius_bottom_right = 3
	return stylebox
