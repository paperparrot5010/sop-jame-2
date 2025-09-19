extends Area2D
@onready var shine_animation_player: AnimationPlayer = $Shine_AnimationPlayer
@onready var float_animation_player: AnimationPlayer = $Float_AnimationPlayer


func _process(_delta: float) -> void:
	shine_animation_player.play("ShineAnimation")
	float_animation_player.play("FloatAnimation")
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		queue_free()
	pass # Replace with function body.
