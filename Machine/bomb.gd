extends Node2D
@onready var wait_timer: Timer = $WaitTimer
@onready var x_mark: Sprite2D = $XMark
@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var timer: Timer = $Timer
var damage_amount = 15
var player_node: Node2D = null

func _ready() -> void:
	animated_sprite_2d.hide()
	area_2d.monitoring = false
	wait_timer.start()
	await wait_timer.timeout
	timer.start()
	x_mark.hide()
	area_2d.monitoring = true
	animated_sprite_2d.show()
	animated_sprite_2d.play("Explosion")
	
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node == null:
		print("Enemy AI: Error: Player node not found in \"PlayerGroup\".")
		return
	else:
		print("Enemy AI: Player node found: ", player_node.name)



func _on_timer_timeout() -> void:
	animated_sprite_2d.hide()
	area_2d.monitoring = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		player_node.player_takes_damage(damage_amount)
