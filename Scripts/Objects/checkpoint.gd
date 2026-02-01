extends Node2D
@onready var sprite := $Sprite2D
@onready var sfx := $AudioStreamPlayer

var activated = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if activated:
		return
	
	if body is not Player:
		return
	sprite.play("unfurl")
	var player : Player = body
	player.set_default_state()
	sfx.play()
	activated = true
