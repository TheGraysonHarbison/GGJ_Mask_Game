class_name Grabbable extends RigidBody2D
@onready var normal_collision := collision_layer
@export var heavy := false
@export var throw_vector := Vector2(120, -20)


func grab() -> void:
	freeze = true
	collision_layer = 0
	pass

func ungrab() -> void:
	freeze = false
	collision_layer = normal_collision
	
func get_throw_vector() -> Vector2:
	return throw_vector

func is_heavy() -> bool:
	return heavy
	
func throw(impulse: Vector2):
	ungrab()
	apply_impulse(impulse, Vector2(0, 0))
