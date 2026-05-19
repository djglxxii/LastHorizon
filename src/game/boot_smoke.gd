extends Node

const BOOT_MESSAGE := "LAST_HORIZON_BOOT_SMOKE_OK"


func _ready() -> void:
	print(BOOT_MESSAGE)
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
