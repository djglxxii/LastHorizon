extends SceneTree

const OUTPUT_PATH := "res://tests/evidence/T003-auto-fire-pea-shooter/bullet-stream.png"
const PLAYER_SPRITE_PATH := "res://assets/sprites/player/player-ship.png"
const BULLET_SPRITE_PATH := "res://assets/sprites/projectiles/pea-bullet.png"
const WIDTH := 540
const HEIGHT := 960


func _init() -> void:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.025, 0.04))

	_draw_playfield_frame(image)
	_draw_bullet_column(image, 150, 820)
	_draw_bullet_column(image, 270, 780)
	_draw_bullet_column(image, 390, 830)
	_draw_player(image, Vector2i(150, 850))
	_draw_player(image, Vector2i(270, 850))
	_draw_player(image, Vector2i(390, 850))

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save bullet stream evidence: %s" % error)
		quit(1)
		return

	print("Saved %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _draw_playfield_frame(image: Image) -> void:
	_draw_line(image, Vector2i(0, 0), Vector2i(WIDTH - 1, 0), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, 0), Vector2i(WIDTH - 1, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, HEIGHT - 1), Vector2i(0, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(0, HEIGHT - 1), Vector2i(0, 0), Color(0.14, 0.55, 0.72))


func _draw_bullet_column(image: Image, x: int, start_y: int) -> void:
	var bullet_image := Image.load_from_file(ProjectSettings.globalize_path(BULLET_SPRITE_PATH))
	for index in range(7):
		var y := start_y - index * 92
		_draw_sprite(image, bullet_image, Vector2i(x, y), 2.0)


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
