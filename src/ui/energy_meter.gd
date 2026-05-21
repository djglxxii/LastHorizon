extends Control
class_name EnergyMeter

const ACTIVE_BACKGROUND := Color(0.025, 0.045, 0.07, 0.92)
const ACTIVE_BORDER := Color(0.12, 0.72, 0.88, 1.0)
const ACTIVE_FILL := Color(0.0, 0.88, 0.78, 1.0)
const REFILL_FLASH_BORDER := Color(0.62, 1.0, 1.0, 1.0)
const REFILL_FLASH_FILL := Color(0.78, 1.0, 0.98, 1.0)
const REFILL_FLASH_SECONDS := 0.25
const LOW_FILL := Color(1.0, 0.68, 0.18, 1.0)
const EMPTY_BACKGROUND := Color(0.09, 0.035, 0.04, 0.94)
const EMPTY_BORDER := Color(0.92, 0.24, 0.18, 1.0)
const INACTIVE_BACKGROUND := Color(0.035, 0.04, 0.05, 0.84)
const INACTIVE_BORDER := Color(0.22, 0.27, 0.31, 1.0)
const INACTIVE_FILL := Color(0.16, 0.18, 0.2, 1.0)
const ACTIVE_TEXT := Color(0.86, 0.98, 1.0, 1.0)
const INACTIVE_TEXT := Color(0.48, 0.54, 0.58, 1.0)

@onready var _bar: ProgressBar = %EnergyBar
@onready var _label: Label = %ValueLabel


func _ready() -> void:
	_bar.min_value = 0.0
	_bar.show_percentage = false
	set_empty()


func set_energy(current_energy: float, max_energy: float) -> void:
	var normalized_max := maxf(max_energy, 0.0)
	var normalized_current := clampf(current_energy, 0.0, normalized_max)

	if is_zero_approx(normalized_max):
		set_empty()
		return

	_bar.max_value = normalized_max
	_bar.value = normalized_current
	_label.text = "%d / %d" % [roundi(normalized_current), roundi(normalized_max)]

	var ratio := normalized_current / normalized_max
	var fill_color := ACTIVE_FILL
	if ratio <= 0.0:
		fill_color = LOW_FILL
	elif ratio <= 0.25:
		fill_color = LOW_FILL

	var background_color := ACTIVE_BACKGROUND
	var border_color := ACTIVE_BORDER
	var text_color := ACTIVE_TEXT
	if ratio <= 0.0:
		background_color = EMPTY_BACKGROUND
		border_color = EMPTY_BORDER

	_apply_style(background_color, border_color, fill_color, text_color)


func set_empty() -> void:
	_bar.max_value = 1.0
	_bar.value = 0.0
	_label.text = "-- / --"
	_apply_style(INACTIVE_BACKGROUND, INACTIVE_BORDER, INACTIVE_FILL, INACTIVE_TEXT)


func flash_refill() -> void:
	if !is_inside_tree():
		return

	_apply_style(ACTIVE_BACKGROUND, REFILL_FLASH_BORDER, REFILL_FLASH_FILL, ACTIVE_TEXT)

	var tree := get_tree()
	if tree == null:
		set_energy(_bar.value, _bar.max_value)
		return

	await tree.create_timer(REFILL_FLASH_SECONDS).timeout
	if !is_inside_tree():
		return

	set_energy(_bar.value, _bar.max_value)


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
