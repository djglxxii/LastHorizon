extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/projectiles/pea-bullet.png"
const SIZE := 16
const TRANSPARENT := Color(0, 0, 0, 0)
const CORE := Color8(220, 255, 246, 255)
const CYAN := Color8(72, 255, 218, 255)
const GREEN := Color8(78, 240, 124, 255)
const BLUE_SHADOW := Color8(28, 122, 160, 220)
const GLOW := Color8(54, 230, 210, 96)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/projectiles"))

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_rect(image, Rect2i(6, 2, 4, 10), BLUE_SHADOW)
	_fill_rect(image, Rect2i(7, 1, 2, 12), GREEN)
	_fill_rect(image, Rect2i(6, 4, 4, 6), CYAN)
	_fill_rect(image, Rect2i(7, 3, 2, 5), CORE)
	_blend_pixel(image, 7, 0, CORE)
	_blend_pixel(image, 8, 0, CORE)
	_blend_pixel(image, 6, 12, BLUE_SHADOW)
	_blend_pixel(image, 9, 12, BLUE_SHADOW)

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save pea bullet sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(Vector2(7.5, 6.5))
			if distance < 7.0:
				var alpha := int(clampf((1.0 - distance / 7.0) * 80.0, 0.0, 80.0))
				_blend_pixel(image, x, y, Color8(42, 242, 205, alpha))


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
