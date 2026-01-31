extends Node2D
@export var bounce_velocity:Vector2 = Vector2(0, -460)

@onready var animator := $AnimationPlayer

func bounce(player: Player):
	player.velocity = bounce_velocity
	animator.queue(&"springy")
	animator.queue(&"idle")
	pass


func _on_player_collider_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
		
	bounce(body)
