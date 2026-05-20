extends Node2D

@export var lifetime := 0.4
@export var drift := Vector2(0.0, -12.0)

@onready var _label := $Label as Label


func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + drift, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)


func set_damage(amount: float) -> void:
	if _label == null:
		await ready

	_label.text = str(roundi(amount))
