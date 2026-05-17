extends CanvasLayer

@onready var timer_label = $Control/TopCenterContainer/TimerLabel
@onready var health_label = $Control/HealthContainer/HealthLabel

var timer: int
var health: int = 100

func _ready() -> void:
	update_timer_display()
	update_health_display()

func update_timer_value(total_seconds: int) -> void:
	timer = total_seconds

func update_timer_display() -> void:
	var minutes: int = timer / 60
	var seconds: int = timer % 60

	if timer_label:
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_health_value(health: int) -> void:
	self.health = health

func update_health_display() -> void:
	if health_label:
		health_label.text = "%d" % health
