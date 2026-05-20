extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/player/player-ship.png"
const SIZE := 64
const TRANSPARENT := Color(0, 0, 0, 0)
const EDGE := Color8(216, 248, 255, 255)
const HULL := Color8(28, 220, 255, 255)
const HULL_DARK := Color8(16, 95, 143, 255)
const CANOPY := Color8(246, 255, 255, 255)
const CANOPY_SHADOW := Color8(118, 208, 232, 255)
const ACCENT := Color8(255, 76, 47, 255)
const ACCENT_DARK := Color8(138, 33, 42, 255)
const GLOW := Color8(32, 113, 149, 120)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/player"))

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_polygon(image, PackedVector2Array([
		Vector2(32, 5), Vector2(47, 50), Vector2(37, 45), Vector2(32, 57),
		Vector2(27, 45), Vector2(17, 50),
	]), HULL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(32, 7), Vector2(44, 48), Vector2(35, 42), Vector2(32, 52),
		Vector2(29, 42), Vector2(20, 48),
	]), HULL)
	_fill_polygon(image, PackedVector2Array([
		Vector2(32, 12), Vector2(38, 35), Vector2(32, 31), Vector2(26, 35),
	]), CANOPY_SHADOW)
	_fill_polygon(image, PackedVector2Array([
		Vector2(32, 14), Vector2(36, 31), Vector2(32, 28), Vector2(28, 31),
	]), CANOPY)
	_fill_polygon(image, PackedVector2Array([
		Vector2(21, 48), Vector2(29, 44), Vector2(25, 58), Vector2(14, 56),
	]), ACCENT_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(43, 48), Vector2(50, 56), Vector2(39, 58), Vector2(35, 44),
	]), ACCENT_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(23, 49), Vector2(28, 47), Vector2(25, 55), Vector2(17, 54),
	]), ACCENT)
	_fill_polygon(image, PackedVector2Array([
		Vector2(41, 49), Vector2(47, 54), Vector2(39, 55), Vector2(36, 47),
	]), ACCENT)
	_draw_polyline(image, PackedVector2Array([
		Vector2(32, 5), Vector2(47, 50), Vector2(37, 45), Vector2(32, 57),
		Vector2(27, 45), Vector2(17, 50), Vector2(32, 5),
	]), EDGE)
	_draw_line(image, Vector2i(32, 9), Vector2i(32, 50), Color8(154, 242, 255, 255))
	_draw_line(image, Vector2i(25, 48), Vector2i(29, 42), Color8(126, 238, 255, 255))
	_draw_line(image, Vector2i(39, 48), Vector2i(35, 42), Color8(126, 238, 255, 255))

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save player sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(Vector2(32, 34))
			if distance < 29.0:
				var alpha := int(clampf((1.0 - distance / 29.0) * 70.0, 0.0, 70.0))
				image.set_pixel(x, y, Color8(21, 151, 194, alpha))


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
