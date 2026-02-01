@tool
extends Node2D

var monitoring = null

@export var flip: bool = false:
	set(value):
		flip = false
		if $Sprite2D.flip_h:
			$Sprite2D.flip_h = false
		else:
			$Sprite2D.flip_h = true


@export_range(1, 16) var height_tiles: int = 1:
	set(value):
		height_tiles = value
		$Sprite2D.set_region_rect(Rect2(0, 0, 16, 16 * height_tiles))
		$Sprite2D.position = Vector2(0, -8 * height_tiles)
		
		var shape = RectangleShape2D.new()
		shape.size.y = 16 * height_tiles
		shape.size.x = 8
		$StaticBody2D/CollisionShape2D.set_shape(shape)
		$StaticBody2D/CollisionShape2D.position.y = -8 * height_tiles
		
		var shape2 = RectangleShape2D.new()
		shape2.size.y = 16 * height_tiles
		shape2.size.x = 2
		$LadderArea/CollisionShape2D.set_shape(shape2)
		$LadderArea/CollisionShape2D.position.y = -8 * height_tiles

func player_process(delta: float, player: Player):
	player.velocity = Vector2(0, 0)
	if Input.is_action_pressed("ui_up"):
		player.velocity = Vector2(0, -80)
	elif Input.is_action_pressed("ui_down"):
		player.velocity = Vector2(0, 80)
	
	# Prevent player from climbing over top of ladder
	if player.global_position.y < global_position.y - height_tiles * 16 + 8:
		player.global_position.y = global_position.y - height_tiles * 16 + 8
	
	# Prevent player from climbing under bottom of ladder
	if player.global_position.y > global_position.y:
		player.global_position.y = global_position.y
		
	player.global_position.x = global_position.x
		
	if Input.is_action_just_pressed("p1_jump"):
		player.set_gimmick(null)
		player._transition_to_state(Player.State.AIR)
		player.start_jump()
		monitoring = null
	
	pass
	
func force_disconnect(player: Player):
	pass
	
func _process(_delta: float):
	var player = monitoring
	if !player:
		return
		
	if player.check_mount_ladder():
		print("mounting")
		player.set_gimmick(self)


func _on_ladder_area_body_entered(body: Node2D) -> void:
	if body is not Player:
		return

	var player: Player = body
	monitoring = player
	


func _on_ladder_area_body_exited(body: Node2D) -> void:
	if body is not Player:
		return
	
	monitoring = null
