class_name ExplodingPot extends Grabbable
var armed = false

var explosion_scene = preload("res://Entities/AttackObjects/Explosion.tscn")

func throw(impulse: Vector2):
	super(impulse)
	armed = true

func _on_body_entered(body: Node) -> void:
	if (armed):
		print("explode!")
		explode()
	
func load_default_state():
	super()
	visible = true
	armed = false
	set_process(true)
	pass

func explode():
	# Create an instance of the explosion
	var explosion = explosion_scene.instantiate()
	
	# Position the explosion at this object's location
	explosion.global_position = global_position - Vector2(0, 8)
	
	# Add the explosion to the scene tree
	get_parent().add_child(explosion)
	
	# Hide this object from the scene
	visible = false
	set_process(false)
	global_position = Vector2(-20000,-20000)
