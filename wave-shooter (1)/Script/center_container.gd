extends CenterContainer

var a = 1.0
var b : Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	queue_redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw():
	var center_point = size / 2.0
	draw_circle(size, a, b)
