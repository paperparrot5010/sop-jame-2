extends Node2D
@onready var wait_timer: Timer = $WaitTimer
@onready var x_mark: Sprite2D = $XMark


func _ready() -> void:
	wait_timer.start()
	await wait_timer.timeout
	x_mark.hide()
