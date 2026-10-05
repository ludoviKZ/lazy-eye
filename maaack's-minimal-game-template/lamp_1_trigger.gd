extends Area3D

@export var lamp_light: OmniLight3D

func _on_body_entered(body):
	if body.name == "Player":
		lamp_light.visible = true
		queue_free()
