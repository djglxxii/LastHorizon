extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T005-energy-meter-hud-readout"
const PLAYER_SPRITE_PATH := "res://assets/sprites/player/player-ship.png"
const PEA_SPRITE_PATH := "res://assets/sprites/projectiles/pea-bullet.png"
const TYPED_SPRITE_PATH := "res://assets/sprites/projectiles/typed-plasma-bolt.png"
const WIDTH := 540
const HEIGHT := 960
const METER_RECT := Rect2i(155, 926, 230, 30)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	_render_frame("full-meter.png", 100.0, 100.0, true, 4, 0)
	_render_frame("drain-sequence-01-draining.png", 65.0, 100.0, true, 8, 5)
	_render_frame("drain-sequence-02-low.png", 30.0, 100.0, true, 10, 9)
	_render_frame("drain-sequence-03-expiring.png", 0.0, 100.0, true, 12, 0)
	_render_frame("empty-state.png", 0.0, 0.0, false, 13, 0)

	print("Saved T005 HUD visual evidence.")
	quit(0)


func _render_frame(file_name: String, current_energy: float, max_energy: float, active: bool, pea_count: int, typed_count: int) -> void:
	var image := _new_playfield_image()
	_draw_projectile_column(image, PEA_SPRITE_PATH, 260, 804, pea_count, 2.0)
	if typed_count > 0:
		_draw_projectile_column(image, TYPED_SPRITE_PATH, 282, 792, typed_count, 2.0)
	_draw_player(image, Vector2i(270, 850))
	_draw_energy_meter(image, current_energy, max_energy, active)
	_save(image, file_name)


func _new_playfield_image() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.025, 0.04))
	_draw_playfield_frame(image)
	return image


func _draw_playfield_frame(image: Image) -> void:
	_draw_line(image, Vector2i(0, 0), Vector2i(WIDTH - 1, 0), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, 0), Vector2i(WIDTH - 1, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, HEIGHT - 1), Vector2i(0, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(0, HEIGHT - 1), Vector2i(0, 0), Color(0.14, 0.55, 0.72))


func _draw_energy_meter(image: Image, current_energy: float, max_energy: float, active: bool) -> void:
	var background := Color(0.025, 0.045, 0.07, 0.92)
	var border := Color(0.12, 0.72, 0.88, 1.0)
	var fill := Color(0.0, 0.88, 0.78, 1.0)

	if !active:
		background = Color(0.035, 0.04, 0.05, 0.84)
		border = Color(0.22, 0.27, 0.31, 1.0)
		fill = Color(0.16, 0.18, 0.2, 1.0)
	elif current_energy <= 0.0:
		background = Color(0.09, 0.035, 0.04, 0.94)
		border = Color(0.92, 0.24, 0.18, 1.0)
		fill = Color(1.0, 0.68, 0.18, 1.0)
	elif current_energy / maxf(max_energy, 1.0) <= 0.25:
		fill = Color(1.0, 0.68, 0.18, 1.0)

	_fill_rect(image, METER_RECT, background)
	_draw_rect_outline(image, METER_RECT, border, 2)

	if active and max_energy > 0.0 and current_energy > 0.0:
		var inner := Rect2i(METER_RECT.position + Vector2i(4, 4), METER_RECT.size - Vector2i(8, 8))
		inner.size.x = int(round(inner.size.x * clampf(current_energy / max_energy, 0.0, 1.0)))
		_fill_rect(image, inner, fill)


func _draw_projectile_column(image: Image, sprite_path: String, x: int, start_y: int, count: int, scale: float) -> void:
	var sprite_image := Image.load_from_file(ProjectSettings.globalize_path(sprite_path))
	for index in range(count):
		var y := start_y - index * 86
		_draw_sprite(image, sprite_image, Vector2i(x, y), scale)


func _draw_player(image: Image, position: Vector2i) -> void:
	var player_image := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_SPRITE_PATH))
	_draw_sprite(image, player_image, position, 1.5)


func _draw_sprite(image: Image, sprite: Image, center: Vector2i, scale: float) -> void:
	var draw_size := Vector2i(
		int(sprite.get_width() * scale),
		int(sprite.get_height() * scale)
	)
	var top_left := center - draw_size / 2

	for y in range(draw_size.y):
		for x in range(draw_size.x):
			var source_x := int(floor(x / scale))
			var source_y := int(floor(y / scale))
			var color := sprite.get_pixel(source_x, source_y)
			if color.a > 0.0:
				_blend_pixel(image, top_left.x + x, top_left.y + y, color)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, width: int) -> void:
	for offset in range(width):
		var top_left := rect.position + Vector2i(offset, offset)
		var bottom_right := rect.position + rect.size - Vector2i(1 + offset, 1 + offset)
		_draw_line(image, top_left, Vector2i(bottom_right.x, top_left.y), color)
		_draw_line(image, Vector2i(bottom_right.x, top_left.y), bottom_right, color)
		_draw_line(image, bottom_right, Vector2i(top_left.x, bottom_right.y), color)
		_draw_line(image, Vector2i(top_left.x, bottom_right.y), top_left, color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_blend_pixel(image, x, y, color)


func _draw_line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var x0 := start.x
	var y0 := start.y
	var x1 := end.x
	var y1 := end.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var error := dx + dy

	while true:
		_blend_pixel(image, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var error2 := 2 * error
		if error2 >= dy:
			error += dy
			x0 += sx
		if error2 <= dx:
			error += dx
			y0 += sy


func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
		return

	var under := image.get_pixel(x, y)
	var alpha := color.a
	var out_alpha := alpha + under.a * (1.0 - alpha)
	if out_alpha <= 0.0:
		image.set_pixel(x, y, Color(0, 0, 0, 0))
		return

	image.set_pixel(x, y, Color(
		(color.r * alpha + under.r * under.a * (1.0 - alpha)) / out_alpha,
		(color.g * alpha + under.g * under.a * (1.0 - alpha)) / out_alpha,
		(color.b * alpha + under.b * under.a * (1.0 - alpha)) / out_alpha,
		out_alpha
	))


func _save(image: Image, file_name: String) -> void:
	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [output_path, error])
		quit(1)
