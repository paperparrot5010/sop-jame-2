extends TextureProgressBar

var player_node: Node

func _ready():
	# Find the actual player instance in the scene using the correct group name
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	
	if player_node:
		# Connect to the health_changed signal
		player_node.health_changed.connect(update_health)
		
		# Set up the progress bar
		max_value = player_node.health  # Set max value to starting health
		value = player_node.health      # Set current value
		print("Health bar connected to player successfully!")
	else:
		print("Player node not found in PlayerGroup!")

func update_health(new_health: int):
	value = new_health
	print("Health bar updated to: ", new_health)
