extends Node3D


@export var destroy_wait_time = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GPUParticles3D.emitting = true

func _on_gpu_particles_3d_finished() -> void:
	await get_tree().create_timer(destroy_wait_time).timeout 
	queue_free()
