class_name Player extends CharacterBody2D

# Reference to child nodes
@onready var sprite: Sprite2D = $CharacterSprite
@onready var animator: AnimationPlayer = $CharacterAnimator
@onready var sfx: Array[Node] = $CharacterAudio.get_children()
@onready var colliders: Node2D = $Colliders
@onready var grabdetect: Area2D = $Colliders/GrabbableDetector
@onready var walldetect: Area2D = $Colliders/WallDetector

# Character states
enum State {
	NORMAL,
	AIR,
	GIMMICK,
	DYING,
}

var current_state: State = State.AIR

# Movement constants (all in pixels)
const TILE_SIZE: float = 16.0
const PLAYER_HEIGHT: float = 16.0

# Horizontal movement
const WALK_SPEED: float = TILE_SIZE / 0.20  # 1 tile in 0.20 seconds = 64 px/s
const RUN_SPEED: float = WALK_SPEED * 1.6  # 128 px/s
const DOUBLE_TAP_TIME: float = 0.3  # Time window for double tap detection

# Jump constants
const JUMP_DURATION: float = 0.25  # Maximum jump button hold time
const JUMP_HEIGHT: float = 24.0  # Height when holding jump for full duration
const FALL_TIME: float = 0.25  # Time to fall 32 pixels
const TERMINAL_VELOCITY: float = 24.0 * TILE_SIZE

# Calculated physics values
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

# Forces the player in a direction when doing things like wall jump so that they can't repeatedly
# jump off the same wall
var jump_direction_modifier: float = 0.0

# Movement state
var is_running: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left

# Jump state
var jump_time: float = 0.0
var is_jumping: bool = false
var is_wall_jumping: bool = false
var jump_button_released: bool = false

# Double tap detection
var last_left_tap_time: float = -1.0
var last_right_tap_time: float = -1.0

# Gimmick interaction
var active_gimmick: Node = null  # Should be ConnectableGimmick type
var grabbable_object: Grabbable = null # Should be Grabbable type
var held_object: Grabbable = null

var walls_touching := 0

# The mask unlocks the double-jump -- this should be off by default normally
@export var has_fox_mask := true
var can_double_jump := 0


var death_timer = 0

@onready var original_position = global_position
func set_default_state():
	original_position = global_position
	pass
func load_default_state():
	global_position = original_position
	current_state = State.AIR
	if held_object:
		throw_object(true)
	
	pass

## Make sure any nodes connecting themselves as the gimmick also have the following function:
##
## func process_connected_player(delta: float, player: Player) function
## func force_disconnect(player: Player)
func set_gimmick(gimmick : Node2D):
	if active_gimmick:
		active_gimmick.force_disconnect(self)

	active_gimmick = gimmick
	
	if gimmick != null:
		_transition_to_state(State.GIMMICK)

func _ready() -> void:
	_calculate_physics()
	
	# Start in air state to handle initial ground detection
	current_state = State.AIR
	$MaskNode/MaskSprite.visible = has_fox_mask


func _calculate_physics() -> void:
	# Calculate jump velocity needed to reach JUMP_HEIGHT
	# Using: height = velocity * time - 0.5 * gravity * time^2
	# Solving for initial velocity when we want to reach peak at JUMP_DURATION
	jump_gravity = (2.0 * JUMP_HEIGHT) / (JUMP_DURATION * JUMP_DURATION)
	jump_velocity = jump_gravity * JUMP_DURATION
	
	# Calculate fall gravity based on falling 32 pixels in FALL_TIME
	# Using: distance = 0.5 * gravity * time^2
	fall_gravity = (2.0 * 32.0) / (FALL_TIME * FALL_TIME)


func _physics_process(delta: float) -> void:
	match current_state:
		State.NORMAL:
			_process_normal_state(delta)
		State.AIR:
			_process_air_state(delta)
		State.GIMMICK:
			_process_gimmick_state(delta)
		State.DYING:
			_process_dying_state(delta)
	
	# Apply movement
	move_and_slide()
	
	if held_object:
		held_object.global_transform.origin = global_position - Vector2(0, 16)
	
	# Reposition specialized Sensors
	if sprite.flip_h:
		colliders.scale.x = -1
		$MaskNode.scale.x = -1
	else:
		colliders.scale.x = 1
		$MaskNode.scale.x = 1


func _process_normal_state(delta: float) -> void:
	# Check for jump input
	if Input.is_action_just_pressed("p1_jump"):  # Spacebar
		# Can only jump if either an object is unheld or the held object isn't heavy
		if held_object == null or !held_object.is_heavy():
			start_jump()
			_transition_to_state(State.AIR)
			return
	
	# Handle horizontal movement
	_handle_horizontal_input(delta)
	
	# Apply minimal gravity to detect if we fall off platforms
	velocity.y += fall_gravity * delta
	
	# Check if we're no longer on the ground
	if not is_on_floor():
		_transition_to_state(State.AIR)
	
	# Normally I'd be opposed to animation control in a physics process function, but we're on a
	# sharp deadline and it simplifies things.
	if abs(velocity.x) < 2:
		if held_object:
			animator.play(&"idle_hold")
		else:
			animator.play(&"idle")
	elif is_running:
		if held_object:
			animator.play(&"run_hold")
		else:
			animator.play(&"run")
	else:
		if held_object:
			animator.play(&"walk_hold")
		else:
			animator.play(&"walk")
	
	# While grounded we can also turn around (unlike in the air)
	if velocity.x < -0.2:
		sprite.flip_h = true
	elif velocity.x > 0.2:
		sprite.flip_h = false
	
	# While in the normal state and an object is grabbable plus no object is held, the player can
	# grab it.
	if Input.is_action_just_pressed("p1_use"):
		if grabbable_object and held_object == null:
			print("grabed object!")
			held_object = grabbable_object
			held_object.grab()
			grabbable_object = null
		elif held_object:
			throw_object()

func throw_object(unsafe: bool = false) -> void:
	if not unsafe and held_object.test_overlapping():
		print("prevented throw (proximity to wall)")
		return

	var scaler: Vector2 = Vector2(1 * colliders.scale.x, 1)
	
	if is_running:
		scaler.x = scaler.x * 1.5
	
	held_object.global_transform.origin.y -= 4
	held_object.throw(Vector2(scaler.x * held_object.get_throw_vector().x,
							scaler.y * held_object.get_throw_vector().y))
	held_object = null

func _process_air_state(delta: float) -> void:
	# Handle jump physics
	if is_jumping:
		jump_time += delta
		
		# Check if jump button was released early
		if Input.is_action_just_released("p1_jump"):
			jump_button_released = true
			# Cut the upward velocity to end the jump early
			if velocity.y < -12:
				velocity.y *= 0.5
			is_jumping = false
		
		# Check if we've reached max jump duration
		if jump_time >= JUMP_DURATION:
			is_jumping = false
			
	# Apply falling gravity
	velocity.y += fall_gravity * delta
	
	# Cap at terminal velocity
	if velocity.y > TERMINAL_VELOCITY:
		velocity.y = TERMINAL_VELOCITY
	
	# Handle horizontal movement in air
	_handle_horizontal_input(delta)
	
	# You can't pick up objects while airborn, but you can throw them.
	if Input.is_action_just_pressed("p1_use"):
		if held_object:
			throw_object()
	
	# If we are against a wall and attempt to jump again, we can wall jump.
	if Input.is_action_just_pressed("p1_jump"):
		var touching_wall := walls_touching > 0

		var wall_side: int = int(sign(colliders.scale.x))
		var move_x: int = sign(Input.get_axis("ui_left", "ui_right"))
		var holding_into_wall := touching_wall and (move_x != 0) and (move_x == wall_side)

		var double_jump_used := has_fox_mask and (not bool(can_double_jump))

		var do_wall_jump := touching_wall and (is_wall_jumping or holding_into_wall or double_jump_used)
		var do_double_jump := (not do_wall_jump) and has_fox_mask and (not double_jump_used)

		if do_wall_jump:
			start_jump()
			colliders.scale.x *= -1
			sprite.flip_h = colliders.scale.x <= 0
			jump_direction_modifier = colliders.scale.x * RUN_SPEED

			is_wall_jumping = true
			if has_fox_mask:
				can_double_jump = true

		elif do_double_jump:
			can_double_jump = false
			start_jump()
			is_wall_jumping = false
			
	
	# Check for landing
	if is_on_floor():
		# Push player out of ground if embedded
		if velocity.y > 0:
			velocity.y = 0
		
		
		
		_transition_to_state(State.NORMAL)


func _process_gimmick_state(delta: float) -> void:
	# Delegate control to the active gimmick
	if active_gimmick and active_gimmick.has_method("player_process"):
		active_gimmick.player_process(delta, self)
	else:
		# If gimmick is invalid, return to normal state
		print("Warning: Invalid gimmick in GIMMICK state")
		active_gimmick = null
		_transition_to_state(State.AIR)

func _process_dying_state(delta: float) -> void:
	velocity = Vector2(0,0)
	death_timer += delta
	
	if death_timer >= 2:
		LevelManager.get_active_level().reset_to_spawn()
		LevelManager.get_active_level().resume_music()
		if has_fox_mask:
			$MaskNode/MaskSprite.visible = true
	
	pass

func give_mask():
	has_fox_mask = true
	$MaskNode/MaskSprite.visible = true
	can_double_jump = true
	sfx[2].play()

func _process_picking_up_state(delta: float) -> void:
	# Player cannot move during pickup
	# Apply gravity to stay grounded
	velocity.x = 0
	
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += fall_gravity * delta


func _handle_horizontal_input(_delta: float) -> void:
	var input_direction: int = 0
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if Input.is_action_pressed("ui_right"):
		input_direction = 1
	elif Input.is_action_pressed("ui_left"):
		input_direction = -1
	
	# Detect double tap for running
	if Input.is_action_just_pressed("ui_right"):
		if current_time - last_right_tap_time < DOUBLE_TAP_TIME:
			is_running = true
		last_right_tap_time = current_time
	
	if Input.is_action_just_pressed("ui_left"):
		if current_time - last_left_tap_time < DOUBLE_TAP_TIME:
			is_running = true
		last_left_tap_time = current_time
	
	# Can't run while holding heavy object
	if held_object and held_object.is_heavy():
		is_running = false
	
	# Apply movement if we have input
	if input_direction != 0:
		# Update facing direction
		facing_direction = input_direction
		
		# Apply movement speed
		var move_speed = RUN_SPEED if is_running else WALK_SPEED
		velocity.x = input_direction * move_speed
	else:
		# No input - stop moving and reset run state
		velocity.x = 0
		is_running = false
		
	if jump_direction_modifier < 0:
		velocity.x = clampf(velocity.x, velocity.x, jump_direction_modifier)
	elif jump_direction_modifier > 0:
		velocity.x = clampf(velocity.x, jump_direction_modifier, velocity.x)


func start_jump() -> void:
	is_jumping = true
	jump_time = 0.0
	jump_button_released = false
	sfx[0].play()
	velocity.y = -jump_velocity
	animator.play(&"jump")


func _transition_to_state(new_state: State) -> void:
	# Exit current state
	match current_state:
		State.NORMAL:
			pass
		State.AIR:
			is_jumping = false
			is_wall_jumping = false
			jump_button_released = false
		State.GIMMICK:
			if active_gimmick:
				active_gimmick.force_disconnect(self)
			pass
		State.DYING:
			pass
	
	# Enter new state
	current_state = new_state
	
	match new_state:
		State.NORMAL:
			jump_direction_modifier = 0.0
			if has_fox_mask:
				can_double_jump = true
			pass
		State.AIR:
			pass
		State.GIMMICK:
			pass
		State.DYING:
			animator.play(&"dying")
			death_timer = 0.0
			pass


# Public methods for external state control

func enter_gimmick_state(gimmick: Node) -> void:
	"""Called by ConnectableGimmick objects to take control of the player"""
	active_gimmick = gimmick
	_transition_to_state(State.GIMMICK)


func exit_gimmick_state() -> void:
	"""Called to return control from a gimmick"""
	active_gimmick = null
	if is_on_floor():
		_transition_to_state(State.NORMAL)
	else:
		_transition_to_state(State.AIR)

# Utility getters

func get_facing_direction() -> int:
	return facing_direction


func is_grounded() -> bool:
	return is_on_floor()


func get_current_state() -> State:
	return current_state


func _on_grabbable_detector_body_entered(body: Node2D) -> void:
	if body is not Grabbable:
		return
	# Might be more appropriate to maintain an array, but we're doing this fast and loose.
	grabbable_object = body

func _on_grabbable_detector_body_exited(body: Node2D) -> void:
	if grabbable_object == body:
		grabbable_object = null


func _on_wall_detector_body_entered(body: Node2D) -> void:
	if body is not TileMapLayer:
		return
		
	walls_touching += 1
	pass # Replace with function body.


func _on_wall_detector_body_exited(body: Node2D) -> void:
	if body is not TileMapLayer:
		return
		
	walls_touching -= 1
	pass # Replace with function body.


func check_mount_ladder() -> bool:
	var should_mount = false
	if held_object:
		return false
	
	if current_state != State.NORMAL and current_state != State.AIR:
		return false
	
	if Input.is_action_pressed("ui_up"):
		should_mount = true
	elif Input.is_action_pressed("ui_down"):
		should_mount = true
		
	return should_mount

func kill_player():
	var level : Level = LevelManager.get_active_level()
	
	level.pause_music()
	_transition_to_state(State.DYING)
	pass
