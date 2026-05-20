extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const PLAYER_SPRITE := preload("res://assets/sprites/player/player-ship.png")
const OUTPUT_PATH := "res://tests/evidence/T002-player-ship-horizontal-movement/player-bounds.png"
const WIDTH := 540
const HEIGHT := 960
const ROWS := [
	{"target_x": -999.0, "y": 230.0},
	{"target_x": 270.0, "y": 480.0},
	{"target_x": 999.0, "y": 730.0},
]


func _init() -> void:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.025, 0.04))

	_draw_rect_outline(image, Rect2i(0, 0, WIDTH, HEIGHT), Color(0.14, 0.55, 0.72))

	for row in ROWS:
		var player := PLAYER_SCENE.instantiate()
		player.fixed_y = row["y"]
		player.position = Vector2(row["target_x"], row["y"])
		player.clamp_to_playfield()
		_draw_row_guides(image, player)
		_draw_player(image, player)
		player.free()

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save player bounds evidence: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_row_guides(image: Image, player: Node2D) -> void:
	var left := int(player.left_bound_x())
	var right := int(player.right_bound_x())
	var y := int(player.position.y)

	_draw_line(image, Vector2i(left, y + 46), Vector2i(right, y + 46), Color(0.16, 0.3, 0.38))
	_draw_line(image, Vector2i(left, y - 46), Vector2i(left, y + 52), Color(0.9, 0.25, 0.2))
	_draw_line(image, Vector2i(right, y - 46), Vector2i(right, y + 52), Color(0.9, 0.25, 0.2))


func _draw_player(image: Image, player: Node2D) -> void:
	var sprite_image := PLAYER_SPRITE.get_image()
	var sprite_scale := 1.5
	var draw_size := Vector2i(
		int(sprite_image.get_width() * sprite_scale),
		int(sprite_image.get_height() * sprite_scale)
	)
	var top_left := Vector2i(player.position.round()) - draw_size / 2

	for y in range(draw_size.y):
		for x in range(draw_size.x):
			var source_x := int(floor(x / sprite_scale))
			var source_y := int(floor(y / sprite_scale))
			var color := sprite_image.get_pixel(source_x, source_y)
			if color.a > 0.0:
				_blend_pixel(image, top_left.x + x, top_left.y + y, color)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	_draw_line(image, Vector2i(rect.end.x - 1, rect.position.y), rect.end - Vector2i.ONE, color)
	_draw_line(image, rect.end - Vector2i.ONE, Vector2i(rect.position.x, rect.end.y - 1), color)
	_draw_line(image, Vector2i(rect.position.x, rect.end.y - 1), rect.position, color)


func _draw_polyline(image: Image, points: PackedVector2Array, color: Color) -> void:
	for index in points.size():
		var next_index := (index + 1) % points.size()
		_draw_line(image, Vector2i(points[index].round()), Vector2i(points[next_index].round()), color)


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
