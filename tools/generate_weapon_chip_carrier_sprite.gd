extends SceneTree

const OUTPUT_PATH := "res://assets/sprites/enemies/weapon-chip-carrier.png"
const WIDTH := 64
const HEIGHT := 48
const TRANSPARENT := Color(0, 0, 0, 0)
const EDGE := Color8(255, 238, 166, 255)
const HULL := Color8(230, 92, 46, 255)
const HULL_DARK := Color8(111, 39, 52, 255)
const CARGO := Color8(255, 202, 64, 255)
const CARGO_DARK := Color8(174, 93, 35, 255)
const CORE := Color8(84, 245, 255, 255)
const CORE_DARK := Color8(26, 118, 155, 255)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/enemies"))

	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	_draw_soft_glow(image)
	_fill_polygon(image, PackedVector2Array([
		Vector2(7, 25), Vector2(18, 12), Vector2(47, 12), Vector2(58, 25),
		Vector2(47, 37), Vector2(18, 37),
	]), HULL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(10, 25), Vector2(20, 15), Vector2(45, 15), Vector2(54, 25),
		Vector2(45, 34), Vector2(20, 34),
	]), HULL)
	_fill_rect(image, Rect2i(24, 8, 17, 10), CARGO_DARK)
	_fill_rect(image, Rect2i(26, 7, 13, 10), CARGO)
	_fill_rect(image, Rect2i(29, 9, 7, 6), Color8(255, 246, 182, 255))
	_fill_rect(image, Rect2i(23, 22, 20, 7), CORE_DARK)
	_fill_rect(image, Rect2i(25, 23, 16, 5), CORE)
	_fill_polygon(image, PackedVector2Array([
		Vector2(8, 21), Vector2(0, 16), Vector2(3, 29), Vector2(8, 29),
	]), HULL_DARK)
	_fill_polygon(image, PackedVector2Array([
		Vector2(56, 21), Vector2(63, 16), Vector2(61, 29), Vector2(56, 29),
	]), HULL_DARK)
	_draw_polyline(image, PackedVector2Array([
		Vector2(7, 25), Vector2(18, 12), Vector2(47, 12), Vector2(58, 25),
		Vector2(47, 37), Vector2(18, 37), Vector2(7, 25),
	]), EDGE)
	_draw_line(image, Vector2i(13, 25), Vector2i(21, 17), Color8(255, 160, 92, 255))
	_draw_line(image, Vector2i(51, 25), Vector2i(43, 17), Color8(255, 160, 92, 255))
	_draw_line(image, Vector2i(27, 37), Vector2i(22, 44), Color8(255, 119, 50, 255))
	_draw_line(image, Vector2i(37, 37), Vector2i(42, 44), Color8(255, 119, 50, 255))

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save weapon-chip carrier sprite: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_soft_glow(image: Image) -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var distance := Vector2(x, y).distance_to(Vector2(32, 24))
			if distance < 30.0:
				var alpha := int(clampf((1.0 - distance / 30.0) * 62.0, 0.0, 62.0))
				image.set_pixel(x, y, Color8(217, 89, 39, alpha))


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
