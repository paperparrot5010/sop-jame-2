extends Area2D
@onready var shine_animation_player: AnimationPlayer = $Shine_AnimationPlayer
@onready var float_animation_player: AnimationPlayer = $Float_AnimationPlayer
signal crystal_collected  # You can keep this if you need it locally

func _process(_delta: float) -> void:
	shine_animation_player.play("ShineAnimation")
	float_animation_player.play("FloatAnimation")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		# Emit both signals (optional - you can choose one)
		crystal_collected.emit()  # Local signal
		GlobalSignals.crystal_collected.emit()  # Global signal
		queue_free()
