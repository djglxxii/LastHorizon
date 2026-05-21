extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/pickups/weapon-chip.png"
const SIZE := 24
const TRANSPARENT := Color(0, 0, 0, 0)
const EDGE := Color8(255, 252, 180, 255)
const CHIP := Color8(255, 178, 45, 255)
const CHIP_DARK := Color8(174, 83, 35, 255)
const CORE := Color8(84, 244, 255, 255)
const GLOW := Color8(255, 185, 42, 90)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/pickups"))

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_rect(image, Rect2i(6, 5, 12, 14), CHIP_DARK)
	_fill_rect(image, Rect2i(8, 4, 8, 16), CHIP)
	_fill_rect(image, Rect2i(9, 8, 6, 5), CORE)
	_fill_rect(image, Rect2i(10, 9, 4, 3), Color8(235, 255, 255, 255))
	_draw_line(image, Vector2i(5, 7), Vector2i(2, 7), EDGE)
	_draw_line(image, Vector2i(5, 12), Vector2i(1, 12), EDGE)
	_draw_line(image, Vector2i(5, 17), Vector2i(2, 17), EDGE)
	_draw_line(image, Vector2i(18, 7), Vector2i(21, 7), EDGE)
	_draw_line(image, Vector2i(18, 12), Vector2i(22, 12), EDGE)
	_draw_line(image, Vector2i(18, 17), Vector2i(21, 17), EDGE)
	_draw_rect_outline(image, Rect2i(7, 4, 10, 16), EDGE)

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save weapon-chip sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(Vector2(12, 12))
			if distance < 11.0:
				var alpha := int(clampf((1.0 - distance / 11.0) * 92.0, 0.0, 92.0))
				_blend_pixel(image, x, y, Color(GLOW.r, GLOW.g, GLOW.b, alpha / 255.0))


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	_draw_line(image, Vector2i(rect.end.x - 1, rect.position.y), rect.end - Vector2i(1, 1), color)
	_draw_line(image, rect.end - Vector2i(1, 1), Vector2i(rect.position.x, rect.end.y - 1), color)
	_draw_line(image, Vector2i(rect.position.x, rect.end.y - 1), rect.position, color)


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


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_blend_pixel(image, x, y, color)


func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
		return

	var under := image.get_pixel(x, y)
	var alpha := color.a
	var out_alpha := alpha + under.a * (1.0 - alpha)
	if out_alpha <= 0.0:
		image.set_pixel(x, y, TRANSPARENT)
		return

	image.set_pixel(x, y, Color(
		(color.r * alpha + under.r * under.a * (1.0 - alpha)) / out_alpha,
		(color.g * alpha + under.g * under.a * (1.0 - alpha)) / out_alpha,
		(color.b * alpha + under.b * under.a * (1.0 - alpha)) / out_alpha,
		out_alpha
	))
