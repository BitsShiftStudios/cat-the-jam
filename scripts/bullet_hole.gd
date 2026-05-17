extends Node3D


@export var destroy_wait_time = 3.0

func _process(delta: float) -> void:
	await get_tree().create_timer(destroy_wait_time).timeout 
	queue_free()
