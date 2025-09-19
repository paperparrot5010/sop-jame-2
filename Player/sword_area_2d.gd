extends Area2D
@export var damage_amount = 1
@onready var animation_player: AnimationPlayer = $AnimationPlayer
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		animation_player.play("Hit")





func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("EnemyGroup"):
		print(1)
		# Call the take_damage function on the enemy
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
