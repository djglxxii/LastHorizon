extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/enemies/elite-heavy.png"
const SIZE := 60
const TRANSPARENT := Color(0, 0, 0, 0)
const EDGE := Color8(217, 255, 154, 255)
const SHELL := Color8(60, 232, 120, 255)
const SHELL_DARK := Color8(21, 116, 76, 255)
const CORE := Color8(238, 70, 255, 255)
const CORE_DARK := Color8(112, 32, 144, 255)
const EYE := Color8(255, 253, 208, 255)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/enemies"))

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_polygon(image, PackedVector2Array([
		Vector2(30, 4), Vector2(48, 11), Vector2(57, 28), Vector2(51, 45),
		Vector2(40, 39), Vector2(35, 55), Vector2(30, 47), Vector2(25, 55),
		Vector2(20, 39), Vector2(9, 45), Vector2(3, 28), Vector2(12, 11),
	]), SHELL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(30, 7), Vector2(45, 14), Vector2(52, 28), Vector2(47, 41),
		Vector2(37, 35), Vector2(33, 50), Vector2(30, 42), Vector2(27, 50),
		Vector2(23, 35), Vector2(13, 41), Vector2(8, 28), Vector2(15, 14),
	]), SHELL)
	_fill_polygon(image, PackedVector2Array([
		Vector2(16, 24), Vector2(30, 14), Vector2(44, 24), Vector2(41, 36),
		Vector2(30, 43), Vector2(19, 36),
	]), CORE_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(19, 24), Vector2(30, 18), Vector2(41, 24), Vector2(38, 34),
		Vector2(30, 39), Vector2(22, 34),
	]), CORE)
	_fill_rect(image, Rect2i(24, 27, 12, 5), EYE)
	_fill_rect(image, Rect2i(27, 28, 6, 3), Color8(35, 20, 52, 255))
	_fill_rect(image, Rect2i(13, 25, 6, 8), Color8(170, 255, 169, 255))
	_fill_rect(image, Rect2i(41, 25, 6, 8), Color8(170, 255, 169, 255))
	_draw_polyline(image, PackedVector2Array([
		Vector2(30, 4), Vector2(48, 11), Vector2(57, 28), Vector2(51, 45),
		Vector2(40, 39), Vector2(35, 55), Vector2(30, 47), Vector2(25, 55),
		Vector2(20, 39), Vector2(9, 45), Vector2(3, 28), Vector2(12, 11),
		Vector2(30, 4),
	]), EDGE)
	_draw_line(image, Vector2i(13, 13), Vector2i(25, 27), Color8(170, 255, 169, 255))
	_draw_line(image, Vector2i(47, 13), Vector2i(35, 27), Color8(170, 255, 169, 255))
	_draw_line(image, Vector2i(16, 42), Vector2i(6, 57), Color8(35, 194, 100, 255))
	_draw_line(image, Vector2i(44, 42), Vector2i(54, 57), Color8(35, 194, 100, 255))

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save elite enemy sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(Vector2(30, 30))
			if distance < 29.0:
				var alpha := int(clampf((1.0 - distance / 29.0) * 62.0, 0.0, 62.0))
				image.set_pixel(x, y, Color8(35, 185, 92, alpha))


func _draw_polyline(image: Image, points: PackedVector2Array, color: Color) -> void:
	for index in points.size() - 1:
		_draw_line(image, Vector2i(points[index].round()), Vector2i(points[index + 1].round()), color)


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


func _fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var min_x := SIZE - 1
	var min_y := SIZE - 1
	var max_x := 0
	var max_y := 0

	for point in points:
		min_x = mini(min_x, floori(point.x))
		min_y = mini(min_y, floori(point.y))
		max_x = maxi(max_x, ceili(point.x))
		max_y = maxi(max_y, ceili(point.y))

	for y in range(maxi(min_y, 0), mini(max_y + 1, SIZE)):
		for x in range(maxi(min_x, 0), mini(max_x + 1, SIZE)):
			if _point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_blend_pixel(image, x, y, color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_blend_pixel(image, x, y, color)


func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var previous := polygon.size() - 1

	for current in polygon.size():
		var current_point := polygon[current]
		var previous_point := polygon[previous]
		var crosses_y := (current_point.y > point.y) != (previous_point.y > point.y)
		if crosses_y:
			var intersect_x := (previous_point.x - current_point.x) * (point.y - current_point.y) / (previous_point.y - current_point.y) + current_point.x
			if point.x < intersect_x:
				inside = !inside
		previous = current

	return inside


func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
		return

	var under := image.get_pixel(x, y)
	var alpha := color.a
	var out_alpha := alpha + under.a * (1.0 - alpha)
	if out_alpha <= 0.0:
		image.set_pixel(x, y, TRANSPARENT)
		return

	var out_color := Color(
		(color.r * alpha + under.r * under.a * (1.0 - alpha)) / out_alpha,
		(color.g * alpha + under.g * under.a * (1.0 - alpha)) / out_alpha,
		(color.b * alpha + under.b * under.a * (1.0 - alpha)) / out_alpha,
		out_alpha
	)
	image.set_pixel(x, y, out_color)
