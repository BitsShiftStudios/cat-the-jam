extends Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func fire_muzzle_flash():
	show()
	rotation_degrees.z = randf_range(0, 360)
	await get_tree().create_timer(0.05).timeout
	hide()
