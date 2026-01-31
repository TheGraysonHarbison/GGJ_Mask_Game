extends CharacterBody2D

# Reference to child nodes
@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var character_animator: AnimationPlayer = $CharacterAnimator
@onready var sfx: Array[Node] = $CharacterAudio.get_children()

# Character states
enum State {
	NORMAL,
	AIR,
	GIMMICK,
	PICKING_UP
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
const TERMINAL_VELOCITY: float = 8.0 * TILE_SIZE  # 128 px/s

# Calculated physics values
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

# Movement state
var is_running: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left

# Jump state
var jump_time: float = 0.0
var is_jumping: bool = false
var jump_button_released: bool = false

# Double tap detection
var last_left_tap_time: float = -1.0
var last_right_tap_time: float = -1.0

# Gimmick interaction
var active_gimmick: Node = null  # Should be ConnectableGimmick type


func _ready() -> void:
	_calculate_physics()
	
	# Start in air state to handle initial ground detection
	current_state = State.AIR


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
		State.PICKING_UP:
			_process_picking_up_state(delta)
	
	# Apply movement
	move_and_slide()


func _process_normal_state(delta: float) -> void:
	# Check for jump input
	if Input.is_action_just_pressed("ui_accept"):  # Spacebar
		_start_jump()
		_transition_to_state(State.AIR)
		return
	
	# Handle horizontal movement
	_handle_horizontal_input(delta)
	
	# Apply minimal gravity to detect if we fall off platforms
	velocity.y += fall_gravity * delta
	
	# Check if we're no longer on the ground
	if not is_on_floor():
		_transition_to_state(State.AIR)


func _process_air_state(delta: float) -> void:
	# Handle jump physics
	if is_jumping:
		jump_time += delta
		
		# Check if jump button was released early
		if Input.is_action_just_released("ui_accept"):
			jump_button_released = true
			# Cut the upward velocity to end the jump early
			if velocity.y < 0:
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


func _process_picking_up_state(delta: float) -> void:
	# Player cannot move during pickup
	# Apply gravity to stay grounded
	velocity.x = 0
	
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += fall_gravity * delta


func _handle_horizontal_input(delta: float) -> void:
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


func _start_jump() -> void:
	is_jumping = true
	jump_time = 0.0
	jump_button_released = false
	sfx[0].play()
	velocity.y = -jump_velocity


func _transition_to_state(new_state: State) -> void:
	# Exit current state
	match current_state:
		State.NORMAL:
			pass
		State.AIR:
			is_jumping = false
			jump_button_released = false
		State.GIMMICK:
			pass
		State.PICKING_UP:
			pass
	
	# Enter new state
	current_state = new_state
	
	match new_state:
		State.NORMAL:
			pass
		State.AIR:
			pass
		State.GIMMICK:
			pass
		State.PICKING_UP:
			# Reset horizontal velocity when picking up
			velocity.x = 0


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


func enter_picking_up_state() -> void:
	"""Called when the player starts picking up an object"""
	_transition_to_state(State.PICKING_UP)


func exit_picking_up_state() -> void:
	"""Called when the player finishes picking up an object"""
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
