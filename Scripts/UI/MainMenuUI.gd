extends Node

enum MenuState{
	Main,
	Settings,
	Credits
}

@export_category("Menu Groups")
@export var state : MenuState = MenuState.Main
@export var MainMenuGroup : Control
@export var SettingsMenuGroup : Control
@export var CreditsMenuGroup : Control

@export_category("Setting Sliders")
@export var musicVolSilder : Slider
@export var soundVolSilder : Slider

# Signals
signal menuStateUpdated(newState : MenuState)

# Start On Main Menu Group
func _ready():
	state = MenuState.Main
	_updateMenu()

# Set The Menu State
func _setMenuState(newState : MenuState):
	state = newState
	print("Updated Menu State To {0}".format([newState]))
	
	menuStateUpdated.emit(newState)
	_updateMenu()

# Swaps Group Dependant On State
func _updateMenu():
	match state:
		MenuState.Main:
			MainMenuGroup.visible = true
			SettingsMenuGroup.visible = false
			CreditsMenuGroup.visible = false
		MenuState.Settings:
			_settingsUI_Update()
			MainMenuGroup.visible = false
			SettingsMenuGroup.visible = true
			CreditsMenuGroup.visible = false
		MenuState.Credits:
			MainMenuGroup.visible = false
			SettingsMenuGroup.visible = false
			CreditsMenuGroup.visible = true

# Quit The Game
func _quitGame():
	print("Quiting Game!")
	get_tree().quit()

# Set The Settings UI Upon Its Opening
func _settingsUI_Update():
	musicVolSilder.set_value_no_signal(AudioManager.musicVol)
	soundVolSilder.set_value_no_signal(AudioManager.soundVol)

"""Sliders For Settings"""
func _setMusicVolume(newVol : float):
	AudioManager._updateMusicVolume(newVol)
	
func _setSoundVolume(newVol : float):
	AudioManager._updateSoundVolume(newVol)

# Play The Game
func _playGame():
	print("Playing Game!")
	LevelManager._startLoadingScene(LevelManager.Levels.First)
