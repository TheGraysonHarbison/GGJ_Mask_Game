extends CharacterBody2D

# Components
@onready var animator : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Graphics
@onready var frontDetector = $Colliders/Front_Detector
@onready var colliders = $Colliders

# Speeds And Physics
const TILE_SIZE: float = 16.0
const BOSS_HEIGHT: float = 48.0

var targetRecoveryTime : float = 0
var currentRecoveryTime : float = 0

# Horizontal movement
const WALK_SPEED: float = TILE_SIZE / 0.28  # 1 tile in 0.20 seconds = 64 px/s

# States
enum BehaviorState{
	WaitingForFightToStart,
	Introduction,
	ChargePlayer,
	EvadingToCorner,
	Slashing,
	PreparingSpin,
	Spinning,
	Recovering,
	Dying
}

var currentState : BehaviorState = BehaviorState.WaitingForFightToStart
var facingRight : bool = false
var directionLock : bool = false

@export_category("Settings")
@export var player : Player
@export var wallHitRecoverTime : float = 3.0
@export var slashRecoverTime : float = 1.5

# Setup
func _ready():
	_setFacing(false)
	_swapToState(BehaviorState.WaitingForFightToStart)

# Start The Fight
func _startFight():
	print("Beginning Boss Fight!")
	_swapToState(BehaviorState.Introduction)

# Swap To A State
func _swapToState(newState : BehaviorState):
	_stateExit(currentState)
	currentState = newState
	print("Boss Changed To State {0}".format([newState]))
	_stateEnter(newState)

# Exit Solver
func _stateExit(oldState : BehaviorState):
	match oldState:
		BehaviorState.ChargePlayer:
			_onExitCharging()

# Entrance Solver
func _stateEnter(newState : BehaviorState):
	match newState:
		BehaviorState.WaitingForFightToStart:
			animator.play("boss/idle")
		BehaviorState.Introduction:
			_onEnterIntroState()
		BehaviorState.Slashing:
			_onEnterSlashingState()
		BehaviorState.Recovering:
			_onEnterRecoveringState()

# State and Physics Update
func _physics_process(delta):
	match currentState:
		BehaviorState.ChargePlayer:
			_chargePlayerBehavior(delta)
		BehaviorState.Recovering:
			_recoveringBehavior(delta)

	move_and_slide()

# Enter The Intro Cutscene
func _onEnterIntroState():
	animator.play("boss/intro")
	
# Handle Basic Attack
func _onEnterSlashingState():
	directionLock = false
	targetRecoveryTime = slashRecoverTime
	animator.play("boss/slash")
	
# Handle Basic Attack
func _onEnterRecoveringState():
	velocity.x = 0
	directionLock = false
	currentRecoveryTime = 0
	animator.play("boss/idle")

# Handle Checks For Slashing
func _onExitCharging():
	directionLock = false
	frontDetector.monitoring = false

# Charge Player Down Behavior
"""
First we check to see where the play is relative to the boss, then we lock in that direction
and charge until we hit a wall or get close enough to attack the player, then we repeat the cycle.
"""
func _chargePlayerBehavior(delta : float):
	# Check Direction
	if not directionLock:
		_facePlayer()
		directionLock = true
		print("CHANGED")
		
		frontDetector.monitoring = true
	
	# Move In Direction
	var move_speed = Vector2(-WALK_SPEED, 0)
	if facingRight:
		move_speed.x = WALK_SPEED
	velocity = move_speed
	
	# Animation
	if abs(velocity.x) > 2 and animator.current_animation != "boss/walk":
		animator.play("boss/walk")
	
	# Check For Barrier
	var bodies = frontDetector.get_overlapping_bodies()
	if bodies.size() > 0:
		if player in bodies:
			velocity.x = 0
			_swapToState(BehaviorState.Slashing)
		else:
			targetRecoveryTime = wallHitRecoverTime
			_swapToState(BehaviorState.Recovering)
	pass

"""
Freezes The Boss So The Player Has A Chance To Hit Them With Something. After Three Seconds, The Boss Chooses A Random
Attack State
"""
func _recoveringBehavior(delta : float):
	currentRecoveryTime += delta
	if currentRecoveryTime > targetRecoveryTime:
		targetRecoveryTime = 0
		currentRecoveryTime = 0
		_swapToState(BehaviorState.ChargePlayer)

# Set Graphics Direction
func _setFacing(fr : bool):
	facingRight = fr
	sprite.flip_h = facingRight
	if fr:
		colliders.scale.x = -1
	else:
		colliders.scale.x = 1

# Face The Player
func _facePlayer() -> void:
	if player == null:
		push_warning("The Boss Doesn't Have A Player To Check")
		return
	
	if player.position.x > position.x:
		_setFacing(true)
	else:
		_setFacing(false)
