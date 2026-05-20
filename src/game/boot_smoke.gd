extends Node

const BOOT_MESSAGE := "LAST_HORIZON_BOOT_SMOKE_OK"
const EVIDENCE_CAPTURE_SETTING := "last_horizon/evidence_capture"


func _ready() -> void:
	print(BOOT_MESSAGE)
	if DisplayServer.get_name() == "headless" and !ProjectSettings.get_setting(EVIDENCE_CAPTURE_SETTING, false):
		get_tree().quit(0)
