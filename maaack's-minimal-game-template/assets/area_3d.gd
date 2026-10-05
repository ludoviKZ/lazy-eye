extends Area3D

var activated = false

func _on_body_entered(body):
	if activated:
		return

	if body.name == "Player":
		activated = true
		get_tree().change_scene_to_file("res://assets/Wall.tscn")
		print("next level")
