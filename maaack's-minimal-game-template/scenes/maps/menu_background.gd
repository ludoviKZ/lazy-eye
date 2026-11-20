
extends Node3D

@onready var new_game: Button = $MenuUi/MenuButtons/NewGame
@onready var quit: Button = $MenuUi/MenuButtons/Quit

func _ready() -> void:
	new_game.pressed.connect(start_game)
	quit.pressed.connect(exit_game)

func start_game() -> void:
	SceneLoader.load_scene("res://lvl_1.tscn")

func exit_game() -> void:
	get_tree().quit()
