
extends Control

@onready var new_game: Button = $MenuButtons/NewGame
@onready var options: Button = $MenuButtons/Options
@onready var quit: Button = $MenuButtons/Quit

func _ready() -> void:
	new_game.pressed.connect(start_game)
	options.pressed.connect(open_options)
	quit.pressed.connect(exit_game)

func start_game() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func open_options() -> void:
	print("Options menu goes here!")

func exit_game() -> void:
	get_tree().quit()
