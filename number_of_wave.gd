extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
	animation_player.play("Fade_to_normal")
	await timer.timeout
	animation_player.play("Fade_to_vanish")
