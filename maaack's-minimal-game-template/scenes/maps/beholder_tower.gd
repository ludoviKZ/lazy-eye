extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	AudioMaster.play_stream(SoundLibrary.HIGH_THEME)
