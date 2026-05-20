extends CanvasLayer
class_name RunEndOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_failed() -> void:
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if !visible:
		return

	if event.is_action_pressed("ui_accept") or _is_restart_key(event):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _is_restart_key(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	return key_event != null and key_event.pressed and !key_event.echo and key_event.keycode == KEY_R
