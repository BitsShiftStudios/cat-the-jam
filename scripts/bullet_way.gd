extends RayCast3D

var base_shake_rate = 0.0

func find_target() -> Vector3:
	force_raycast_update()
	if is_colliding():
		return get_collision_point()
	else:
		return global_position - global_transform.basis.z * 100.0
