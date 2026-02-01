@tool extends Node2D

@export_range(1, 32) var x_tile_width := 2:
	set(value):
		x_tile_width = value
		$Sprite2D.set_region_rect(Rect2(0, 0, 16 * x_tile_width, 16))
		print("16 * x_tile_width")
		var shape = RectangleShape2D.new()
		shape.size.y = 8
		shape.size.x = 16 * x_tile_width - 5
		$Area2D/CollisionShape2D.set_shape(shape)
		$Area2D/CollisionShape2D.position.x = 8 * x_tile_width - 0.5
		$RightWall.position.x = 16 * x_tile_width - 5
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	var player: Player = body
	player.kill_player()
