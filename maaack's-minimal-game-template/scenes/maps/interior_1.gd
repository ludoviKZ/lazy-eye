extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	AudioMaster.play_stream(SoundLibrary.MID_THEME)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
