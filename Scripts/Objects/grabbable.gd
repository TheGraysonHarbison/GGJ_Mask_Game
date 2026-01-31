class_name Grabbable extends RigidBody2D
@onready var normal_collision = collision_layer

func grab():
	freeze = true
	collision_layer = 0
	pass

func ungrab():
	freeze = false
	collision_layer = normal_collision
	
	
func throw(impulse: Vector2):
	ungrab()
	apply_impulse(impulse, Vector2(0, 0))
