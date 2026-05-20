extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/projectiles/typed-plasma-bolt.png"
const SIZE := 20
const TRANSPARENT := Color(0, 0, 0, 0)
const CORE := Color8(255, 246, 210, 255)
const HOT := Color8(255, 116, 64, 255)
const MAGENTA := Color8(215, 64, 255, 255)
const VIOLET := Color8(96, 62, 220, 230)
const GLOW := Color8(255, 74, 196, 90)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/projectiles"))

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_rect(image, Rect2i(8, 1, 4, 15), VIOLET)
	_fill_rect(image, Rect2i(7, 3, 6, 11), MAGENTA)
	_fill_rect(image, Rect2i(8, 4, 4, 8), HOT)
	_fill_rect(image, Rect2i(9, 3, 2, 7), CORE)
	_blend_pixel(image, 9, 0, CORE)
	_blend_pixel(image, 10, 0, CORE)
	_blend_pixel(image, 6, 8, HOT)
	_blend_pixel(image, 13, 8, HOT)
	_blend_pixel(image, 7, 16, VIOLET)
	_blend_pixel(image, 12, 16, VIOLET)

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save typed projectile sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(Vector2(9.5, 7.5))
			if distance < 8.5:
				var alpha := int(clampf((1.0 - distance / 8.5) * 86.0, 0.0, 86.0))
				_blend_pixel(image, x, y, Color(GLOW.r, GLOW.g, GLOW.b, alpha / 255.0))


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
