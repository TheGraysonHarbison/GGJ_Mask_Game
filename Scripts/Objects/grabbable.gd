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
	
@onready var original_position: Vector2 = global_position
func set_default_state():
	original_position = global_position
func load_default_state():
	print("loading default state")
	grab()
	global_transform.origin = original_position
	ungrab()

## Enables collisions long enough to check for them and then returns collisions to the prior state
## will false if there is anything overlapping while collisions are enabled and true otherwise.
func test_overlapping() -> bool:
	var hold_col = collision_layer
	
	print("hold_col = %d" % collision_layer)
	
	collision_layer = normal_collision
	print("new_col = %d" % collision_layer)
	
	var colliding = get_colliding_bodies()
	
	collision_layer = hold_col
	return colliding.size() > 0


func _on_body_entered(body: Node) -> void:
	pass # Replace with function body.
