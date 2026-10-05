extends Area3D

func _on_body_entered(body):
	print("LIVELLO +")
	get_tree().change_scene_to_file("res://assets/Wall.tscn")
