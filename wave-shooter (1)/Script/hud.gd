extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_current_ammo_info(total_ammo, ammo_in_magazine):
	$Control/AmmoInfo.text = str(ammo_in_magazine) + " / " + str(total_ammo)
