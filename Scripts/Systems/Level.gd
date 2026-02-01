class_name Level extends Node2D

@onready var player: Player = $MainCharacter
@export var kill_height = 360

func _ready():
	for child in find_children("*", "", true, true):
		print("initializing child %s" % child)
		if child.has_method("set_default_state"):
			child.set_default_state()

func reset_to_spawn():
	for child in find_children("*", "", true, true):
		print("found child %s" % child)
		if child.has_method("load_default_state"):
			child.load_default_state()

func _process(_delta : float) -> void:
	if Input.is_action_just_released("p1_reset"):
		player.kill_player()
	
	if Input.is_action_just_pressed("cheats_mask"):
		player.give_mask()
	
	if player.global_position.y > kill_height:
		player.global_position.y = kill_height - 2
		player.kill_player()
	pass
	
func pause_music():
	$MainMusic.stream_paused = true

func resume_music():
	$MainMusic.stream_paused = false
