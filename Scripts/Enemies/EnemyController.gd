class_name EnemyController
extends CharacterBody2D

const TILE_SIZE: float = 16.0
const ENEMY_HEIGHT: float = 16.0

const WALK_SPEED: float = TILE_SIZE / 0.20 
const RUN_SPEED: float = WALK_SPEED * 1.75 # Slightly Faster than player.

@export_category("Behavior")
@export var chasePlayer : bool = false
@export var useRanged : bool = false

@export var huntRange : float = TILE_SIZE * 3

var foundPlayer : bool = false
enum State{
	Walking,
	Running,
	Swiping,
	Throwing,
	Dead,
}
