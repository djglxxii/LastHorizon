extends SceneTree

const OUTPUT_DIR := "res://tests/evidence/T004-typed-weapon-slot-and-energy-meter"
const PLAYER_SPRITE_PATH := "res://assets/sprites/player/player-ship.png"
const PEA_SPRITE_PATH := "res://assets/sprites/projectiles/pea-bullet.png"
const TYPED_SPRITE_PATH := "res://assets/sprites/projectiles/typed-plasma-bolt.png"
const WIDTH := 540
const HEIGHT := 960


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	_render_dual_stream()
	_render_expiry_frame("expiry-sequence-01-equipped.png", 7, 7)
	_render_expiry_frame("expiry-sequence-02-draining.png", 10, 3)
	_render_expiry_frame("expiry-sequence-03-expired.png", 12, 0)

	print("Saved T004 typed weapon visual evidence.")
	quit(0)


func _render_dual_stream() -> void:
	var image := _new_playfield_image()
	_draw_projectile_column(image, PEA_SPRITE_PATH, 260, 804, 7, 2.0)
	_draw_projectile_column(image, TYPED_SPRITE_PATH, 282, 792, 6, 2.0)
	_draw_player(image, Vector2i(270, 850))
	_save(image, "dual-stream.png")


func _render_expiry_frame(file_name: String, pea_count: int, typed_count: int) -> void:
	var image := _new_playfield_image()
	_draw_projectile_column(image, PEA_SPRITE_PATH, 260, 804, pea_count, 2.0)
	if typed_count > 0:
		_draw_projectile_column(image, TYPED_SPRITE_PATH, 282, 792, typed_count, 2.0)
	_draw_player(image, Vector2i(270, 850))
	_save(image, file_name)


func _new_playfield_image() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.025, 0.04))
	_draw_playfield_frame(image)
	return image


func _draw_playfield_frame(image: Image) -> void:
	_draw_line(image, Vector2i(0, 0), Vector2i(WIDTH - 1, 0), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, 0), Vector2i(WIDTH - 1, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(WIDTH - 1, HEIGHT - 1), Vector2i(0, HEIGHT - 1), Color(0.14, 0.55, 0.72))
	_draw_line(image, Vector2i(0, HEIGHT - 1), Vector2i(0, 0), Color(0.14, 0.55, 0.72))


func _draw_projectile_column(image: Image, sprite_path: String, x: int, start_y: int, count: int, scale: float) -> void:
	var sprite_image := Image.load_from_file(ProjectSettings.globalize_path(sprite_path))
	for index in range(count):
		var y := start_y - index * 86
		_draw_sprite(image, sprite_image, Vector2i(x, y), scale)


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


func _save(image: Image, file_name: String) -> void:
	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [output_path, error])
		quit(1)
