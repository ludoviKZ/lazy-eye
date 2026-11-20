extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(1.6).timeout
	SceneLoader.load_scene("res://scenes/maps/MenuBackground.tscn")
