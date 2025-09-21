extends CharacterBody2D

var bullet_path = preload("res://Player/bullet2.tscn")

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("shoot"):
		fire()
		
func fire():
	var bullet = bullet_path.instantiate()
	# Pass the rotation direction to the bullet
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	bullet.global_position = $Node2D.global_position
	bullet.rotation = rotation
	get_parent().add_child(bullet)
