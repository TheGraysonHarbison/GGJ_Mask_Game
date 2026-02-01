extends Node

# Levels To Load
#@onready var main_menu_level : PackedScene = preload("res://MainMenu.tscn")
#@onready var first_level : PackedScene = preload("res://Tilemap/main_level.tscn")

# Loading Screen
#@onready var loading_screen_prefab : PackedScene

# States
enum Levels{
	MainMenu,
	First
}

var is_working : bool = false
var currentSceneState : Levels = Levels.MainMenu

# Setup
func _ready():
	is_working = false
	currentSceneState = Levels.MainMenu
	print("Level Manager Is Ready!")

# Trigger A Load
func _startLoadingScene(levelToLoad : Levels):
	print("Changing Level To {0}".format([levelToLoad]))
	
	match levelToLoad:
		Levels.MainMenu:
			get_tree().change_scene_to_file("res://MainMenu.tscn")
		Levels.First:
			get_tree().change_scene_to_file("res://Tilemap/main_level.tscn")
	
	pass
