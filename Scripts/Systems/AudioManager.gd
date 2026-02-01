extends Node

# Volumes
var musicVol : float = 1
var soundVol : float = 1

# Indexes Used To Get Bus
const MUSIC_BUS_INDEX : int = 1
const SOUND_BUS_INDEX : int = 2

# First Time Audio Setup
func _ready():
	# Set Defaults
	_updateMusicVolume(1)
	_updateSoundVolume(1)
	
	print("Audio System Is Ready.")

# Update Buses
func _updateMusicVolume(newVol : float):
	musicVol = clamp(newVol, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MUSIC_BUS_INDEX, linear_to_db(musicVol))
	
func _updateSoundVolume(newVol : float):
	soundVol = clamp(newVol, 0.0, 1.0)
	AudioServer.set_bus_volume_db(SOUND_BUS_INDEX, linear_to_db(soundVol))
