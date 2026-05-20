extends Node

const BOOT_MESSAGE := "LAST_HORIZON_BOOT_SMOKE_OK"
const EVIDENCE_CAPTURE_SETTING := "last_horizon/evidence_capture"

@onready var _defense_grid: DefenseGrid = %DefenseGrid
@onready var _run_end_overlay: RunEndOverlay = %RunEndOverlay


func _ready() -> void:
	_defense_grid.grid_failed.connect(_on_grid_failed)
	print(BOOT_MESSAGE)
	if DisplayServer.get_name() == "headless" and !ProjectSettings.get_setting(EVIDENCE_CAPTURE_SETTING, false):
		get_tree().quit(0)


func _on_grid_failed() -> void:
	_run_end_overlay.show_failed()
	get_tree().paused = true
