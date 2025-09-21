extends Area2D

var bullet_path = preload("res://Player/bullet2.tscn")
var can_fire = true
var fire_rate = 0.25  # Time in seconds between shots (2 shots per second)
var cooldown_timer: Timer

func _ready():
	# Create timer programmatically
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = fire_rate
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	add_child(cooldown_timer)

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("shoot") and can_fire:
		fire()
		
func fire():
	# Create bullet and set its properties
	var bullet = bullet_path.instantiate()
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	bullet.global_position = $Node2D.global_position
	bullet.rotation = rotation
	get_parent().add_child(bullet)
	
	# Start cooldown timer
	can_fire = false
	cooldown_timer.start()

func _on_cooldown_timer_timeout():
	can_fire = true
