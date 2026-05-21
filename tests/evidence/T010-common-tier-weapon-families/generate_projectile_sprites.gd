extends SceneTree

const OUTPUTS := {
	"res://assets/sprites/projectiles/wide-spread-shard.png": "wide",
	"res://assets/sprites/projectiles/piercing-lance-bolt.png": "lance",
	"res://assets/sprites/projectiles/heavy-slug-orb.png": "slug",
	"res://assets/sprites/projectiles/rapid-stream-dart.png": "dart",
}

const O := Color(0.05, 0.07, 0.11, 1.0)
const A := Color(0.72, 0.86, 1.0, 1.0)
const B := Color(1.0, 1.0, 1.0, 1.0)
const C := Color(0.55, 0.67, 0.82, 1.0)
const T := Color(0.0, 0.0, 0.0, 0.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in OUTPUTS:
		var image := Image.create_empty(20, 20, false, Image.FORMAT_RGBA8)
		image.fill(T)
		match String(OUTPUTS[path]):
			"wide":
				_draw_wide(image)
			"lance":
				_draw_lance(image)
			"slug":
				_draw_slug(image)
			"dart":
				_draw_dart(image)
		var error := image.save_png(path)
		if error != OK:
			push_error("Failed to save %s: %s" % [path, error])
			quit(1)
			return

	print("PROJECTILE_SPRITES_GENERATED")
	quit(0)


func _draw_wide(image: Image) -> void:
	_draw_points(image, [
		Vector2i(9, 2), Vector2i(10, 2),
		Vector2i(7, 3), Vector2i(8, 3), Vector2i(11, 3), Vector2i(12, 3),
		Vector2i(5, 4), Vector2i(6, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(13, 4), Vector2i(14, 4),
		Vector2i(4, 5), Vector2i(5, 5), Vector2i(9, 5), Vector2i(10, 5), Vector2i(14, 5), Vector2i(15, 5),
		Vector2i(6, 6), Vector2i(7, 6), Vector2i(12, 6), Vector2i(13, 6),
	], O)
	_draw_points(image, [
		Vector2i(9, 3), Vector2i(10, 3),
		Vector2i(6, 4), Vector2i(10, 4), Vector2i(13, 4),
		Vector2i(5, 5), Vector2i(10, 5), Vector2i(14, 5),
	], B)
	_draw_points(image, [
		Vector2i(6, 5), Vector2i(9, 4), Vector2i(13, 5),
	], A)


func _draw_lance(image: Image) -> void:
	_draw_rect(image, Rect2i(8, 2, 4, 15), O)
	_draw_rect(image, Rect2i(9, 1, 2, 17), O)
	_draw_rect(image, Rect2i(9, 3, 2, 12), B)
	_draw_rect(image, Rect2i(10, 4, 1, 10), A)
	image.set_pixel(9, 1, B)
	image.set_pixel(10, 1, B)
	image.set_pixel(9, 16, C)
	image.set_pixel(10, 16, C)


func _draw_slug(image: Image) -> void:
	for y in range(4, 17):
		for x in range(4, 17):
			var offset := Vector2(x - 10, y - 10)
			var distance := offset.length()
			if distance <= 6.5:
				image.set_pixel(x, y, O)
			if distance <= 5.0:
				image.set_pixel(x, y, A)
			if distance <= 3.2:
				image.set_pixel(x, y, B)
	_draw_points(image, [Vector2i(7, 6), Vector2i(8, 5), Vector2i(9, 5)], B)
	_draw_points(image, [Vector2i(13, 14), Vector2i(14, 13)], C)


func _draw_dart(image: Image) -> void:
	_draw_points(image, [
		Vector2i(9, 2), Vector2i(10, 2),
		Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3),
		Vector2i(9, 4), Vector2i(10, 4),
		Vector2i(9, 5), Vector2i(10, 5),
		Vector2i(8, 6), Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6),
		Vector2i(9, 7), Vector2i(10, 7),
		Vector2i(9, 8), Vector2i(10, 8),
		Vector2i(9, 9), Vector2i(10, 9),
		Vector2i(8, 10), Vector2i(11, 10),
	], O)
	_draw_rect(image, Rect2i(9, 3, 2, 6), B)
	_draw_points(image, [Vector2i(9, 2), Vector2i(10, 2), Vector2i(9, 6), Vector2i(10, 6)], A)


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_points(image: Image, points: Array, color: Color) -> void:
	for point in points:
		image.set_pixel(point.x, point.y, color)
