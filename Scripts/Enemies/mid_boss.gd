extends CharacterBody2D


const SPEED = 120
const JUMP_VELOCITY = -240.0
const GRAVITY := Vector2(0, 480.0)

var target: Node2D = null

var activated = false

@export var input_vector := Vector2(0, 0)

func _ready() -> void:
	#activate() # Remove on final -- should be triggered by an area body entered signal
	pass

func activate() -> void:
	if not activated:
		$BossController.play(&"active")
		activated = true

func do_jump():
	if !is_on_floor():
		return
	velocity.y = JUMP_VELOCITY
	$JUMP.play()
	
func kill():
	$BossController.play(&"dead")
	$boss_box.position.x -= 7000 # He'll fall if his collider is way to the left of the playfield
	$DIE.play()
	# Need to spawn a mask -- mask needs to fall in case it was too high.

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := input_vector.x
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_hurt_box_area_entered(area: Area2D) -> void:
	#Ignore my own hurtbox!
	if area == $PlayerKillBox:
		return
	
	kill()
