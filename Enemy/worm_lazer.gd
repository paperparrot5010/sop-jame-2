extends CharacterBody2D

@export var speed: float = 300.0
@export var damage_amount: int = 2
@export var lifetime: float = 5.0  # Destroy after 5 seconds if it doesn't hit anything

var direction: Vector2 = Vector2.ZERO
var has_hit: bool = false

func _ready():
	# Auto-destroy after lifetime expires
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	# Move the laser in the direction it was fired
	velocity = direction * speed
	move_and_slide()

func initialize(start_position: Vector2, target_position: Vector2):
	# Set the laser's starting position and calculate direction
	global_position = start_position
	direction = (target_position - start_position).normalized()
	
	# Rotate the laser sprite to face the direction of travel
	rotation = direction.angle()
	
	print("Worm laser fired toward player!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup") and not has_hit:
		has_hit = true
		body.player_takes_damage(damage_amount)
		print("Worm laser hit player for ", damage_amount, " damage!")
		# Destroy the laser after hitting
		queue_free()

func _on_lifetime_expired():
	# Destroy the laser if it hasn't hit anything after the lifetime
	if not has_hit:
		print("Worm laser expired without hitting target")
		queue_free()
