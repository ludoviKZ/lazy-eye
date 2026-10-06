class_name PatrolPoint
extends Marker3D
## A waypoint on an enemy patrol route. The enemy stops here for `wait_time`.

@export_range(0.0, 60.0, 0.1, "or_greater") var wait_time: float = 2.0
