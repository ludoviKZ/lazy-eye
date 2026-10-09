extends Node3D

var die: bool= false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !die:
		rotate_y(-0.85 *delta)
	else:
		position.y -= 1.2 * delta
		rotate_x(-0.3 *delta)

func _on_enemy_fov_player_entered(player):
	get_tree().reload_current_scene()
