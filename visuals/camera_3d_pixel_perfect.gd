class_name Camera3DPixelPerfect
extends Camera3D

## Pixel-perfect camera that snaps position to texel grid

@export var pixels_per_unit: float = 16.0


func _process(_delta: float) -> void:
	var texel_size := 1.0 / pixels_per_unit
	global_position = Vector3(
		snappedf(global_position.x, texel_size),
		global_position.y,
		snappedf(global_position.z, texel_size)
	)
