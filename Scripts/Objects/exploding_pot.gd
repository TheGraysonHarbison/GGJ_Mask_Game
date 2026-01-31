class_name ExplodingPot extends Grabbable
var armed = false

var explosion_scene = preload("res://Entities/AttackObjects/Explosion.tscn")

func ungrab():
	freeze = false
	collision_layer = normal_collision
	
func throw(impulse: Vector2):
	ungrab()
	apply_impulse(impulse, Vector2(0, 0))
	armed = true

func _on_body_entered(body: Node) -> void:
	if (armed):
		print("explode!")
		explode()

func explode():
	print("Explosion scene loaded: ", explosion_scene)
	
	# Create an instance of the explosion
	var explosion = explosion_scene.instantiate()
	print("Explosion instantiated: ", explosion)
	
	# Position the explosion at this object's location
	explosion.global_position = global_position - Vector2(0, 8)
	print("Explosion positioned at: ", explosion.global_position )
	
	# Add the explosion to the scene tree
	get_parent().add_child(explosion)
	print("Explosion added to parent")
	
	# Remove this object from the scene
	queue_free()
	print("queue_free() called on self")
