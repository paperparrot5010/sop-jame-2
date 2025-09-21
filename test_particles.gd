extends Node

# This is a test script to verify the purple particle system works correctly
# You can run this in the Godot debugger to test the functionality

func test_particle_system():
	print("=== Testing Purple Particle System ===")
	
	# Test if particle scene exists
	var particle_path = "res://particles/purple_explosion.tscn"
	if ResourceLoader.exists(particle_path):
		print("✓ Purple explosion particle file found at: ", particle_path)
		
		# Try to load and instantiate it
		var particle_scene = load(particle_path)
		if particle_scene:
			print("✓ Particle scene loaded successfully")
			
			var particle_instance = particle_scene.instantiate()
			if particle_instance:
				print("✓ Particle instance created successfully")
				print("  Particle type: ", particle_instance.get_class())
				
				# Test if it's a valid particle system
				if particle_instance is CPUParticles2D:
					print("✓ CPUParticles2D detected")
					print("  Can emit: ", particle_instance.has_method("set_emitting"))
				elif particle_instance is GPUParticles2D:
					print("✓ GPUParticles2D detected")
					print("  Can emit: ", particle_instance.has_method("set_emitting"))
				else:
					print("? Unknown particle type - might still work")
				
				# Clean up test instance
				particle_instance.queue_free()
			else:
				print("✗ Failed to create particle instance")
		else:
			print("✗ Failed to load particle scene")
	else:
		print("✗ Purple explosion particle file NOT found at: ", particle_path)
	
	# Test enemy scripts
	print("\n=== Testing Enemy Scripts ===")
	
	# Check if enemies exist in scene
	var enemies = get_tree().get_nodes_in_group("EnemyGroup")
	if enemies.size() > 0:
		print("✓ Found ", enemies.size(), " enemies in scene")
		for enemy in enemies:
			if enemy.has_method("die"):
				print("  - Enemy ", enemy.name, " has die() method")
				if enemy.has_signal("died"):
					print("    ✓ Has died signal")
				else:
					print("    ? Missing died signal")
			else:
				print("  - Enemy ", enemy.name, " missing die() method")
	else:
		print("! No enemies found in scene (this is normal if testing outside gameplay)")
	
	print("\n=== Test Complete ===")
	print("If particles don't work, check:")
	print("1. purple_explosion.tscn exists in particles folder")
	print("2. Particle system is set to emit on start")
	print("3. Particle system has a purple material/color")
	print("4. Enemies are properly calling die() method")

func _ready():
	# Wait a moment for scene to initialize
	await get_tree().process_frame
	test_particle_system()