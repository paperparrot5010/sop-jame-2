extends CharacterBody2D
@export var crystal_scene: PackedScene
var pos:Vector2
var rota:float
var dir:float
var speed = 2000

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	
func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())
	velocity = Vector2(speed,0).rotated(dir)
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("EnemyGroup"):
		# Call the take_damage function on the enemy
		if body.has_method("take_damage"):
			body.take_damage(1) # Assuming 1 damage per bullet
		queue_free() # Destroy the bullet after hitting an enemy
		
	elif body.is_in_group("MachineGroup") :
		queue_free()
