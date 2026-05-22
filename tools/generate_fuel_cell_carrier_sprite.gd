extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/carriers/fuel-cell-carrier.png"
const WIDTH := 56
const HEIGHT := 48
const TRANSPARENT := Color(0, 0, 0, 0)
const EDGE := Color8(190, 250, 255, 255)
const HULL := Color8(45, 146, 204, 255)
const HULL_DARK := Color8(20, 62, 111, 255)
const HULL_LIGHT := Color8(100, 213, 246, 255)
const CANISTER := Color8(95, 237, 255, 255)
const CANISTER_DARK := Color8(28, 122, 160, 255)
const GLOW := Color8(238, 255, 255, 255)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/carriers"))

	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_polygon(image, PackedVector2Array([
		Vector2(11, 17), Vector2(24, 8), Vector2(42, 12), Vector2(50, 22),
		Vector2(43, 32), Vector2(22, 34), Vector2(10, 27),
	]), HULL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(15, 18), Vector2(25, 11), Vector2(40, 14), Vector2(46, 22),
		Vector2(40, 29), Vector2(24, 31), Vector2(15, 26),
	]), HULL)
	_fill_polygon(image, PackedVector2Array([
		Vector2(15, 20), Vector2(4, 24), Vector2(15, 29),
	]), HULL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(44, 19), Vector2(55, 16), Vector2(49, 28),
	]), HULL_DARK)
	_fill_rect(image, Rect2i(20, 25, 20, 16), CANISTER_DARK)
	_fill_rect(image, Rect2i(23, 23, 14, 17), CANISTER)
	_fill_rect(image, Rect2i(25, 25, 10, 5), GLOW)
	_fill_rect(image, Rect2i(27, 31, 6, 6), Color8(183, 251, 255, 255))
	_draw_polyline(image, PackedVector2Array([
		Vector2(11, 17), Vector2(24, 8), Vector2(42, 12), Vector2(50, 22),
		Vector2(43, 32), Vector2(22, 34), Vector2(10, 27), Vector2(11, 17),
	]), EDGE)
	_draw_line(image, Vector2i(22, 16), Vector2i(38, 18), HULL_LIGHT)
	_draw_line(image, Vector2i(23, 41), Vector2i(36, 41), EDGE)
	_draw_line(image, Vector2i(20, 25), Vector2i(23, 23), EDGE)
	_draw_line(image, Vector2i(37, 23), Vector2i(40, 25), EDGE)
	_draw_line(image, Vector2i(7, 24), Vector2i(14, 27), Color8(76, 188, 226, 255))
	_draw_line(image, Vector2i(48, 20), Vector2i(53, 17), Color8(76, 188, 226, 255))

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save fuel-cell carrier sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var distance := Vector2(x, y).distance_to(Vector2(29, 29))
			if distance < 24.0:
				var alpha := int(clampf((1.0 - distance / 24.0) * 70.0, 0.0, 70.0))
				image.set_pixel(x, y, Color8(54, 230, 255, alpha))


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
	var min_x := WIDTH - 1
	var min_y := HEIGHT - 1
	var max_x := 0
	var max_y := 0

	for point in points:
		min_x = mini(min_x, floori(point.x))
		min_y = mini(min_y, floori(point.y))
		max_x = maxi(max_x, ceili(point.x))
		max_y = maxi(max_y, ceili(point.y))

	for y in range(maxi(min_y, 0), mini(max_y + 1, HEIGHT)):
		for x in range(maxi(min_x, 0), mini(max_x + 1, WIDTH)):
			if _point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_blend_pixel(image, x, y, color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
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
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
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
