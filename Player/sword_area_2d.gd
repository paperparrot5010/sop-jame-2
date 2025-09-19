extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		animation_player.play("Hit")





func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("EnemyGroup"):
		print(1)
		# Call the take_damage function on the enemy
		if body.has_method("take_damage"):
			body.take_damage(1) # Assuming 1 damage per bullet
